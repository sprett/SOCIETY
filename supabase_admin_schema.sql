-- SOCIETY - Admin dashboard: profiles.role, profiles.created_at, get_admin_stats()
--
-- Run in: Supabase Dashboard -> SQL Editor (after supabase_rsvp_schema.sql and profile extended schema)
--
-- Enables: admin-only dashboard access and server-side stats.

-- 1. Add created_at to profiles (for "new signups" stats)
alter table public.profiles
  add column if not exists created_at timestamptz default now();

-- Backfill created_at for existing rows (use updated_at as proxy where null)
update public.profiles
set created_at = coalesce(created_at, updated_at, now())
where created_at is null;

-- 2. Add role to profiles ('user' | 'admin')
alter table public.profiles
  add column if not exists role text not null default 'user';

alter table public.profiles
  drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check check (role in ('user', 'admin'));

-- 3. SECURITY DEFINER function: returns stats only for admins
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
    'new_signups_7d', (select count(*)::int from public.profiles where created_at >= now() - interval '7 days'),
    'total_events', (select count(*)::int from public.events),
    'new_events_7d', (select count(*)::int from public.events where created_at >= now() - interval '7 days'),
    'total_rsvps', (select count(*)::int from public.event_rsvps)
  ) into result;

  return result;
end;
$$;

grant execute on function public.get_admin_stats() to authenticated;

comment on function public.get_admin_stats() is 'Returns dashboard stats (users, events, rsvps). Caller must have profiles.role = admin.';

-- 4. SECURITY DEFINER function: returns user list details for admin users page
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
  last_login_at timestamptz
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
    au.last_sign_in_at::timestamptz as last_login_at
  from public.profiles p
  left join auth.users au on au.id = p.id
  left join attended a on a.user_id = p.id
  left join hosted h on h.user_id = p.id
  order by p.created_at desc nulls last;
end;
$$;

grant execute on function public.get_admin_users() to authenticated;

comment on function public.get_admin_users() is 'Returns admin users list with profile details, auth email/last login, and hosted/attended counts. Caller must have profiles.role = admin.';

-- 5. After running this migration, set your admin user(s):
--    update public.profiles set role = 'admin' where id = auth.uid();
--    Or in Dashboard: Table Editor -> profiles -> set role to 'admin' for your row.
