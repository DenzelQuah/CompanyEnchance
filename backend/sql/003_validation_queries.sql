-- 003_validation_queries.sql
-- Run these checks after scripts 001 and 002.

-- 1) Function existence
select proname
from pg_proc
where proname = 'match_roadmap_docs';

-- 2) Function signature check
select
  p.proname as function_name,
  pg_catalog.pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'match_roadmap_docs';

-- 3) Legacy row check
select count(*) as null_user_rows
from public.roadmap_knowledge
where user_id is null;

-- 4) Metadata integrity checks for grouped chunk ingestion
select count(*) as missing_source_doc_id
from public.roadmap_knowledge
where not (metadata ? 'source_doc_id');

select count(*) as missing_source_doc_hash
from public.roadmap_knowledge
where not (metadata ? 'source_doc_hash');

select count(*) as missing_chunk_index
from public.roadmap_knowledge
where not (metadata ? 'chunk_index');

select count(*) as missing_chunk_total
from public.roadmap_knowledge
where not (metadata ? 'chunk_total');

select count(*) as missing_milestone_id
from public.roadmap_knowledge
where (metadata->>'source_type' = 'user_milestone')
  and not (metadata ? 'milestone_id');

-- 5) Chunk ordering consistency by user/doc
select
  user_id,
  metadata->>'source_doc_id' as source_doc_id,
  count(*) as chunk_rows,
  min((metadata->>'chunk_index')::int) as min_chunk_index,
  max((metadata->>'chunk_index')::int) as max_chunk_index
from public.roadmap_knowledge
where metadata ? 'source_doc_id'
group by user_id, metadata->>'source_doc_id'
order by chunk_rows desc;

-- 6) Duplicate chunk index per user/doc (should be zero rows)
select
  user_id,
  metadata->>'source_doc_id' as source_doc_id,
  (metadata->>'chunk_index')::int as chunk_index,
  count(*) as duplicate_count
from public.roadmap_knowledge
where metadata ? 'source_doc_id'
  and metadata ? 'chunk_index'
group by user_id, metadata->>'source_doc_id', (metadata->>'chunk_index')::int
having count(*) > 1;

-- 7) Orphan milestone chunks (should be zero rows)
select count(*) as orphan_milestone_chunks
from public.roadmap_knowledge rk
left join public.user_milestones um
  on um.id::text = rk.metadata->>'milestone_id'
 and um.user_id::text = rk.user_id::text
where rk.metadata->>'source_type' = 'user_milestone'
  and um.id is null;

-- 8) Optional smoke test (replace values):
-- select *
-- from public.match_roadmap_docs(
--   '00000000-0000-0000-0000-000000000000'::uuid,
--   '[0,0,0]'::halfvec,
--   0.5,
--   5
-- );
