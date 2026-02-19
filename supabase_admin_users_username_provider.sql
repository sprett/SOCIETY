-- SOCIETY - Admin users list: username and sign_in_provider for get_admin_users()
--
-- Run in: Supabase Dashboard -> SQL Editor (after supabase_admin_activity.sql)
--
-- Use this if your Users tab shows "—" for Username and "Email" for everyone: it adds
-- profiles.username (if missing) and replaces get_admin_users() so the dashboard shows
-- username (fallback: email local part) and real sign-in provider (Apple, Google, email).
-- Optional: run supabase_username_auto_generate.sql to set usernames from full name (e.g. dinoh).

alter table public.profiles add column if not exists username text;

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

comment on function public.get_admin_users() is 'Returns admin users list with profile details, auth email/last login, username (fallback: email local part), sign_in_provider (from auth), last_app_open_at, last_seen_at, and hosted/attended counts. Caller must have profiles.role = admin.';
