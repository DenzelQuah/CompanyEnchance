-- 010_optional_align_user_id_uuid.sql
-- Optional: align user_milestones.user_id to uuid.
-- Run ONLY if all user_id values are valid UUID strings.

-- Precheck invalid values:
-- select user_id
-- from public.user_milestones
-- where user_id is null
--    or user_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

-- If precheck returns zero rows, execute:
-- alter table public.user_milestones
--   alter column user_id type uuid
--   using user_id::uuid;

-- create index if not exists idx_user_milestones_user_id_uuid
--   on public.user_milestones (user_id);
