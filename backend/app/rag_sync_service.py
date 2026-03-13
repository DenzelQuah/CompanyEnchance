from __future__ import annotations

import hashlib
import json
import re
from typing import Any
from uuid import UUID

from langchain_google_genai import GoogleGenerativeAIEmbeddings
from supabase import Client, create_client

from .config import settings


class RagSyncService:
    """Build and sync user milestone chunks into roadmap_knowledge."""

    def __init__(self) -> None:
        self.supabase: Client = create_client(
            settings.supabase_url, settings.supabase_service_role_key
        )
        self.embeddings = GoogleGenerativeAIEmbeddings(
            model=settings.gemini_embedding_model,
            google_api_key=settings.gemini_api_key,
        )

    def sync_user_milestones(self, user_id: str, force: bool = False) -> dict[str, int]:
        user_uuid = self._parse_user_uuid(user_id)
        milestones = self._fetch_milestones(user_uuid)
        existing = self._fetch_existing_chunks(user_uuid)

        inserted_chunks = 0
        replaced_docs = 0
        skipped_docs = 0
        deleted_stale_docs = 0
        candidate_docs = 0

        active_source_doc_ids: set[str] = set()

        for milestone in milestones:
            source_doc_id = f"milestone:{milestone['id']}"
            active_source_doc_ids.add(source_doc_id)
            candidate_docs += 1

            source_doc_hash = self._source_doc_hash(milestone)
            existing_hash = existing.get(source_doc_id, {}).get("source_doc_hash")
            if not force and existing_hash == source_doc_hash:
                skipped_docs += 1
                continue

            rows = self._build_rows(
                user_uuid=user_uuid,
                milestone=milestone,
                source_doc_id=source_doc_id,
                source_doc_hash=source_doc_hash,
            )
            self._delete_source_doc_chunks(user_uuid=user_uuid, source_doc_id=source_doc_id)
            if rows:
                self.supabase.table(settings.rag_table_name).insert(rows).execute()
                inserted_chunks += len(rows)
                replaced_docs += 1

        for source_doc_id in existing.keys():
            if not source_doc_id.startswith("milestone:"):
                continue
            if source_doc_id in active_source_doc_ids:
                continue
            self._delete_source_doc_chunks(user_uuid=user_uuid, source_doc_id=source_doc_id)
            deleted_stale_docs += 1

        return {
            "milestones_scanned": len(milestones),
            "candidate_docs": candidate_docs,
            "docs_replaced": replaced_docs,
            "docs_skipped_unchanged": skipped_docs,
            "stale_docs_deleted": deleted_stale_docs,
            "chunks_written": inserted_chunks,
        }

    def _parse_user_uuid(self, user_id: str) -> str:
        try:
            return str(UUID(user_id))
        except ValueError as exc:
            raise ValueError("user_id must be a valid UUID for RAG sync.") from exc

    def _fetch_milestones(self, user_uuid: str) -> list[dict[str, Any]]:
        result = (
            self.supabase.table("user_milestones")
            .select(
                "id,user_id,title,description,week_label,status,relevance_reason,"
                "current_step,steps,micro_tasks,resources,updated_at,created_at"
            )
            .eq("user_id", user_uuid)
            .order("created_at", desc=False)
            .execute()
        )
        return [dict(row) for row in list(result.data or [])]

    def _fetch_existing_chunks(self, user_uuid: str) -> dict[str, dict[str, Any]]:
        result = (
            self.supabase.table(settings.rag_table_name)
            .select("metadata")
            .eq("user_id", user_uuid)
            .execute()
        )
        rows = list(result.data or [])
        out: dict[str, dict[str, Any]] = {}
        for row in rows:
            metadata = dict(row.get("metadata") or {})
            source_doc_id = str(metadata.get("source_doc_id") or "")
            if not source_doc_id:
                continue
            source_doc_hash = str(metadata.get("source_doc_hash") or "")
            if source_doc_id not in out:
                out[source_doc_id] = {"source_doc_hash": source_doc_hash}
        return out

    def _source_doc_hash(self, milestone: dict[str, Any]) -> str:
        canonical = {
            "id": milestone.get("id"),
            "title": milestone.get("title"),
            "description": milestone.get("description"),
            "week_label": milestone.get("week_label"),
            "status": milestone.get("status"),
            "relevance_reason": milestone.get("relevance_reason"),
            "current_step": milestone.get("current_step"),
            "steps": milestone.get("steps") or [],
            "micro_tasks": milestone.get("micro_tasks") or [],
            "resources": milestone.get("resources") or [],
            "updated_at": milestone.get("updated_at"),
            "created_at": milestone.get("created_at"),
        }
        encoded = json.dumps(canonical, sort_keys=True, separators=(",", ":"))
        return hashlib.sha256(encoded.encode("utf-8")).hexdigest()

    def _build_rows(
        self,
        user_uuid: str,
        milestone: dict[str, Any],
        source_doc_id: str,
        source_doc_hash: str,
    ) -> list[dict[str, Any]]:
        sections = self._milestone_sections(milestone)
        if not sections:
            return []

        chunk_specs: list[dict[str, str]] = []
        for section_name, content in sections:
            pieces = self._split_text(
                content=content,
                max_chars=settings.rag_chunk_size_chars,
                overlap=settings.rag_chunk_overlap_chars,
            )
            for piece in pieces:
                if piece.strip():
                    chunk_specs.append({"section": section_name, "content": piece.strip()})

        if not chunk_specs:
            return []

        embeddings = self.embeddings.embed_documents([c["content"] for c in chunk_specs])
        if any(len(v) != settings.rag_embedding_dim for v in embeddings):
            raise ValueError(
                f"Embedding dimension mismatch while syncing user={user_uuid}."
            )

        total = len(chunk_specs)
        rows: list[dict[str, Any]] = []
        for idx, chunk in enumerate(chunk_specs):
            metadata = {
                "source_type": "user_milestone",
                "source_doc_id": source_doc_id,
                "source_doc_hash": source_doc_hash,
                "milestone_id": str(milestone.get("id") or ""),
                "section": chunk["section"],
                "status": str(milestone.get("status") or ""),
                "week_label": str(milestone.get("week_label") or ""),
                "chunk_index": idx,
                "chunk_total": total,
                "milestone_updated_at": milestone.get("updated_at"),
            }
            rows.append(
                {
                    "user_id": user_uuid,
                    "content": chunk["content"],
                    "metadata": metadata,
                    "embedding": embeddings[idx],
                }
            )
        return rows

    def _milestone_sections(self, milestone: dict[str, Any]) -> list[tuple[str, str]]:
        title = str(milestone.get("title") or "").strip()
        description = str(milestone.get("description") or "").strip()
        week = str(milestone.get("week_label") or "").strip()
        status = str(milestone.get("status") or "").strip()
        reason = str(milestone.get("relevance_reason") or "").strip()
        current_step = self._to_int(milestone.get("current_step"))

        steps_raw = milestone.get("steps")
        steps = [str(s).strip() for s in (steps_raw or []) if str(s).strip()]

        micro_raw = milestone.get("micro_tasks")
        micro_rows = self._coerce_micro_tasks(micro_raw)

        resources_raw = milestone.get("resources")
        resources = self._resource_lines(resources_raw)

        sections: list[tuple[str, str]] = []
        overview = (
            f"Milestone: {title}\nWeek: {week}\nStatus: {status}\n"
            f"Description: {description}\nRelevance: {reason}"
        ).strip()
        if overview:
            sections.append(("overview", overview))

        if steps:
            step_lines = [f"{i + 1}. {step}" for i, step in enumerate(steps)]
            step_text = (
                f"Milestone steps for {title}\nCurrent step index: {current_step}\n"
                + "\n".join(step_lines)
            )
            sections.append(("steps", step_text))

        if micro_rows:
            micro_lines: list[str] = []
            for i, items in enumerate(micro_rows):
                if not items:
                    continue
                joined = "; ".join(items)
                micro_lines.append(f"Step {i + 1} micro tasks: {joined}")
            if micro_lines:
                sections.append(("micro_tasks", "\n".join(micro_lines)))

        if resources:
            sections.append(("resources", f"Resources for {title}\n" + "\n".join(resources)))

        return sections

    def _coerce_micro_tasks(self, value: Any) -> list[list[str]]:
        if not isinstance(value, list):
            return []
        out: list[list[str]] = []
        for row in value:
            if isinstance(row, list):
                out.append([str(item).strip() for item in row if str(item).strip()])
            else:
                text = str(row).strip()
                out.append([text] if text else [])
        return out

    def _to_int(self, value: Any) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return 0

    def _resource_lines(self, value: Any) -> list[str]:
        if not isinstance(value, list):
            return []
        lines: list[str] = []
        for item in value:
            if isinstance(item, dict):
                title = str(item.get("title") or "").strip()
                org = str(item.get("organisation") or item.get("agency") or "").strip()
                url = str(item.get("url") or "").strip()
                highlight = str(item.get("highlight") or "").strip()
                parts = [p for p in [title, org, highlight, url] if p]
                if parts:
                    lines.append(" | ".join(parts))
            else:
                text = str(item).strip()
                if text:
                    lines.append(text)
        return lines

    def _split_text(self, content: str, max_chars: int, overlap: int) -> list[str]:
        if max_chars < 100:
            max_chars = 100
        overlap = max(0, min(overlap, max_chars - 1))
        text = re.sub(r"\s+", " ", content).strip()
        if not text:
            return []
        if len(text) <= max_chars:
            return [text]

        sentences = re.split(r"(?<=[.!?])\s+", text)
        chunks: list[str] = []
        current = ""

        for sentence in sentences:
            sentence = sentence.strip()
            if not sentence:
                continue

            candidate = sentence if not current else f"{current} {sentence}"
            if len(candidate) <= max_chars:
                current = candidate
                continue

            if current:
                chunks.append(current)
            current = sentence

            while len(current) > max_chars:
                chunks.append(current[:max_chars].strip())
                step = max_chars - overlap
                current = current[step:].strip()

        if current:
            chunks.append(current)

        return chunks

    def _delete_source_doc_chunks(self, user_uuid: str, source_doc_id: str) -> None:
        (
            self.supabase.table(settings.rag_table_name)
            .delete()
            .eq("user_id", user_uuid)
            .eq("metadata->>source_doc_id", source_doc_id)
            .execute()
        )
