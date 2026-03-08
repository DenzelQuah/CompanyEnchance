-- 004_financial_columns.sql
-- Extend survey_responses for deterministic financial projections.

alter table if exists public.survey_responses
  add column if not exists business_registration_no text,
  add column if not exists registration_type text,
  add column if not exists digital_statement_months integer not null default 0,
  add column if not exists avg_monthly_sales_rm numeric,
  add column if not exists avg_monthly_material_cost_rm numeric,
  add column if not exists avg_monthly_labor_cost_rm numeric;

alter table if exists public.survey_responses
  add constraint survey_responses_registration_type_chk
  check (
    registration_type is null
    or registration_type in ('ubin', 'ssm', 'other')
  );
