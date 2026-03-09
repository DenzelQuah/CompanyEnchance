-- 002_match_roadmap_docs_function.sql
-- Run this script after 001_roadmap_knowledge_table.sql.

create or replace function public.match_roadmap_docs(
  filter_user_id uuid,
  query_embedding halfvec(3072),
  match_threshold float,
  match_count int
)
returns table (
  id uuid,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    rk.id,
    rk.content,
    rk.metadata,
    1 - (rk.embedding <=> query_embedding) as similarity
  from public.roadmap_knowledge as rk
  where (rk.user_id = filter_user_id or rk.user_id is null)
    and 1 - (rk.embedding <=> query_embedding) > match_threshold
  order by similarity desc
  limit match_count;
end;
$$;

-- Optional grant for anon/authenticated clients.
-- If your backend uses service_role only, this is optional.
grant execute on function public.match_roadmap_docs(uuid, halfvec, float, int)
to anon, authenticated;
