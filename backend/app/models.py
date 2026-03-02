from typing import Any

from pydantic import BaseModel, Field, field_validator


class ChatRequest(BaseModel):
    user_id: str = Field(..., description="Supabase auth user id")
    message: str = Field(..., min_length=1)
    session_id: str | None = Field(default=None)

    @field_validator("user_id", "message", mode="before")
    @classmethod
    def _strip_required_fields(cls, value: str) -> str:
        if value is None:
            return value
        if not isinstance(value, str):
            raise TypeError("Field must be a string.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Field cannot be empty.")
        return cleaned


class SourceDocument(BaseModel):
    content: str
    metadata: dict[str, Any] = Field(default_factory=dict)


class ChatResponse(BaseModel):
    answer: str
    source_documents: list[SourceDocument] = Field(default_factory=list)
    session_id: str
