# Supabase SQL Editor Troubleshooting

## Run Order
1. `001_roadmap_knowledge_table.sql`
2. `002_match_roadmap_docs_function.sql`
3. `003_validation_queries.sql`
4. `009_user_milestones_updated_at_sync_support.sql` (recommended for incremental sync)
5. `010_optional_align_user_id_uuid.sql` (optional; run only after precheck passes)

## Common Errors and Fixes

1. `type "halfvec" does not exist`
- Cause: `vector` extension not installed.
- Fix: ensure `create extension if not exists vector;` succeeds in script `001`.

2. `function ... does not exist` from backend
- Cause: function not created in `public` or wrong signature.
- Fix: run `002_match_roadmap_docs_function.sql`, then check signature using `003_validation_queries.sql`.

3. `column reference "id" is ambiguous`
- Cause: unqualified column names inside `returns table (...)` function.
- Fix: use table alias (`rk.id`, `rk.content`, etc.) as in script `002`.

4. No documents returned for valid queries
- Cause: `user_id` is null on legacy rows, mismatch with current user, or grouped chunk metadata missing (`source_doc_id`, `chunk_index`).
- Fix: backfill `user_id`, example:
```sql
update public.roadmap_knowledge
set user_id = '<AUTH_USER_UUID>'
where user_id is null;
```
- Also run `003_validation_queries.sql` and confirm chunk metadata counts are zero for missing fields.

5. Permission denied on function/table
- Cause: grants/RLS config mismatch.
- Fix: if using backend service role, grants are often unnecessary; otherwise add execute grants on function and verify table policies.
