-- 001_roadmap_knowledge_table.sql
-- Run this script first.

create extension if not exists vector;
create extension if not exists pgcrypto;

-- Create table if it does not exist.
create table if not exists public.roadmap_knowledge (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  content text not null,
  metadata jsonb default '{}'::jsonb,
  embedding halfvec(3072) not null,
  created_at timestamptz default now()
);

-- Compatibility path for old tables that may not have user_id yet.
alter table public.roadmap_knowledge
  add column if not exists user_id uuid references auth.users(id) on delete cascade;

-- Indexes.
create index if not exists idx_roadmap_knowledge_embedding_hnsw
  on public.roadmap_knowledge
  using hnsw (embedding halfvec_cosine_ops);

create index if not exists idx_roadmap_knowledge_user_id
  on public.roadmap_knowledge (user_id);

create index if not exists idx_roadmap_knowledge_user_doc_chunk
  on public.roadmap_knowledge (
    user_id,
    ((metadata->>'source_doc_id')),
    ((metadata->>'chunk_index'))
  );

create index if not exists idx_roadmap_knowledge_source_doc_hash
  on public.roadmap_knowledge (((metadata->>'source_doc_hash')))
  where metadata ? 'source_doc_hash';

-- NOTE:
-- Do NOT force user_id to NOT NULL until legacy rows are backfilled.
