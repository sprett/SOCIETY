-- SOCIETY - Admin user profile detail + profile updates
--
-- Run in: Supabase Dashboard -> SQL Editor (after admin schema/activity scripts)

create or replace function public.get_admin_user_profile(
  p_username text,
  p_period_days text default '90'
)
returns json
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_days int := least(365, greatest(1, coalesce(nullif(trim(p_period_days), '')::int, 90)));
  v_range_start timestamptz := now() - (v_days || ' days')::interval;
  v_user_id uuid;
  v_result json;
begin
  if not exists (
    select 1 from public.profiles
    where profiles.id = auth.uid() and profiles.role = 'admin'
  ) then
    return null;
  end if;

  select p.id
  into v_user_id
  from public.profiles p
  where lower(trim(coalesce(p.username, ''))) = lower(trim(coalesce(p_username, '')))
  limit 1;

  if v_user_id is null then
    return null;
  end if;

  with profile_data as (
    select
      p.id,
      p.full_name,
      p.username,
      p.avatar_url,
      p.birthday,
      p.created_at,
      au.last_sign_in_at as last_login_at,
      p.last_app_open_at,
      p.last_seen_at,
      au.email,
      p.phone_number,
      p.instagram_handle,
      p.twitter_handle,
      p.youtube_handle,
      p.tiktok_handle,
      p.linkedin_handle,
      p.website_url
    from public.profiles p
    left join auth.users au on au.id = p.id
    where p.id = v_user_id
  ),
  hosted_events as (
    select e.id, e.title, e.start_at, e.category, e.image_url, e.venue_name
    from public.events e
    where e.owner_id = v_user_id
  ),
  attended_events as (
    select e.id, e.title, e.start_at, e.category, e.image_url, e.venue_name
    from public.event_rsvps r
    join public.events e on e.id = r.event_id
    where r.user_id = v_user_id and e.start_at < now()
  ),
  upcoming_events as (
    select e.id, e.title, e.start_at, e.category, e.image_url, e.venue_name
    from public.event_rsvps r
    join public.events e on e.id = r.event_id
    where r.user_id = v_user_id and e.start_at >= now()
  ),
  profile_metrics as (
    select json_build_object(
      'app_opens_total', (
        select count(*)::int
        from public.app_open_events ao
        where ao.user_id = v_user_id
      ),
      'app_opens_in_period', (
        select count(*)::int
        from public.app_open_events ao
        where ao.user_id = v_user_id and ao.opened_at >= v_range_start
      ),
      'hosted_total', (select count(*)::int from hosted_events),
      'attended_past_total', (select count(*)::int from attended_events),
      'signed_up_upcoming_total', (select count(*)::int from upcoming_events)
    ) as payload
  ),
  chart_source as (
    select distinct e.id, e.start_at, coalesce(nullif(trim(e.category), ''), 'Uncategorized') as category
    from (
      select id, start_at, category from hosted_events
      union
      select id, start_at, category from attended_events
      union
      select id, start_at, category from upcoming_events
    ) e
    where e.start_at >= v_range_start
  ),
  active_day as (
    select json_agg(
      json_build_object('day_index', gs.d, 'day_name', gs.n, 'count', coalesce(c.cnt, 0))
      order by gs.d
    ) as payload
    from (values (0,'Sun'),(1,'Mon'),(2,'Tue'),(3,'Wed'),(4,'Thu'),(5,'Fri'),(6,'Sat')) as gs(d, n)
    left join (
      select extract(dow from start_at)::int as day_index, count(*)::int as cnt
      from chart_source
      group by 1
    ) c on c.day_index = gs.d
  ),
  categories as (
    select json_agg(
      json_build_object('category', category, 'count', cnt)
      order by cnt desc, category asc
    ) as payload
    from (
      select category, count(*)::int as cnt
      from chart_source
      group by category
    ) s
  )
  select json_build_object(
    'profile', (
      select row_to_json(pd) from profile_data pd
    ),
    'metrics', (
      select payload from profile_metrics
    ),
    'events', json_build_object(
      'hosted_recent', (
        select coalesce(json_agg(row_to_json(x) order by x.start_at desc), '[]'::json)
        from (
          select * from hosted_events order by start_at desc limit 12
        ) x
      ),
      'attended_past_recent', (
        select coalesce(json_agg(row_to_json(x) order by x.start_at desc), '[]'::json)
        from (
          select * from attended_events order by start_at desc limit 12
        ) x
      ),
      'signed_up_upcoming_recent', (
        select coalesce(json_agg(row_to_json(x) order by x.start_at asc), '[]'::json)
        from (
          select * from upcoming_events order by start_at asc limit 12
        ) x
      )
    ),
    'charts', json_build_object(
      'active_day', coalesce((select payload from active_day), '[]'::json),
      'categories', coalesce((select payload from categories), '[]'::json)
    )
  ) into v_result;

  return v_result;
