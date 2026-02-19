-- SOCIETY - Admin: last_app_open_at, last_seen_at, users_online, app_open_events
--
-- Run in: Supabase Dashboard -> SQL Editor (after supabase_admin_schema.sql)
--
-- Enables: last opened app tracking, currently live user count, and app opens per day (Most active day).
-- The iOS app must call report_app_activity() on launch/foreground.

-- 1. Add activity columns to profiles
alter table public.profiles
  add column if not exists last_app_open_at timestamptz;

alter table public.profiles
  add column if not exists last_seen_at timestamptz;

comment on column public.profiles.last_app_open_at is 'When the user last opened the app (app launch or foreground).';
comment on column public.profiles.last_seen_at is 'When the user last sent a heartbeat. Used for "currently live" count.';

-- Optional: username for admin Users tab (fallback to email local part when null)
alter table public.profiles add column if not exists username text;
comment on column public.profiles.username is 'Optional display username. Admin list falls back to email local part when null.';

-- 2. Table: app_open_events for "App opens per day" / "Most active day" in dashboard
create table if not exists public.app_open_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  opened_at timestamptz not null default now()
);
create index if not exists app_open_events_opened_at_idx on public.app_open_events (opened_at);
create index if not exists app_open_events_user_id_idx on public.app_open_events (user_id);
alter table public.app_open_events enable row level security;
drop policy if exists "app_open_events no direct insert" on public.app_open_events;
create policy "app_open_events no direct insert"
  on public.app_open_events for insert to authenticated with check (false);
drop policy if exists "app_open_events no select" on public.app_open_events;
create policy "app_open_events no select"
  on public.app_open_events for select to authenticated using (false);
comment on table public.app_open_events is 'Log of app opens for admin dashboard "Most active day". Populated by report_app_activity().';

-- 3. RPC: Call from iOS app on launch/foreground (e.g. scenePhase .active)
-- Updates last_app_open_at and last_seen_at (for live count) and logs one row to app_open_events (for app opens per day).
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

comment on function public.report_app_activity() is 'Updates last_app_open_at and last_seen_at and logs one row to app_open_events. Call on app launch and periodically while active (heartbeat).';

-- 4. Update get_admin_stats to include users_online (last_seen within 1 min)
create or replace function public.get_admin_stats()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  result json;
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  ) then
    return null;
  end if;

  select json_build_object(
    'total_users', (select count(*)::int from public.profiles),
    'users_online', (select count(*)::int from public.profiles where last_seen_at >= now() - interval '1 minute'),
    'new_signups_7d', (select count(*)::int from public.profiles where created_at >= now() - interval '7 days'),
    'total_events', (select count(*)::int from public.events),
    'new_events_7d', (select count(*)::int from public.events where created_at >= now() - interval '7 days'),
    'total_rsvps', (select count(*)::int from public.event_rsvps)
  ) into result;

  return result;
end;
$$;

grant execute on function public.get_admin_stats() to authenticated;

comment on function public.get_admin_stats() is 'Returns dashboard stats (users, users_online, events, rsvps). Caller must have profiles.role = admin.';

-- 5. get_admin_users: profile details, last_app_open_at, last_seen_at, username, sign_in_provider
drop function if exists public.get_admin_users();
create or replace function public.get_admin_users()
returns table (
  id uuid,
  full_name text,
  avatar_url text,
  created_at timestamptz,
  email text,
  phone_number text,
  events_attended int,
  events_hosted int,
  birthday date,
  last_login_at timestamptz,
  last_app_open_at timestamptz,
  last_seen_at timestamptz,
  username text,
  sign_in_provider text
)
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not exists (
    select 1 from public.profiles
    where profiles.id = auth.uid() and profiles.role = 'admin'
  ) then
    return;
  end if;

  return query
  with attended as (
    select event_rsvps.user_id, count(*)::int as attended_count
    from public.event_rsvps
    group by event_rsvps.user_id
  ),
  hosted as (
    select events.owner_id as user_id, count(*)::int as hosted_count
    from public.events
    where events.owner_id is not null
    group by events.owner_id
  )
  select
    p.id::uuid,
    p.full_name::text,
    p.avatar_url::text,
    p.created_at::timestamptz,
    au.email::text,
    p.phone_number::text,
    coalesce(a.attended_count, 0)::int as events_attended,
    coalesce(h.hosted_count, 0)::int as events_hosted,
    p.birthday::date,
    au.last_sign_in_at::timestamptz as last_login_at,
    p.last_app_open_at::timestamptz,
    p.last_seen_at::timestamptz,
    coalesce(nullif(trim(p.username), ''), split_part(au.email, '@', 1))::text as username,
    coalesce(au.raw_app_meta_data->>'provider', 'email')::text as sign_in_provider
  from public.profiles p
  left join auth.users au on au.id = p.id
  left join attended a on a.user_id = p.id
  left join hosted h on h.user_id = p.id
  order by p.created_at desc nulls last;
end;
$$;

grant execute on function public.get_admin_users() to authenticated;

comment on function public.get_admin_users() is 'Returns admin users list with profile details, auth email/last login, last_app_open_at, last_seen_at, username (fallback: email local part), sign_in_provider (from auth), and hosted/attended counts. Caller must have profiles.role = admin.';

-- iOS integration: Call report_app_activity() on:
-- 1. App launch / scenePhase .active (updates last_app_open_at and last_seen_at)
-- 2. Periodically while foregrounded (e.g. every 2–5 min) for accurate users_online count
