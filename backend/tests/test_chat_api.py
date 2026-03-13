from fastapi.testclient import TestClient

from main import app, chat_service, rag_sync_service


class _StubResponse:
    def __init__(self, answer: str = "ok", session_id: str = "session-1") -> None:
        self.answer = answer
        self.session_id = session_id
        self.source_documents = []


def test_health_endpoint() -> None:
    client = TestClient(app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_chat_contract_shape() -> None:
    async def fake_chat(user_id: str, message: str, session_id: str | None = None):
        assert user_id == "user-1"
        assert message == "How can I improve sales?"
        assert session_id is None
        return _StubResponse(answer="Grounded answer", session_id="session-abc")

    original = chat_service.chat
    chat_service.chat = fake_chat
    try:
        client = TestClient(app)
        response = client.post(
            "/chat",
            json={
                "user_id": "user-1",
                "message": "How can I improve sales?",
            },
        )
        assert response.status_code == 200
        payload = response.json()
        assert payload["answer"] == "Grounded answer"
        assert payload["session_id"] == "session-abc"
        assert isinstance(payload["source_documents"], list)
    finally:
        chat_service.chat = original


def test_rag_sync_contract_shape() -> None:
    def fake_sync(user_id: str, force: bool = False):
        assert user_id == "a2db4e3d-2175-4cc7-99f8-3ff7dcf3bf70"
        assert force is True
        return {
            "milestones_scanned": 3,
            "candidate_docs": 3,
            "docs_replaced": 2,
            "docs_skipped_unchanged": 1,
            "stale_docs_deleted": 0,
            "chunks_written": 8,
        }

    original = rag_sync_service.sync_user_milestones
    rag_sync_service.sync_user_milestones = fake_sync
    try:
        client = TestClient(app)
        response = client.post(
            "/rag/sync",
            json={
                "user_id": "a2db4e3d-2175-4cc7-99f8-3ff7dcf3bf70",
                "force": True,
            },
        )
        assert response.status_code == 200
        payload = response.json()
        assert payload["milestones_scanned"] == 3
        assert payload["docs_replaced"] == 2
        assert payload["chunks_written"] == 8
    finally:
        rag_sync_service.sync_user_milestones = original
