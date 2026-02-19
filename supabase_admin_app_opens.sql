-- SOCIETY - Admin: app_open_events for "Most active day" (app opens by day of week)
--
-- Run in: Supabase Dashboard -> SQL Editor (after supabase_admin_activity.sql, before or with supabase_admin_dashboard.sql)
--
-- Enables: report_app_activity() to log each app open; dashboard can show app opens by day of week.
-- If you already ran supabase_admin_activity.sql before it included app_open_events, run this script
-- once in the SQL Editor to create the table and update report_app_activity() so "App opens" stat updates.

-- 1. Table: one row per app open (called from iOS on launch/foreground)
create table if not exists public.app_open_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  opened_at timestamptz not null default now()
);

create index if not exists app_open_events_opened_at_idx on public.app_open_events (opened_at);
create index if not exists app_open_events_user_id_idx on public.app_open_events (user_id);

alter table public.app_open_events enable row level security;

-- Only the RPC (security definer) inserts; admins read via get_admin_dashboard
drop policy if exists "app_open_events no direct insert" on public.app_open_events;
create policy "app_open_events no direct insert"
on public.app_open_events for insert
to authenticated
with check (false);

drop policy if exists "app_open_events no select" on public.app_open_events;
create policy "app_open_events no select"
on public.app_open_events for select
to authenticated
using (false);

comment on table public.app_open_events is 'Log of app opens for admin dashboard "Most active day". Populated by report_app_activity().';

-- 2. Update report_app_activity to log each open (so we can aggregate by day of week)
create or replace function public.report_app_activity()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set
    last_app_open_at = now(),
    last_seen_at = now()
  where id = auth.uid();

  insert into public.app_open_events (user_id, opened_at)
  values (auth.uid(), now());
end;
$$;

grant execute on function public.report_app_activity() to authenticated;

comment on function public.report_app_activity() is 'Updates last_app_open_at and last_seen_at and logs one row to app_open_events for "Most active day" chart. Call on app launch and periodically while active.';
