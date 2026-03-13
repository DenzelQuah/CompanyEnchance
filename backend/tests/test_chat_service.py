from app.chat_service import ChatService
from app.config import settings


class _FakeEmbeddings:
    def embed_query(self, _: str) -> list[float]:
        return [0.1, 0.2, 0.3]


class _FakeRPC:
    def __init__(self, data):
        self.data = data

    def execute(self):
        return self


class _FakeSupabase:
    def __init__(self):
        self.calls = []

    def rpc(self, fn_name: str, payload: dict):
        self.calls.append((fn_name, payload))
        if fn_name == settings.rag_match_function:
            return _FakeRPC(
                [
                    {
                        "content": "roadmap chunk",
                        "metadata": {"source_doc_id": "milestone:1"},
                        "similarity": 0.9,
                    }
                ]
            )
        if fn_name == settings.business_rag_match_function:
            return _FakeRPC(
                [
                    {
                        "content": "business chunk",
                        "metadata": {"source_doc_id": "knowledge:1"},
                        "similarity": 0.8,
                    }
                ]
            )
        return _FakeRPC([])


class _FakeLLM:
    def __init__(self, label: str):
        self.label = label

    def invoke(self, _: str):
        return self.label


def test_retrieve_documents_routes_to_roadmap() -> None:
    service = ChatService.__new__(ChatService)
    service.embeddings = _FakeEmbeddings()
    service.supabase = _FakeSupabase()
    service.llm = _FakeLLM("both")

    docs = service._retrieve_documents(
        user_id="a2db4e3d-2175-4cc7-99f8-3ff7dcf3bf70",
        question="What is my next milestone step?",
    )

    assert len(service.supabase.calls) == 1
    fn_name, payload = service.supabase.calls[0]
    assert fn_name == settings.rag_match_function
    assert payload["filter_user_id"] == "a2db4e3d-2175-4cc7-99f8-3ff7dcf3bf70"
    assert payload["query_embedding"] == [0.1, 0.2, 0.3]
    assert len(docs) == 1
    assert docs[0].page_content == "roadmap chunk"
    assert docs[0].metadata["similarity"] == 0.9
    assert docs[0].metadata["retrieval_route"] == "roadmap"


def test_retrieve_documents_routes_to_both() -> None:
    service = ChatService.__new__(ChatService)
    service.embeddings = _FakeEmbeddings()
    service.supabase = _FakeSupabase()
    service.llm = _FakeLLM("both")

    docs = service._retrieve_documents(
        user_id="a2db4e3d-2175-4cc7-99f8-3ff7dcf3bf70",
        question="How should I improve performance?",
    )

    assert len(service.supabase.calls) == 2
    assert service.supabase.calls[0][0] == settings.rag_match_function
    assert service.supabase.calls[1][0] == settings.business_rag_match_function
    assert len(docs) == 2
    assert docs[0].page_content == "roadmap chunk"
    assert docs[1].page_content == "business chunk"
