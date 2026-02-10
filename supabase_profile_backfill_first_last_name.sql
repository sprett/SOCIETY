-- SOCIETY - Backfill first_name and last_name from full_name
--
-- Run once in: Supabase Dashboard -> SQL Editor
-- Use this so you can use first_name for email marketing (e.g. "Hey Dino!").
-- Only updates rows where first_name is currently null/empty.

update public.profiles
set
  first_name = trim(split_part(coalesce(full_name, ''), ' ', 1)),
  last_name = case
    when position(' ' in trim(coalesce(full_name, ''))) > 0
    then trim(substring(trim(full_name) from position(' ' in trim(full_name)) + 1))
    else null
  end
where full_name is not null
  and trim(full_name) <> ''
  and (first_name is null or trim(first_name) = '');
