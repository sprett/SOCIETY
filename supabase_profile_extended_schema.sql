-- SOCIETY - Extended profile columns for Edit Profile & Account Settings
--
-- Run in: Supabase Dashboard -> SQL Editor (after supabase_rsvp_schema.sql)
--
-- Adds: first_name, last_name, bio, username, phone_number, social handles, website

alter table public.profiles
  add column if not exists first_name text,
  add column if not exists last_name text,
  add column if not exists bio text,
  add column if not exists username text,
  add column if not exists phone_number text,
  add column if not exists instagram_handle text,
  add column if not exists twitter_handle text,
  add column if not exists youtube_handle text,
  add column if not exists tiktok_handle text,
  add column if not exists linkedin_handle text,
  add column if not exists website_url text,
  add column if not exists birthday date;

-- Optional: backfill full_name from first_name + last_name where full_name is null
-- update public.profiles
-- set full_name = trim(concat(coalesce(first_name,''), ' ', coalesce(last_name,'')))
-- where full_name is null and (first_name is not null or last_name is not null);

-- Add unique constraint on username
alter table public.profiles
  add constraint profiles_username_unique unique (username);

-- Add check constraint for username validation
-- Min 3 chars, lowercase only, alphanumeric plus _, -, .
-- Must start and end with alphanumeric (lowercase letter or number)
alter table public.profiles
  add constraint profiles_username_valid check (
    username is null or (
      length(trim(username)) >= 3
      and username ~ '^[a-z0-9][a-z0-9._-]*[a-z0-9]$'
      and username = lower(username)
    )
  );

notify pgrst, 'reload schema';