end;
$$;

grant execute on function public.get_admin_user_profile(text, text) to authenticated;

comment on function public.get_admin_user_profile(text, text) is 'Returns admin-only detailed user profile by username, including metrics, event strips, and chart data.';

create or replace function public.admin_update_user_profile(
  p_user_id uuid,
  p_full_name text default null,
  p_username text default null,
  p_phone_number text default null,
  p_birthday date default null,
  p_avatar_url text default null,
  p_instagram_handle text default null,
  p_twitter_handle text default null,
  p_youtube_handle text default null,
  p_tiktok_handle text default null,
  p_linkedin_handle text default null,
  p_website_url text default null
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text := nullif(lower(trim(coalesce(p_username, ''))), '');
  v_profile record;
begin
  if not exists (
    select 1 from public.profiles
    where profiles.id = auth.uid() and profiles.role = 'admin'
  ) then
    return json_build_object('success', false, 'error', 'forbidden');
  end if;

  if v_username is not null and (
    length(v_username) < 3 or
    v_username !~ '^[a-z0-9][a-z0-9._-]*[a-z0-9]$'
  ) then
    return json_build_object('success', false, 'error', 'invalid_username');
  end if;

  if v_username is not null and exists (
    select 1
    from public.profiles p
    where p.id <> p_user_id and lower(trim(coalesce(p.username, ''))) = v_username
  ) then
    return json_build_object('success', false, 'error', 'username_taken');
  end if;

  update public.profiles
  set
    full_name = nullif(trim(coalesce(p_full_name, '')), ''),
    username = v_username,
    phone_number = nullif(trim(coalesce(p_phone_number, '')), ''),
    birthday = p_birthday,
    avatar_url = nullif(trim(coalesce(p_avatar_url, '')), ''),
    instagram_handle = nullif(trim(coalesce(p_instagram_handle, '')), ''),
    twitter_handle = nullif(trim(coalesce(p_twitter_handle, '')), ''),
    youtube_handle = nullif(trim(coalesce(p_youtube_handle, '')), ''),
    tiktok_handle = nullif(trim(coalesce(p_tiktok_handle, '')), ''),
    linkedin_handle = nullif(trim(coalesce(p_linkedin_handle, '')), ''),
    website_url = nullif(trim(coalesce(p_website_url, '')), '')
  where id = p_user_id
  returning id, username, full_name into v_profile;

  if v_profile.id is null then
    return json_build_object('success', false, 'error', 'user_not_found');
  end if;

  return json_build_object(
    'success', true,
    'profile', json_build_object(
      'id', v_profile.id,
      'username', v_profile.username,
      'full_name', v_profile.full_name
    )
  );
end;
$$;

grant execute on function public.admin_update_user_profile(uuid, text, text, text, date, text, text, text, text, text, text, text) to authenticated;

comment on function public.admin_update_user_profile(uuid, text, text, text, date, text, text, text, text, text, text, text) is 'Admin-only profile updates. Does not change auth email/phone.';
