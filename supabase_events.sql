-- SOCIETY - Supabase schema (Events-only MVP)
--
-- Run this in: Supabase Dashboard -> SQL Editor
--
-- Assumptions:
-- - You use Supabase Auth (email/password) and require sign-in for creating/deleting events.
-- - Public users (anon) can read public events (visibility='public').
--
-- Notes:
-- - We store `address_line` (user-facing) AND derived `latitude`/`longitude` (for map).
-- - The app will geocode via MapKit (Option B: autocomplete + pick place) and save coords.

-- EVENTS TABLE
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  -- DEV ONLY: allow null owner_id for anon inserts.
  owner_id uuid references auth.users(id) on delete set null,

  title text not null,
  category text not null,
  about text,

  start_at timestamptz not null,
  end_at timestamptz,

  venue_name text,
  address_line text not null,
  neighborhood text,

  latitude double precision,
  longitude double precision,

  image_url text,
  is_featured boolean not null default false,
  visibility text not null default 'public' check (visibility in ('public', 'private')),

  created_at timestamptz not null default now()
);

-- If you already created `public.events` before, the CREATE TABLE above will NOT add new columns.
-- This fixes the "Could not find the 'neighborhood' column of 'events' in the schema cache" error.
alter table public.events add column if not exists neighborhood text;

create index if not exists events_start_at_idx on public.events (start_at);
create index if not exists events_owner_id_idx on public.events (owner_id);
create index if not exists events_visibility_idx on public.events (visibility);

-- RLS
alter table public.events enable row level security;

-- Anyone can read public events
drop policy if exists "events read public" on public.events;
create policy "events read public"
on public.events for select
to anon, authenticated
using (visibility = 'public');

-- Signed-in users can also read their own private events
drop policy if exists "events read own private" on public.events;
create policy "events read own private"
on public.events for select
to authenticated
using (visibility = 'private' and owner_id = auth.uid());

-- Signed-in users can insert events only for themselves
drop policy if exists "events insert own" on public.events;
create policy "events insert own"
on public.events for insert
to authenticated
with check (owner_id = auth.uid());

-- Signed-in users can update only their own events
drop policy if exists "events update own" on public.events;
create policy "events update own"
on public.events for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

-- Signed-in users can delete only their own events
drop policy if exists "events delete own" on public.events;
create policy "events delete own"
on public.events for delete
to authenticated
using (owner_id = auth.uid());

-- DEV ONLY: allow anon inserts/deletes for local development.
drop policy if exists "events insert anon dev" on public.events;
create policy "events insert anon dev"
on public.events for insert
to anon
with check (true);

drop policy if exists "events delete anon dev" on public.events;
create policy "events delete anon dev"
on public.events for delete
to anon
using (true);

-- Force PostgREST (Supabase API) schema cache reload
notify pgrst, 'reload schema';