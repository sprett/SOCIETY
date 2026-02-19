-- SOCIETY - Re-signup chart fix: count same Apple ID again after account delete as new signup
--
-- Run after: supabase_admin_schema.sql (profiles.created_at must exist)
--
-- When a user is deleted and signs up again with the same Apple ID, Supabase Auth may reuse
-- the same identity and trigger handle_new_user() with ON CONFLICT DO UPDATE (profile row
-- recreated by app or auth). Previously created_at was left unchanged, so the dashboard
-- signup chart did not show the new signup. We now set created_at = now() on conflict
-- so re-signups are counted on the current day.

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
    updated_at = now(),
    created_at = now();
  return new;
end;
$$ language plpgsql security definer;
