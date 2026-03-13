-- 009_user_milestones_updated_at_sync_support.sql
-- Adds update-tracking and helpful indexes for incremental RAG sync.

alter table public.user_milestones
  add column if not exists updated_at timestamptz default now();

update public.user_milestones
set updated_at = coalesce(updated_at, created_at, now())
where updated_at is null;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_user_milestones_set_updated_at on public.user_milestones;
create trigger trg_user_milestones_set_updated_at
before update on public.user_milestones
for each row
execute function public.set_updated_at();

create index if not exists idx_user_milestones_user_updated_at
  on public.user_milestones (user_id, updated_at desc);

create index if not exists idx_roadmap_knowledge_source_doc_id
  on public.roadmap_knowledge (((metadata->>'source_doc_id')));

create index if not exists idx_roadmap_knowledge_milestone_id
  on public.roadmap_knowledge (((metadata->>'milestone_id')))
  where metadata ? 'milestone_id';
