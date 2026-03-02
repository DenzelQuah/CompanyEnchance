from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from langchain_community.vectorstores import SupabaseVectorStore
from langchain_core.documents import Document
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings
from supabase import Client, create_client

from .config import settings
from .models import ChatResponse, SourceDocument


class ChatService:
    """RAG orchestration layer using Supabase Vector Store + Gemini."""

    def __init__(self) -> None:
        self.supabase: Client = create_client(
            settings.supabase_url, settings.supabase_service_role_key
        )
        self.embeddings = GoogleGenerativeAIEmbeddings(
            model=settings.gemini_embedding_model,
            google_api_key=settings.gemini_api_key,
        )
        self.llm = ChatGoogleGenerativeAI(
            model=settings.gemini_chat_model,
            google_api_key=settings.gemini_api_key,
            temperature=0.2,
        )
        self.vector_store = SupabaseVectorStore(
            client=self.supabase,
            embedding=self.embeddings,
            table_name=settings.rag_table_name,
            query_name=settings.rag_match_function,
        )

        # "RAG from scratch" style: prompt -> model -> output parser.
        self.prompt = ChatPromptTemplate.from_messages(
            [
                (
                    "system",
                    "You are a business roadmap assistant. Use retrieved context as primary evidence. "
                    "If context is missing, state that clearly. Cite evidence inline as [Source N].",
                ),
                (
                    "human",
                    "Chat history (last 5):\n{history}\n\n"
                    "Retrieved context:\n{context}\n\n"
                    "Question:\n{question}",
                ),
            ]
        )
        self.answer_chain = self.prompt | self.llm | StrOutputParser()

    async def chat(
        self, user_id: str, message: str, session_id: str | None = None
    ) -> ChatResponse:
        sid = self._get_or_create_session(user_id=user_id, session_id=session_id)
        self._save_message(session_id=sid, user_id=user_id, role="user", content=message)
        history_rows = self._fetch_last_messages(session_id=sid, limit=5)

        if self._is_update_intent(message):
            update_result = self._call_update_tool(user_id=user_id, message=message)
            answer = (
                f"Roadmap update executed via tool `{settings.roadmap_update_function}`. "
                f"Result: {update_result}"
            )
            self._save_message(
                session_id=sid,
                user_id=user_id,
                role="assistant",
                content=answer,
            )
            return ChatResponse(answer=answer, source_documents=[], session_id=sid)

        self._validate_embedding_size(message)
        docs = self._retrieve_documents(question=message)
        context = self._format_docs(docs)
        history = self._format_history(history_rows)

        answer = self.answer_chain.invoke(
            {"question": message, "history": history, "context": context}
        )

        self._save_message(session_id=sid, user_id=user_id, role="assistant", content=answer)

        source_documents = [
            SourceDocument(content=doc.page_content, metadata=doc.metadata or {})
            for doc in docs
        ]
        return ChatResponse(answer=answer, source_documents=source_documents, session_id=sid)

    def _retrieve_documents(self, question: str) -> list[Document]:
        # Uses SupabaseVectorStore retrieval and applies threshold filtering.
        scored = self.vector_store.similarity_search_with_relevance_scores(
            query=question,
            k=settings.rag_top_k,
        )
        docs = [
            doc for (doc, score) in scored if score is not None and score >= settings.rag_match_threshold
        ]
        return docs

    def _format_docs(self, docs: list[Document]) -> str:
        if not docs:
            return "No relevant roadmap documents were retrieved."
        return "\n\n".join(
            [f"[Source {index + 1}] {doc.page_content}" for index, doc in enumerate(docs)]
        )

    def _format_history(self, history_rows: list[dict[str, str]]) -> str:
        if not history_rows:
            return "No prior messages."
        return "\n".join([f"{m['role']}: {m['content']}" for m in history_rows])

    def _is_update_intent(self, message: str) -> bool:
        lower = message.lower()
        verbs = ("update", "add", "change", "complete", "delete", "move")
        return any(verb in lower for verb in verbs)

    def _call_update_tool(self, user_id: str, message: str) -> Any:
        payload = {"user_id": user_id, "instruction": message}
        result = self.supabase.rpc(settings.roadmap_update_function, payload).execute()
        return result.data

    def _validate_embedding_size(self, text: str) -> None:
        vector = self.embeddings.embed_query(text)
        if len(vector) != settings.rag_embedding_dim:
            raise ValueError(
                "Embedding dimension mismatch: "
                f"expected {settings.rag_embedding_dim}, got {len(vector)}"
            )

    def _get_or_create_session(self, user_id: str, session_id: str | None) -> str:
        if session_id:
            return session_id

        existing = (
            self.supabase.table("chat_sessions")
            .select("id")
            .eq("user_id", user_id)
            .order("updated_at", desc=True)
            .limit(1)
            .execute()
        )
        if existing.data:
            return existing.data[0]["id"]

        created = (
            self.supabase.table("chat_sessions")
            .insert({"user_id": user_id, "title": "Roadmap Chat"})
            .execute()
        )
        return created.data[0]["id"]

    def _fetch_last_messages(self, session_id: str, limit: int = 5) -> list[dict[str, str]]:
        result = (
            self.supabase.table("chat_messages")
            .select("role,content")
            .eq("session_id", session_id)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )
        rows = list(result.data or [])
        rows.reverse()
        return [
            {"role": str(row.get("role", "user")), "content": str(row.get("content", ""))}
            for row in rows
        ]

    def _save_message(self, session_id: str, user_id: str, role: str, content: str) -> None:
        self.supabase.table("chat_messages").insert(
            {
                "session_id": session_id,
                "user_id": user_id,
                "role": role,
                "content": content,
            }
        ).execute()
        self.supabase.table("chat_sessions").update(
            {"updated_at": datetime.now(timezone.utc).isoformat()}
        ).eq("id", session_id).execute()
