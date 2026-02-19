-- SOCIETY - Launch gate profile status fields
--
-- Run in: Supabase Dashboard -> SQL Editor
--
-- Adds fields used by iOS launch gate routing:
-- - onboarding_completed: whether profile setup/onboarding is complete
-- - is_active: whether account is active
-- - deleted_at: soft-delete timestamp (null means active)

alter table public.profiles
  add column if not exists onboarding_completed boolean not null default false,
  add column if not exists is_active boolean not null default true,
  add column if not exists deleted_at timestamptz;

-- Backfill existing users as onboarded so current accounts route to Home.
update public.profiles
set onboarding_completed = true
where onboarding_completed is distinct from true;

notify pgrst, 'reload schema';
