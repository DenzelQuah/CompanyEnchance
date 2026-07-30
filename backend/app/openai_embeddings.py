from __future__ import annotations

import time
from typing import Iterable

from openai import OpenAI

from .config import settings


def _client() -> OpenAI:
    return OpenAI(api_key=settings.openai_api_key)


def embed_documents(texts: list[str], *, batch_size: int = 64) -> list[list[float]]:
    """Embed multiple documents with simple retry/backoff."""
    if not texts:
        return []

    out: list[list[float]] = []
    client = _client()

    for batch in _batched(texts, batch_size=batch_size):
        attempt = 0
        while True:
            try:
                resp = client.embeddings.create(
                    model=settings.openai_embedding_model,
                    input=batch,
                )
                out.extend([row.embedding for row in resp.data])
                break
            except Exception:
                if attempt >= 6:
                    raise
                time.sleep(min(60.0, 2.0**attempt))
                attempt += 1

    return out


def embed_query(text: str) -> list[float]:
    vectors = embed_documents([text], batch_size=1)
    return vectors[0] if vectors else []


def _batched(items: list[str], *, batch_size: int) -> Iterable[list[str]]:
    if batch_size <= 0:
        batch_size = 1
    for i in range(0, len(items), batch_size):
        yield items[i : i + batch_size]

