from typing import Any

from pydantic import BaseModel, Field, field_validator


class ChatRequest(BaseModel):
    user_id: str = Field(..., description="Supabase auth user id")
    message: str = Field(..., min_length=1)
    session_id: str | None = Field(default=None)
    use_rag: bool = Field(default=True, description="Use vector retrieval context")
    allow_updates: bool = Field(default=True, description="Allow roadmap update tool")

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


class RagSyncRequest(BaseModel):
    user_id: str = Field(..., description="Supabase auth user id")
    force: bool = Field(default=False)

    @field_validator("user_id", mode="before")
    @classmethod
    def _strip_user_id(cls, value: str) -> str:
        if value is None:
            return value
        if not isinstance(value, str):
            raise TypeError("Field must be a string.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Field cannot be empty.")
        return cleaned


class RagSyncResponse(BaseModel):
    milestones_scanned: int
    candidate_docs: int
    docs_replaced: int
    docs_skipped_unchanged: int
    stale_docs_deleted: int
    chunks_written: int


class FinancialSummaryRequest(BaseModel):
    user_id: str = Field(..., description="Supabase auth user id")
    horizon_months: int = Field(default=12, ge=3, le=24)

    @field_validator("user_id", mode="before")
    @classmethod
    def _strip_user_id(cls, value: str) -> str:
        if value is None:
            return value
        if not isinstance(value, str):
            raise TypeError("Field must be a string.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Field cannot be empty.")
        return cleaned


class MissingRequirement(BaseModel):
    code: str
    label: str
    current: float
    max: float
    missing_points: float
    action_tip: str


class BankReadiness(BaseModel):
    score: int
    tier: str
    qualifying_threshold: int = 80
    points_to_threshold: int
    missing_requirements: list[MissingRequirement] = Field(default_factory=list)


class GrantMatch(BaseModel):
    id: str
    name: str
    agency: str
    country: str
    state: str
    target_business_stage: str = ""
    max_funding_rm: float
    deadline: str
    fit_score: float
    application_url: str
    requirements: list[str] = Field(default_factory=list)
    unmet_requirements: list[str] = Field(default_factory=list)


class FinancialSummaryResponse(BaseModel):
    readiness: BankReadiness
    matched_grants: list[GrantMatch] = Field(default_factory=list)


class FinancialTargetUpsertRequest(BaseModel):
    user_id: str = Field(..., description="Supabase auth user id")
    month: str = Field(..., description="YYYY-MM")
    monthly_budget_rm: float = Field(..., ge=0)
    target_growth_pct: float = Field(..., ge=-100, le=500)

    @field_validator("user_id", mode="before")
    @classmethod
    def _strip_user_id(cls, value: str) -> str:
        if value is None:
            return value
        if not isinstance(value, str):
            raise TypeError("Field must be a string.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Field cannot be empty.")
        return cleaned


class FinancialTargetResponse(BaseModel):
    user_id: str
    month: str
    monthly_budget_rm: float
    target_growth_pct: float


class DailyFinancialLogUpsertRequest(BaseModel):
    user_id: str = Field(..., description="Supabase auth user id")
    log_date: str = Field(..., description="YYYY-MM-DD")
    revenue_rm: float = Field(..., ge=0)
    expense_rm: float = Field(..., ge=0)
    note: str | None = None

    @field_validator("user_id", mode="before")
    @classmethod
    def _strip_user_id(cls, value: str) -> str:
        if value is None:
            return value
        if not isinstance(value, str):
            raise TypeError("Field must be a string.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Field cannot be empty.")
        return cleaned


class DailyFinancialLog(BaseModel):
    id: str
    user_id: str
    log_date: str
    revenue_rm: float
    expense_rm: float
    note: str | None = None


class DailyFinancialLogListResponse(BaseModel):
    items: list[DailyFinancialLog] = Field(default_factory=list)


class FinancialGrowthGraphRequest(BaseModel):
    user_id: str = Field(..., description="Supabase auth user id")
    month: str = Field(..., description="YYYY-MM")

    @field_validator("user_id", mode="before")
    @classmethod
    def _strip_user_id(cls, value: str) -> str:
        if value is None:
            return value
        if not isinstance(value, str):
            raise TypeError("Field must be a string.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Field cannot be empty.")
        return cleaned


class FinancialGrowthGraphResponse(BaseModel):
    month: str
    monthly_budget_rm: float
    target_growth_pct: float
    dates: list[str] = Field(default_factory=list)
    projection_growth_pct: list[float] = Field(default_factory=list)
    actual_growth_pct: list[float] = Field(default_factory=list)
