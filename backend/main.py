import logging

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.chat_service import ChatService
from app.config import settings
from app.models import ChatRequest, ChatResponse

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
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Unexpected /chat failure.")
        if settings.debug_errors:
            raise HTTPException(status_code=500, detail=str(exc)) from exc
        raise HTTPException(
            status_code=500,
            detail="Internal server error while processing chat request.",
        ) from exc
