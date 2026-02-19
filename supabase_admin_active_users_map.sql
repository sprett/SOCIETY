-- SOCIETY - Admin: Active Users Map (location columns + get_active_users_map RPC)
--
-- Run in: Supabase Dashboard -> SQL Editor (after supabase_admin_activity.sql)
--
-- Enables: Active Users map on admin Users page. Requires report-app-activity Edge Function
-- to populate last_known_lat/lng via IP geolocation when users report app activity.

-- 1. Add last-known location columns to profiles (updated by Edge Function)
alter table public.profiles
  add column if not exists last_known_lat double precision;

alter table public.profiles
  add column if not exists last_known_lng double precision;

comment on column public.profiles.last_known_lat is 'Approximate latitude from IP geolocation when user last reported app activity.';
comment on column public.profiles.last_known_lng is 'Approximate longitude from IP geolocation when user last reported app activity.';

-- 2. RPC: Returns active users count and GeoJSON for map (admin only)
create or replace function public.get_active_users_map()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_active_count int;
  v_features json;
  v_geo_json json;
begin
  if not exists (
    select 1 from public.profiles
    where profiles.id = auth.uid() and profiles.role = 'admin'
  ) then
    return null;
  end if;

  with active as (
    select
      p.id,
      p.last_known_lat as lat,
      p.last_known_lng as lng
    from public.profiles p
    where p.last_seen_at >= now() - interval '1 minute'
      and p.last_known_lat is not null
      and p.last_known_lng is not null
  )
  select
    (select count(*)::int from active),
    coalesce(
      (select json_agg(
        json_build_object(
          'type', 'Feature',
          'geometry', json_build_object(
            'type', 'Point',
            'coordinates', json_build_array(a.lng, a.lat)
          ),
          'properties', json_build_object('count', 1)
        )
      ) from active a),
      '[]'::json
    )
  from (select 1) _
  into v_active_count, v_features;

  v_geo_json := json_build_object(
    'type', 'FeatureCollection',
    'features', coalesce(v_features, '[]'::json)
  );

  return json_build_object(
    'active_count', v_active_count,
    'geo_json', v_geo_json
  );
end;
$$;

grant execute on function public.get_active_users_map() to authenticated;

comment on function public.get_active_users_map() is 'Returns active_count (users online in last 1 min with location) and geo_json FeatureCollection for map. Caller must have profiles.role = admin.';
