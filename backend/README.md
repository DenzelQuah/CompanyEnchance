# FastAPI RAG Backend

## Run

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
uvicorn main:app --reload --port 8000
```

Set Flutter `.env`:

```env
CHAT_API_URL=http://10.0.2.2:8000/chat
```

## Endpoint

`POST /chat`

Request:

```json
{
  "user_id": "uuid",
  "message": "How do I improve exports?",
  "session_id": "optional-uuid"
}
```

Response:

```json
{
  "answer": "Grounded response with citations [Source 1]",
  "source_documents": [
    {
      "content": "retrieved chunk",
      "metadata": {}
    }
  ],
  "session_id": "uuid"
}
```

## Notes

- Uses Supabase Vector Store retriever against `roadmap_knowledge`.
- Uses Gemini 2.5 Flash (`GEMINI_CHAT_MODEL`) for generation.
- Uses `models/gemini-embedding-001` for embeddings.
- Loads last 5 messages from `chat_messages` for context.
- If input indicates update intent, backend calls Supabase RPC function configured by `ROADMAP_UPDATE_FUNCTION`.
