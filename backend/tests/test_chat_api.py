from fastapi.testclient import TestClient

from main import app, chat_service


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
