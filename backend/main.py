import logging

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.chat_service import ChatService
from app.config import settings
from app.financial_service import FinancialService
from app.models import (
    ChatRequest,
    ChatResponse,
    DailyFinancialLog,
    DailyFinancialLogListResponse,
    DailyFinancialLogUpsertRequest,
    FinancialGrowthGraphRequest,
    FinancialGrowthGraphResponse,
    FinancialSummaryRequest,
    FinancialSummaryResponse,
    FinancialTargetResponse,
    FinancialTargetUpsertRequest,
    RagSyncRequest,
    RagSyncResponse,
)
from app.rag_sync_service import RagSyncService

app = FastAPI(title="Roadmap RAG API", version="1.0.0")
logger = logging.getLogger(__name__)

origins = [o.strip() for o in settings.cors_allow_origins.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

chat_service = ChatService()
financial_service = FinancialService()
rag_sync_service = RagSyncService()


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest) -> ChatResponse:
    try:
        return await chat_service.chat(
            user_id=req.user_id,
            message=req.message,
            session_id=req.session_id,
            use_rag=req.use_rag,
            allow_updates=req.allow_updates,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Unexpected /chat failure.")
        detail = (
            str(exc)
            if settings.debug_errors
            else "Internal server error while processing chat request."
        )
        raise HTTPException(status_code=500, detail=detail) from exc


@app.post("/rag/sync", response_model=RagSyncResponse)
async def rag_sync(req: RagSyncRequest) -> RagSyncResponse:
    try:
        result = rag_sync_service.sync_user_milestones(
            user_id=req.user_id,
            force=req.force,
        )
        return RagSyncResponse(**result)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Unexpected /rag/sync failure.")
        if settings.debug_errors:
            raise HTTPException(status_code=500, detail=str(exc)) from exc
        raise HTTPException(
            status_code=500,
            detail="Internal server error while syncing RAG knowledge.",
        ) from exc


@app.post("/financial/summary", response_model=FinancialSummaryResponse)
async def financial_summary(req: FinancialSummaryRequest) -> FinancialSummaryResponse:
    try:
        return financial_service.get_summary(
            user_id=req.user_id,
            horizon_months=req.horizon_months,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Unexpected /financial/summary failure.")
        if settings.debug_errors:
            raise HTTPException(status_code=500, detail=str(exc)) from exc
        raise HTTPException(
            status_code=500,
            detail="Internal server error while processing financial summary request.",
        ) from exc


@app.post("/financial/targets", response_model=FinancialTargetResponse)
async def upsert_financial_target(req: FinancialTargetUpsertRequest) -> FinancialTargetResponse:
    try:
        return financial_service.upsert_target(
            user_id=req.user_id,
            month=req.month,
            monthly_budget_rm=req.monthly_budget_rm,
            target_growth_pct=req.target_growth_pct,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Unexpected /financial/targets failure.")
        if settings.debug_errors:
            raise HTTPException(status_code=500, detail=str(exc)) from exc
        raise HTTPException(
            status_code=500,
            detail="Internal server error while upserting financial target.",
        ) from exc


@app.get("/financial/targets", response_model=FinancialTargetResponse)
async def get_financial_target(user_id: str, month: str) -> FinancialTargetResponse:
    try:
        return financial_service.get_target(user_id=user_id, month=month)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Unexpected GET /financial/targets failure.")
        if settings.debug_errors:
            raise HTTPException(status_code=500, detail=str(exc)) from exc
        raise HTTPException(
            status_code=500,
            detail="Internal server error while loading financial target.",
        ) from exc


@app.post("/financial/logs", response_model=DailyFinancialLog)
async def upsert_financial_log(req: DailyFinancialLogUpsertRequest) -> DailyFinancialLog:
    try:
        return financial_service.upsert_daily_log(
            user_id=req.user_id,
            log_date=req.log_date,
            revenue_rm=req.revenue_rm,
            expense_rm=req.expense_rm,
            note=req.note,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Unexpected /financial/logs failure.")
        if settings.debug_errors:
            raise HTTPException(status_code=500, detail=str(exc)) from exc
        raise HTTPException(
            status_code=500,
            detail="Internal server error while upserting daily financial log.",
        ) from exc


@app.get("/financial/logs", response_model=DailyFinancialLogListResponse)
async def get_financial_logs(user_id: str, month: str) -> DailyFinancialLogListResponse:
    try:
        return financial_service.get_daily_logs(user_id=user_id, month=month)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Unexpected GET /financial/logs failure.")
        if settings.debug_errors:
            raise HTTPException(status_code=500, detail=str(exc)) from exc
        raise HTTPException(
            status_code=500,
            detail="Internal server error while loading financial logs.",
        ) from exc


@app.post("/financial/growth-graph", response_model=FinancialGrowthGraphResponse)
async def get_growth_graph(req: FinancialGrowthGraphRequest) -> FinancialGrowthGraphResponse:
    try:
        return financial_service.get_growth_graph(user_id=req.user_id, month=req.month)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Unexpected /financial/growth-graph failure.")
        if settings.debug_errors:
            raise HTTPException(status_code=500, detail=str(exc)) from exc
        raise HTTPException(
            status_code=500,
            detail="Internal server error while building growth graph.",
        ) from exc
