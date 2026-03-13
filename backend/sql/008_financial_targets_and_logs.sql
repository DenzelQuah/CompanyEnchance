-- 008_financial_targets_and_logs.sql
-- Phase 2: monthly target + daily revenue/expense tracking.

create extension if not exists "pgcrypto";

create table if not exists public.business_financial_targets (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  month text not null,
  monthly_budget_rm numeric not null default 0 check (monthly_budget_rm >= 0),
  target_growth_pct numeric not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, month)
);

create index if not exists idx_business_financial_targets_user_month
  on public.business_financial_targets (user_id, month);

create table if not exists public.daily_financial_logs (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  log_date date not null,
  revenue_rm numeric not null default 0 check (revenue_rm >= 0),
  expense_rm numeric not null default 0 check (expense_rm >= 0),
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, log_date)
);

create index if not exists idx_daily_financial_logs_user_date
  on public.daily_financial_logs (user_id, log_date);

