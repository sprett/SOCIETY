-- SOCIETY - Avatar onboarding metadata (uses existing profile-images bucket)
--
-- Run in: Supabase Dashboard -> SQL Editor
-- After: supabase_rsvp_schema.sql and supabase_profile_extended_schema.sql

alter table public.profiles
  add column if not exists avatar_source text,
  add column if not exists avatar_seed text,
  add column if not exists avatar_style text;

alter table public.profiles
  drop constraint if exists profiles_avatar_source_valid;

alter table public.profiles
  add constraint profiles_avatar_source_valid check (
    avatar_source is null or avatar_source in ('dicebear', 'upload')
  );

-- Avatars reuse the existing 'profile-images' bucket; no extra bucket/policies required.
notify pgrst, 'reload schema';
