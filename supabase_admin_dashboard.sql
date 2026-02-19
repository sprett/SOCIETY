-- SOCIETY - Admin dashboard: get_admin_dashboard(period), get_admin_events()
--
-- Run in: Supabase Dashboard -> SQL Editor (after supabase_admin_activity.sql and supabase_rsvp_schema.sql for RSVP stats).
--
-- Enables: timeframe-based dashboard stats (incl. rsvps_in_period, rsvps_prev_period), time-series (signups, events, rsvps per day), events-by-category for charts; admin events list page.

-- 1. get_admin_dashboard(period text) — period is '7', '30', '90', or '365'
-- Returns JSON: stats (current + previous period for deltas), time_series, events_by_category
create or replace function public.get_admin_dashboard(period_days text default '30')
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  days int;
  range_end timestamptz := now();
  range_start timestamptz;
  prev_end timestamptz;
  prev_start timestamptz;
  result json;
  signups_period int;
  signups_prev int;
  events_period int;
  events_prev int;
  rsvps_period int;
  rsvps_prev int;
  users_online int;
  ts json;
  by_cat json;
  app_opens_dow json;
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  ) then
    return null;
  end if;

  days := least(365, greatest(1, coalesce(period_days::int, 30)));
  range_start := range_end - (days || ' days')::interval;
  prev_end := range_start;
  prev_start := prev_end - (days || ' days')::interval;

  -- Stats: signups and events in current and previous period
  select count(*)::int from public.profiles where created_at >= range_start and created_at < range_end into signups_period;
  select count(*)::int from public.profiles where created_at >= prev_start and created_at < prev_end into signups_prev;
  select count(*)::int from public.events where created_at >= range_start and created_at < range_end into events_period;
  select count(*)::int from public.events where created_at >= prev_start and created_at < prev_end into events_prev;
  select count(*)::int from public.profiles where last_seen_at >= now() - interval '1 minute' into users_online;

  -- RSVPs in current and previous period (event_rsvps.created_at)
  begin
    select count(*)::int from public.event_rsvps where created_at >= range_start and created_at < range_end into rsvps_period;
    select count(*)::int from public.event_rsvps where created_at >= prev_start and created_at < prev_end into rsvps_prev;
  exception when undefined_table then
    rsvps_period := 0;
    rsvps_prev := 0;
  end;

  -- Time series: one row per day with signups_count, events_count, rsvps_count
  select json_agg(
    json_build_object(
      'date', gs.d::date,
      'signups_count', coalesce(s.cnt, 0),
      'events_count', coalesce(e.cnt, 0),
      'rsvps_count', coalesce(r.cnt, 0)
    ) order by gs.d
  ) into ts
  from generate_series(range_start::date, range_end::date, '1 day'::interval) as gs(d)
  left join (
    select date_trunc('day', created_at)::date as day, count(*)::int as cnt
    from public.profiles
    where created_at >= range_start and created_at < range_end
    group by 1
  ) s on s.day = gs.d
  left join (
    select date_trunc('day', created_at)::date as day, count(*)::int as cnt
    from public.events
    where created_at >= range_start and created_at < range_end
    group by 1
  ) e on e.day = gs.d
  left join (
    select date_trunc('day', created_at)::date as day, count(*)::int as cnt
    from public.event_rsvps
    where created_at >= range_start and created_at < range_end
    group by 1
  ) r on r.day = gs.d;

  -- Events by category (current period only)
  select json_agg(
    json_build_object('category', category, 'count', cnt) order by cnt desc
  ) into by_cat
  from (
    select category, count(*)::int as cnt
    from public.events
    where created_at >= range_start and created_at < range_end
    group by category
  ) t;

  -- App opens by day of week (0=Sun..6=Sat) for "Most active day" chart; include all days with 0 if no opens
  begin
    select json_agg(
      json_build_object('day_index', gs.d, 'day_name', gs.n, 'count', coalesce(o.cnt, 0)) order by gs.d
    ) into app_opens_dow
    from (values (0,'Sun'),(1,'Mon'),(2,'Tue'),(3,'Wed'),(4,'Thu'),(5,'Fri'),(6,'Sat')) as gs(d, n)
    left join (
      select extract(dow from opened_at)::int as day_index, count(*)::int as cnt
      from public.app_open_events
      where opened_at >= range_start and opened_at < range_end
      group by 1
    ) o on o.day_index = gs.d;
  exception when undefined_table then
    app_opens_dow := '[]'::json;
  end;

  select json_build_object(
    'stats', json_build_object(
      'signups_in_period', signups_period,
      'signups_prev_period', signups_prev,
      'events_in_period', events_period,
      'events_prev_period', events_prev,
      'rsvps_in_period', coalesce(rsvps_period, 0),
      'rsvps_prev_period', coalesce(rsvps_prev, 0),
      'users_online', users_online,
      'period_days', days,
      'range_start', range_start,
      'range_end', range_end
    ),
    'time_series', coalesce(ts, '[]'::json),
    'events_by_category', coalesce(by_cat, '[]'::json),
    'app_opens_by_dow', coalesce(app_opens_dow, '[]'::json)
  ) into result;

  return result;
end;
$$;

grant execute on function public.get_admin_dashboard(text) to authenticated;

comment on function public.get_admin_dashboard(text) is 'Returns dashboard data for period (7/30/90/365 days): stats with previous-period counts, daily time_series, events_by_category. Caller must have profiles.role = admin.';

-- 2. get_admin_events() — admin-only list of events (bypasses RLS)
create or replace function public.get_admin_events()
returns table (
  id uuid,
  title text,
  category text,
  start_at timestamptz,
  created_at timestamptz,
  visibility text,
  owner_id uuid,
  venue_name text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles
    where profiles.id = auth.uid() and profiles.role = 'admin'
  ) then
    return;
  end if;

  return query
  select
    e.id,
    e.title,
    e.category,
    e.start_at,
    e.created_at,
    e.visibility,
    e.owner_id,
    e.venue_name
  from public.events e
  order by e.created_at desc nulls last;
end;
$$;

grant execute on function public.get_admin_events() to authenticated;

comment on function public.get_admin_events() is 'Returns all events for admin list. Caller must have profiles.role = admin.';
