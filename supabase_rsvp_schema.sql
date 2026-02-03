-- SOCIETY - Supabase schema for RSVP functionality
--
-- Run this in: Supabase Dashboard -> SQL Editor
--
-- Creates:
-- 1. profiles table (for attendee names and avatars)
-- 2. event_rsvps table (tracks which users are attending which events)
-- 3. Trigger to sync auth.users metadata to profiles table

-- PROFILES TABLE
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  avatar_url text,
  updated_at timestamptz not null default now()
);

-- Index for faster lookups
create index if not exists profiles_id_idx on public.profiles (id);

-- RLS for profiles
alter table public.profiles enable row level security;

-- Anyone authenticated can read profiles (needed to show attendees)
drop policy if exists "profiles read authenticated" on public.profiles;
create policy "profiles read authenticated"
on public.profiles for select
to authenticated
using (true);

-- Users can only update their own profile
drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Users can insert their own profile
drop policy if exists "profiles insert own" on public.profiles;
create policy "profiles insert own"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

-- EVENT_RSVPS TABLE
create table if not exists public.event_rsvps (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(event_id, user_id)
  -- Note: Foreign key to profiles is added separately after ensuring profiles exist
);

-- Indexes for faster queries
create index if not exists event_rsvps_event_id_idx on public.event_rsvps (event_id);
create index if not exists event_rsvps_user_id_idx on public.event_rsvps (user_id);

-- Ensure profiles exist for all users (backfill for existing data)
-- This is needed before adding the foreign key constraint
-- We create profiles for ALL users, not just those with RSVPs, to be safe
insert into public.profiles (id, full_name, avatar_url, updated_at)
select 
  au.id,
  coalesce(
    au.raw_user_meta_data->>'full_name',
    case
      when au.raw_user_meta_data->>'given_name' is not null and au.raw_user_meta_data->>'family_name' is not null
      then (au.raw_user_meta_data->>'given_name') || ' ' || (au.raw_user_meta_data->>'family_name')
      else au.raw_user_meta_data->>'given_name'
    end
  ),
  au.raw_user_meta_data->>'profile_image_url',
  now()
from auth.users au
where not exists (
  select 1 from public.profiles p where p.id = au.id
)
on conflict (id) do nothing;

-- Add foreign key to profiles if it doesn't exist (for PostgREST relationship discovery)
-- This allows Supabase to understand the relationship for nested queries
do $$
begin
  if not exists (
    select 1 from pg_constraint 
    where conname = 'event_rsvps_user_id_profiles_fk'
  ) then
    alter table public.event_rsvps
    add constraint event_rsvps_user_id_profiles_fk 
    foreign key (user_id) references public.profiles(id) on delete cascade;
  end if;
end $$;

-- RLS for event_rsvps
alter table public.event_rsvps enable row level security;

-- Authenticated users can read RSVPs for events they can see (public events or their own private events)
drop policy if exists "event_rsvps read authenticated" on public.event_rsvps;
create policy "event_rsvps read authenticated"
on public.event_rsvps for select
to authenticated
using (
  exists (
    select 1 from public.events
    where events.id = event_rsvps.event_id
    and (
      events.visibility = 'public'
      or (events.visibility = 'private' and events.owner_id = auth.uid())
    )
  )
);

-- Users can only insert RSVPs for themselves
drop policy if exists "event_rsvps insert own" on public.event_rsvps;
create policy "event_rsvps insert own"
on public.event_rsvps for insert
to authenticated
with check (user_id = auth.uid());

-- Users can only delete their own RSVPs
drop policy if exists "event_rsvps delete own" on public.event_rsvps;
create policy "event_rsvps delete own"
on public.event_rsvps for delete
to authenticated
using (user_id = auth.uid());

-- TRIGGER: Sync auth.users metadata to profiles table
-- This ensures profiles are created/updated when users sign up or update their metadata

-- Function to handle profile sync
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, avatar_url, updated_at)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      case
        when new.raw_user_meta_data->>'given_name' is not null and new.raw_user_meta_data->>'family_name' is not null
        then (new.raw_user_meta_data->>'given_name') || ' ' || (new.raw_user_meta_data->>'family_name')
        else new.raw_user_meta_data->>'given_name'
      end
    ),
    new.raw_user_meta_data->>'profile_image_url',
    now()
  )
  on conflict (id) do update
  set
    full_name = coalesce(
      excluded.full_name,
      coalesce(
        new.raw_user_meta_data->>'full_name',
        case
          when new.raw_user_meta_data->>'given_name' is not null and new.raw_user_meta_data->>'family_name' is not null
          then (new.raw_user_meta_data->>'given_name') || ' ' || (new.raw_user_meta_data->>'family_name')
          else new.raw_user_meta_data->>'given_name'
        end
      )
    ),
    avatar_url = coalesce(excluded.avatar_url, new.raw_user_meta_data->>'profile_image_url'),
    updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

-- Trigger on auth.users insert
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Trigger on auth.users update (for metadata changes)
drop trigger if exists on_auth_user_updated on auth.users;
create trigger on_auth_user_updated
  after update on auth.users
  for each row
  when (
    (old.raw_user_meta_data->>'full_name' is distinct from new.raw_user_meta_data->>'full_name')
    or (old.raw_user_meta_data->>'given_name' is distinct from new.raw_user_meta_data->>'given_name')
    or (old.raw_user_meta_data->>'family_name' is distinct from new.raw_user_meta_data->>'family_name')
    or (old.raw_user_meta_data->>'profile_image_url' is distinct from new.raw_user_meta_data->>'profile_image_url')
  )
  execute procedure public.handle_new_user();

-- Force PostgREST (Supabase API) schema cache reload
notify pgrst, 'reload schema';
