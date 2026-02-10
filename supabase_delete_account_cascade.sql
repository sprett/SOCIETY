-- SOCIETY - Account deletion: cascade delete owned events
--
-- Run in: Supabase Dashboard -> SQL Editor
--
-- When a user is deleted from auth.users, their owned events are now deleted
-- (instead of setting owner_id to null). RSVPs and profile already CASCADE.
-- Profile image and event cover images are removed by the delete-account Edge Function
-- before the user is deleted.

-- Drop existing FK on owner_id (find by column and referenced table)
do $$
declare
  conname text;
begin
  select c.conname into conname
  from pg_constraint c
  join pg_attribute a on a.attnum = any(c.conkey) and a.attrelid = c.conrelid
  where c.conrelid = 'public.events'::regclass
    and c.contype = 'f'
    and a.attname = 'owner_id';
  if conname is not null then
    execute format('alter table public.events drop constraint %I', conname);
  end if;
end $$;

-- Re-add with CASCADE so deleting the user deletes their events
alter table public.events
  add constraint events_owner_id_fkey
  foreign key (owner_id) references auth.users(id) on delete cascade;

notify pgrst, 'reload schema';
