from __future__ import annotations

import argparse
import hashlib
import re
import sys
import time
from pathlib import Path
from typing import Iterable

from postgrest.exceptions import APIError

try:
    from langchain_google_genai import GoogleGenerativeAIEmbeddings
except ModuleNotFoundError as exc:
    if exc.name != "langchain_google_genai":
        raise
    script = Path(__file__).name
    raise SystemExit(
        "\n".join(
            [
                f"Missing optional dependency: {exc.name!r}.",
                "",
                "This project pins the dependency in `backend/requirements.txt`, so this usually means",
                "you're running the script with the wrong Python interpreter (not the backend venv).",
                "",
                "Fix (PowerShell):",
                "  cd backend",
                "  .\\.venv\\Scripts\\python -m pip install -r requirements.txt",
                f"  .\\.venv\\Scripts\\python scripts\\{script} --help",
                "",
                "If you don't have the venv yet:",
                "  cd backend",
                "  python -m venv .venv",
                "  .\\.venv\\Scripts\\python -m pip install -r requirements.txt",
            ]
        )
    ) from exc
from supabase import create_client

# Allow direct script execution from backend/scripts.
SCRIPT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = SCRIPT_DIR.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))


def _load_settings():
    # Import lazily so `--help` works even if required env vars are not set.
    try:
        from app.config import settings  # type: ignore

        return settings
    except Exception as exc:  # noqa: BLE001
        # Most commonly: pydantic settings validation error due to missing env vars.
        msg = str(exc)
        missing_key = None
        if "supabase_service_role_key" in msg:
            missing_key = "SUPABASE_SERVICE_ROLE_KEY"
        elif "supabase_url" in msg:
            missing_key = "SUPABASE_URL"
        elif "gemini_api_key" in msg:
            missing_key = "GEMINI_API_KEY"

        if missing_key:
            raise SystemExit(
                "\n".join(
                    [
                        "Missing required configuration for this script.",
                        "",
                        f"Set `{missing_key}` in your `.env` (repo root or `backend/.env`).",
                        "This script needs a Supabase *service role* key to insert embeddings.",
                        "",
                        "Tip: keep secrets in `backend/.env` if you don't want them in the repo root.",
                    ]
                )
            ) from exc
        raise


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


def embed_documents_with_throttle(
    embeddings_client: GoogleGenerativeAIEmbeddings,
    chunks: list[str],
    *,
    batch_size: int = 50,
    max_retries: int = 8,
) -> list[list[float]]:
    if batch_size <= 0:
        batch_size = 50

    all_vectors: list[list[float]] = []
    for start in range(0, len(chunks), batch_size):
        batch = chunks[start : start + batch_size]
        attempt = 0
        while True:
            try:
                all_vectors.extend(embeddings_client.embed_documents(batch))
                break
            except Exception as exc:  # noqa: BLE001
                # Common case: Gemini embedding quota/rate-limit (429 ResourceExhausted).
                msg = str(exc)
                is_rate_limit = (
                    "RESOURCE_EXHAUSTED" in msg or "429" in msg or "quota" in msg.lower()
                )
                if not is_rate_limit or attempt >= max_retries:
                    raise

                # Try to respect the server-provided retry delay if present.
                sleep_s = None
                m = re.search(
                    r"retry(?:_| )delay[^\\d]*(\\d+(?:\\.\\d+)?)s",
                    msg,
                    flags=re.IGNORECASE,
                )
                if m:
                    try:
                        sleep_s = float(m.group(1))
                    except ValueError:
                        sleep_s = None

                if sleep_s is None:
                    sleep_s = min(60.0, 2.0**attempt)

                time.sleep(max(1.0, sleep_s))
                attempt += 1

    return all_vectors


