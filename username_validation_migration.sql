-- SOCIETY - Username Validation Migration
-- This script updates existing usernames to meet the new validation rules
-- and adds the necessary constraints.
--
-- Run this in: Supabase Dashboard -> SQL Editor

-- Step 1: Clean existing usernames to only contain valid characters
-- Allowed: lowercase alphanumeric (a-z, 0-9), underscore (_), hyphen (-), period (.)
-- Must start and end with alphanumeric (lowercase letter or number)
update public.profiles
set username = case
  -- If username is null or empty, generate a random one
  when username is null or trim(username) = '' then 'user' || floor(random() * 900 + 100)::text
  
  -- Otherwise, clean it: convert to lowercase, remove invalid characters, ensure proper format
  else 
    case
      -- Clean: lowercase, remove invalid chars
      when regexp_replace(lower(username), '[^a-z0-9._-]', '', 'g') = '' then 'user' || floor(random() * 900 + 100)::text
      when length(regexp_replace(lower(username), '[^a-z0-9._-]', '', 'g')) < 3 then 
        regexp_replace(lower(username), '[^a-z0-9._-]', '', 'g') || floor(random() * 90 + 10)::text
      else 
        -- Ensure starts with alphanumeric
        case
          when regexp_replace(lower(username), '[^a-z0-9._-]', '', 'g') ~ '^[^a-z0-9]' then
            'u' || regexp_replace(lower(username), '[^a-z0-9._-]', '', 'g')
          else regexp_replace(lower(username), '[^a-z0-9._-]', '', 'g')
        end
    end
end
where username is not null;

-- Step 2: Ensure all usernames end with alphanumeric (fix trailing _, -, .)
update public.profiles
set username = regexp_replace(username, '[._-]+$', '', 'g') || 
  case 
    when length(regexp_replace(username, '[._-]+$', '', 'g')) >= 3 then ''
    else floor(random() * 90 + 10)::text
  end
where username is not null 
  and username ~ '[._-]$';

-- Step 3: Drop old constraints if they exist
alter table public.profiles
  drop constraint if exists profiles_username_min_length;
alter table public.profiles
  drop constraint if exists profiles_username_valid;

-- Step 4: Add unique constraint on username (if not already exists)
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_username_unique'
  ) then
    alter table public.profiles
      add constraint profiles_username_unique unique (username);
  end if;
end $$;

-- Step 5: Add new validation constraint
-- Lowercase only, min 3 chars, must start/end with alphanumeric
alter table public.profiles
  add constraint profiles_username_valid check (
    username is null or (
      length(trim(username)) >= 3
      and username ~ '^[a-z0-9][a-z0-9._-]*[a-z0-9]$'
      and username = lower(username)
    )
  );

-- Reload schema cache
notify pgrst, 'reload schema';
