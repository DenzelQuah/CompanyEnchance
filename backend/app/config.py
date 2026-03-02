from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    supabase_url: str
    supabase_service_role_key: str
    gemini_api_key: str

    rag_table_name: str = "roadmap_knowledge"
    rag_match_function: str = "match_roadmap_docs"
    rag_top_k: int = 4
    rag_match_threshold: float = 0.7
    rag_embedding_dim: int = 3072

    gemini_chat_model: str = "gemini-2.5-flash"
    gemini_embedding_model: str = "models/gemini-embedding-001"

    roadmap_update_function: str = "update_roadmap_database"

    cors_allow_origins: str = "*"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