def insert_markdown_chunks(
    markdown_path: Path,
    source_doc_id: str,
    source_type: str = "business_knowledge",
    chunk_size: int = 900,
    chunk_overlap: int = 120,
    embedding_batch_size: int = 50,
) -> dict[str, int | str]:
    settings = _load_settings()

    candidate_paths: list[Path] = []
    placeholder_markers = ("c:\\path\\to\\backend", "/path/to/backend")
    markdown_path_str = str(markdown_path)
    if any(marker in markdown_path_str.lower() for marker in placeholder_markers):
        raw = BACKEND_DIR / "asean_nexus_knowledge_base.md"
    else:
        raw = Path(markdown_path)
    try:
        candidate_paths.append(raw.expanduser())
    except RuntimeError:
        candidate_paths.append(raw)

    if not raw.is_absolute():
        # Try resolving relative paths from both CWD and backend directory.
        candidate_paths.append((Path.cwd() / raw).resolve())
        candidate_paths.append((BACKEND_DIR / raw).resolve())

    resolved_path = next((p for p in candidate_paths if p.exists()), None)
    if resolved_path is None:
        tried = "\n".join(f"- {p}" for p in candidate_paths)
        raise SystemExit(
            "\n".join(
                [
                    "Markdown file not found.",
                    f"Given: {markdown_path}",
                    f"CWD: {Path.cwd()}",
                    "",
                    "Tried:",
                    tried,
                    "",
                    "Fix: pass the real path to `--file`, for example:",
                    f"  --file \"{(BACKEND_DIR / 'asean_nexus_knowledge_base.md').resolve()}\"",
                    "",
                    "Tip: if you copied a placeholder like `C:\\path\\to\\backend\\...`, omit `--file` to use the default knowledge base file.",
                ]
            )
        )

    markdown_text = resolved_path.read_text(encoding="utf-8")
    chunks = build_chunks(markdown_text, chunk_size=chunk_size, chunk_overlap=chunk_overlap)
    if not chunks:
        raise ValueError("No non-empty chunks were produced from the markdown file.")

    source_doc_hash = hashlib.sha256(markdown_text.encode("utf-8")).hexdigest()
    embeddings_client = GoogleGenerativeAIEmbeddings(
        model=settings.gemini_embedding_model,
        google_api_key=settings.gemini_api_key,
    )
    embeddings = embed_documents_with_throttle(
        embeddings_client,
        chunks,
        batch_size=embedding_batch_size,
    )

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
    try:
        supabase.table(settings.business_rag_table_name).insert(rows).execute()
    except APIError as exc:
        msg = ""
        try:
            msg = str(exc).strip()
        except Exception:  # noqa: BLE001
            msg = ""

        m = re.search(r"expected\s+(\d+)\s+dimensions,\s+not\s+(\d+)", msg, re.IGNORECASE)
        if m:
            expected = int(m.group(1))
            actual = int(m.group(2))
            table = settings.business_rag_table_name
            model = settings.gemini_embedding_model
            raise SystemExit(
                "\n".join(
                    [
                        "Embedding dimension mismatch with Supabase table.",
                        "",
                        f"Table: {table}",
                        f"Embedding model: {model}",
                        f"Database expects: {expected}",
                        f"Your embeddings are: {actual}",
                        "",
                        "Fix options:",
                        f"- Update the Supabase `{table}.embedding` vector dimension to {actual} (and update any match function/index accordingly), OR",
                        f"- Switch to an embedding model that returns {expected}-dim vectors.",
                    ]
                )
            ) from exc
        raise
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
    default_file = (BACKEND_DIR / "asean_nexus_knowledge_base.md").resolve()
    parser.add_argument(
        "--file",
        default=str(default_file),
        help=f"Path to .md file (default: {default_file})",
    )
    parser.add_argument("--source-doc-id", required=True, help="Stable source document id")
    parser.add_argument("--source-type", required=False, default="business_knowledge")
    parser.add_argument("--chunk-size", type=int, default=900)
    parser.add_argument("--chunk-overlap", type=int, default=120)
    parser.add_argument(
        "--embedding-batch-size",
        type=int,
        default=50,
        help="How many chunks to embed per API call (smaller can reduce rate-limit spikes).",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    result = insert_markdown_chunks(
        markdown_path=Path(args.file),
        source_doc_id=args.source_doc_id,
        source_type=args.source_type,
        chunk_size=args.chunk_size,
        chunk_overlap=args.chunk_overlap,
        embedding_batch_size=args.embedding_batch_size,
    )
    print(result)
