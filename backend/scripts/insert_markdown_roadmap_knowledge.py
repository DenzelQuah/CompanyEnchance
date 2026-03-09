from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path
from typing import Iterable

from langchain_google_genai import GoogleGenerativeAIEmbeddings
from supabase import create_client

# Allow direct script execution from backend/scripts.
SCRIPT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = SCRIPT_DIR.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.config import settings


def split_markdown_sections(markdown_text: str) -> list[str]:
    """Split markdown by headings while keeping heading text in each section."""
    text = markdown_text.replace("\r\n", "\n").strip()
    if not text:
        return []

    lines = text.split("\n")
    sections: list[list[str]] = []
    current: list[str] = []

    for line in lines:
        if line.lstrip().startswith("#"):
            if current:
                sections.append(current)
            current = [line]
        else:
            current.append(line)

    if current:
        sections.append(current)

    return ["\n".join(section).strip() for section in sections if "".join(section).strip()]


def chunk_text(text: str, max_chars: int, overlap: int) -> list[str]:
    """Chunk text with sentence preference and character overlap."""
    if max_chars < 100:
        max_chars = 100
    overlap = max(0, min(overlap, max_chars - 1))

    flat_text = re.sub(r"\s+", " ", text).strip()
    if not flat_text:
        return []
    if len(flat_text) <= max_chars:
        return [flat_text]

    sentences = re.split(r"(?<=[.!?])\s+", flat_text)
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


def build_chunks(markdown_text: str, chunk_size: int, chunk_overlap: int) -> list[str]:
    sections = split_markdown_sections(markdown_text)
    chunks: list[str] = []
    for section in sections:
        chunks.extend(chunk_text(section, max_chars=chunk_size, overlap=chunk_overlap))
    return [chunk for chunk in chunks if chunk.strip()]


def insert_markdown_chunks(
    markdown_path: Path,
    source_doc_id: str,
    source_type: str = "business_knowledge",
    chunk_size: int = 900,
    chunk_overlap: int = 120,
) -> dict[str, int | str]:
    markdown_text = markdown_path.read_text(encoding="utf-8")
    chunks = build_chunks(markdown_text, chunk_size=chunk_size, chunk_overlap=chunk_overlap)
    if not chunks:
        raise ValueError("No non-empty chunks were produced from the markdown file.")

    source_doc_hash = hashlib.sha256(markdown_text.encode("utf-8")).hexdigest()
    embeddings_client = GoogleGenerativeAIEmbeddings(
        model=settings.gemini_embedding_model,
        google_api_key=settings.gemini_api_key,
    )
    embeddings = embeddings_client.embed_documents(chunks)

    if any(len(vec) != settings.rag_embedding_dim for vec in embeddings):
        raise ValueError(
            f"Embedding dimension mismatch. Expected {settings.rag_embedding_dim}."
        )

    supabase = create_client(settings.supabase_url, settings.supabase_service_role_key)
    rows = list(
        _build_rows(
            chunks=chunks,
            embeddings=embeddings,
            source_doc_id=source_doc_id,
            source_doc_hash=source_doc_hash,
            source_type=source_type,
        )
    )
    supabase.table(settings.business_rag_table_name).insert(rows).execute()
    return {
        "chunks_inserted": len(rows),
        "source_doc_id": source_doc_id,
        "table": settings.business_rag_table_name,
    }


def _build_rows(
    chunks: list[str],
    embeddings: list[list[float]],
    source_doc_id: str,
    source_doc_hash: str,
    source_type: str,
) -> Iterable[dict]:
    chunk_total = len(chunks)
    for index, chunk in enumerate(chunks):
        row = {
            "content": chunk,
            "metadata": {
                "source_type": source_type,
                "source_doc_id": source_doc_id,
                "source_doc_hash": source_doc_hash,
                "chunk_index": index,
                "chunk_total": chunk_total,
            },
            "embedding": embeddings[index],
        }
        yield row


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Chunk a markdown file, embed chunks, then insert into business_knowledge."
    )
    parser.add_argument("--file", required=True, help="Path to .md file")
    parser.add_argument("--source-doc-id", required=True, help="Stable source document id")
    parser.add_argument("--source-type", required=False, default="business_knowledge")
    parser.add_argument("--chunk-size", type=int, default=settings.rag_chunk_size_chars)
    parser.add_argument("--chunk-overlap", type=int, default=settings.rag_chunk_overlap_chars)
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    result = insert_markdown_chunks(
        markdown_path=Path(args.file),
        source_doc_id=args.source_doc_id,
        source_type=args.source_type,
        chunk_size=args.chunk_size,
        chunk_overlap=args.chunk_overlap,
    )
    print(result)
