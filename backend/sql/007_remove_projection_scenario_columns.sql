-- 007_remove_projection_scenario_columns.sql
-- Phase 1 cleanup: remove projection/scenario-specific survey columns.
-- Keeps ASEAN grant tables/records intact.

alter table if exists public.survey_responses
  drop column if exists avg_monthly_sales_rm,
  drop column if exists avg_monthly_material_cost_rm,
  drop column if exists avg_monthly_labor_cost_rm;

