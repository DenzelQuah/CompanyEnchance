-- RM5 monthly membership for manual DuitNow approval.
-- Run this in the Supabase SQL Editor before releasing the app.

create table if not exists public.app_subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  plan_code text not null default 'monthly_rm5'
    check (plan_code = 'monthly_rm5'),
  status text not null default 'inactive'
    check (status in ('inactive', 'active', 'expired', 'cancelled')),
  current_period_start timestamptz,
  current_period_end timestamptz,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.subscription_payment_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_code text not null default 'monthly_rm5'
    check (plan_code = 'monthly_rm5'),
  amount_sen integer not null default 500 check (amount_sen = 500),
  payment_reference text not null check (char_length(trim(payment_reference)) between 3 and 100),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewer_note text
);

create unique index if not exists subscription_one_pending_request_per_user
  on public.subscription_payment_requests(user_id)
  where status = 'pending';

alter table public.app_subscriptions enable row level security;
alter table public.subscription_payment_requests enable row level security;

grant select on public.app_subscriptions to authenticated;
grant select, insert on public.subscription_payment_requests to authenticated;

create policy "Users can view their own subscription"
  on public.app_subscriptions for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can view their own payment requests"
  on public.subscription_payment_requests for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can submit their own payment request"
  on public.subscription_payment_requests for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'pending'
    and plan_code = 'monthly_rm5'
    and amount_sen = 500
  );

-- After you verify the DuitNow transfer, run this as an administrator.
-- Replace both UUID placeholders with the user's auth.users UUID.
-- insert into public.app_subscriptions (user_id, status, current_period_start, current_period_end, approved_at)
-- values ('USER_UUID', 'active', now(), now() + interval '1 month', now())
-- on conflict (user_id) do update set
--   status = 'active', current_period_start = excluded.current_period_start,
--   current_period_end = excluded.current_period_end, approved_at = excluded.approved_at,
--   updated_at = now();
-- update public.subscription_payment_requests set status = 'approved', reviewed_at = now()
-- where user_id = 'USER_UUID' and status = 'pending';
