-- 011_business_knowledge_table_and_match_function.sql
-- Run this after 001_roadmap_knowledge_table.sql.

create extension if not exists vector;
create extension if not exists pgcrypto;

create table if not exists public.business_knowledge (
  id uuid primary key default gen_random_uuid(),
  content text not null,
  metadata jsonb default '{}'::jsonb,
  embedding halfvec(3072) not null,
  created_at timestamptz default now()
);

create index if not exists idx_business_knowledge_embedding_hnsw
  on public.business_knowledge
  using hnsw (embedding halfvec_cosine_ops);

create index if not exists idx_business_knowledge_source_doc_id
  on public.business_knowledge (((metadata->>'source_doc_id')));

create or replace function public.match_business_docs(
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
    bk.id,
    bk.content,
    bk.metadata,
    1 - (bk.embedding <=> query_embedding) as similarity
  from public.business_knowledge as bk
  where 1 - (bk.embedding <=> query_embedding) > match_threshold
  order by similarity desc
  limit match_count;
end;
$$;

grant execute on function public.match_business_docs(halfvec, float, int)
to anon, authenticated;
