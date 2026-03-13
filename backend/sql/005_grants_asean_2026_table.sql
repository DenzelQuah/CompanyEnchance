-- 005_grants_asean_2026_table.sql
-- Funding grants catalog for Malaysia/Sarawak matcher.

create extension if not exists "pgcrypto";

create table if not exists public.grants_asean_2026 (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  agency text not null,
  country text not null default 'Malaysia',
  state text not null default 'Any',
  sector_tags text[] not null default '{}',
  target_business_stage text not null default 'msme',
  min_readiness_score integer not null default 0,
  max_funding_rm numeric not null default 0,
  deadline date,
  requirements text[] not null default '{}',
  application_url text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_grants_asean_2026_active
  on public.grants_asean_2026 (is_active);

create index if not exists idx_grants_asean_2026_country_state
  on public.grants_asean_2026 (country, state);

create index if not exists idx_grants_asean_2026_min_readiness
  on public.grants_asean_2026 (min_readiness_score);
