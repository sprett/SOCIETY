-- SOCIETY - Auto-generate usernames from full name
--
-- Run in: Supabase Dashboard -> SQL Editor (after supabase_admin_activity.sql or supabase_admin_users_username_provider.sql,
-- so that public.profiles has a username column).
--
-- Username format: firstname + first letter of last name (e.g. Dino Hukanovic → dinoh).
-- On collision: add next letter of last name (dinohu, dinohuk, …), then numbers (dinohukanovic1, …).

-- 1. Ensure username column exists
alter table public.profiles add column if not exists username text;

-- 2. Function: generate unique username from full_name (exclude_id = current profile so we don't self-collide)
create or replace function public.generate_username_from_full_name(
  full_name text,
  exclude_id uuid default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  first_part text;
  last_part text;
  first_clean text;
  last_clean text;
  base text;
  candidate text;
  last_len int;
  i int;
  n bigint;
begin
  if full_name is null or trim(full_name) = '' then
    return null;
  end if;

  -- Split: first word vs rest (last name)
  first_part := split_part(trim(full_name), ' ', 1);
  last_part := trim(substring(trim(full_name) from length(first_part) + 1));
  first_clean := lower(regexp_replace(first_part, '[^a-zA-Z]', '', 'g'));
  last_clean := lower(regexp_replace(last_part, '[^a-zA-Z]', '', 'g'));

  if first_clean = '' then
    first_clean := 'user';
  end if;

  -- base = first + first letter of last (or just first if no last name)
  base := first_clean || coalesce(left(last_clean, 1), '');
  last_len := length(last_clean);

  -- Try: base, then base + 2nd letter, + 3rd, … up to full last name
  for i in 1..greatest(last_len, 1) loop
    candidate := first_clean || substr(last_clean, 1, i);
    if not exists (
      select 1 from public.profiles
      where username = candidate and (exclude_id is null or id != exclude_id)
    ) then
      return candidate;
    end if;
  end loop;

  -- Out of letters: append numbers (full first+last then 1, 2, …)
  n := 1;
  loop
    candidate := first_clean || coalesce(last_clean, '') || n::text;
    if not exists (
      select 1 from public.profiles
      where username = candidate and (exclude_id is null or id != exclude_id)
    ) then
      return candidate;
    end if;
    n := n + 1;
  end loop;
end;
$$;

comment on function public.generate_username_from_full_name(text, uuid) is 'Generates a unique username from full name: firstname + initial(s) of last name, then numbers on collision.';

-- 3. Trigger: set username on INSERT/UPDATE when full_name is set
create or replace function public.set_profile_username_from_full_name()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.full_name is not null and trim(new.full_name) <> '' then
    if tg_op = 'INSERT' then
      new.username := public.generate_username_from_full_name(new.full_name, new.id);
    elsif tg_op = 'UPDATE' and (old.full_name is distinct from new.full_name) then
      new.username := public.generate_username_from_full_name(new.full_name, new.id);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists set_username_from_full_name on public.profiles;
create trigger set_username_from_full_name
  before insert or update of full_name on public.profiles
  for each row
  execute function public.set_profile_username_from_full_name();

comment on trigger set_username_from_full_name on public.profiles is 'Auto-sets username from full_name (firstname + initial of last name, unique with more letters or numbers).';

-- 4. Unique constraint so two profiles cannot have the same username
drop index if exists public.profiles_username_key;
create unique index profiles_username_key on public.profiles (username)
  where username is not null;

-- 5. Backfill existing profiles (one row at a time so collision checks see previous assignments)
do $$
declare
  r record;
begin
  for r in
    select id, full_name from public.profiles
    where (username is null or trim(username) = '')
      and full_name is not null
      and trim(full_name) <> ''
    order by id
  loop
    update public.profiles
    set username = public.generate_username_from_full_name(r.full_name, r.id)
    where profiles.id = r.id;
  end loop;
end $$;
