-- SOCIETY - Storage buckets and RLS policies
--
-- Run this in: Supabase Dashboard -> SQL Editor
--
-- 1. Create the event-images bucket (if it doesn't exist)
--    In Dashboard: Storage -> New bucket -> Name: event-images, Public: ON
--    Or run the INSERT below if your project has storage.buckets:
--
-- insert into storage.buckets (id, name, public)
-- values ('event-images', 'event-images', true)
-- on conflict (id) do update set public = true;
--
-- 2. Then run the policies below.

-- ----- event-images (event cover photos) -----
-- Public read so event pages can show cover images without auth.
drop policy if exists "event-images public read" on storage.objects;
create policy "event-images public read"
on storage.objects for select
to public
using (bucket_id = 'event-images');

-- Authenticated users can upload when creating/editing events.
drop policy if exists "event-images authenticated upload" on storage.objects;
create policy "event-images authenticated upload"
on storage.objects for insert
to authenticated
with check (bucket_id = 'event-images');

-- Authenticated users can delete (change cover or delete event removes old image).
drop policy if exists "event-images authenticated delete" on storage.objects;
create policy "event-images authenticated delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'event-images');

-- ----- profile-images -----
-- The app deletes the previous profile image when the user changes their photo.
-- Without a DELETE policy, storage.remove() fails (e.g. 403) and old files stay in the bucket.
drop policy if exists "Authenticated users can delete profile images" on storage.objects;
create policy "Authenticated users can delete profile images"
on storage.objects
for delete
to authenticated
using (bucket_id = 'profile-images');
