from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    supabase_url: str
    supabase_service_role_key: str
    gemini_api_key: str

    rag_table_name: str = "roadmap_knowledge"
    rag_match_function: str = "match_roadmap_docs"
    business_rag_table_name: str = "business_knowledge"
    business_rag_match_function: str = "match_business_docs"
    rag_top_k: int = 4
    rag_match_threshold: float = 0.7
    rag_embedding_dim: int = 3072
    rag_chunk_size_chars: int = 900
    rag_chunk_overlap_chars: int = 120

    gemini_chat_model: str = "gemini-2.5-flash"
    gemini_embedding_model: str = "models/gemini-embedding-001"

    roadmap_update_function: str = "update_roadmap_database"

    cors_allow_origins: str = "*"
    debug_errors: bool = False

    model_config = SettingsConfigDict(
        # Load env vars from either repo-root or backend-local `.env`.
        # This makes CLI scripts runnable from both the repo root and `backend/`.
        env_file=(
            Path(__file__).resolve().parents[2] / ".env",  # repo root
            Path(__file__).resolve().parents[1] / ".env",  # backend/
        ),
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
