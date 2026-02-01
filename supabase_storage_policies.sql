-- SOCIETY - Storage RLS policies for profile-images bucket
--
-- Run this in: Supabase Dashboard -> SQL Editor
--
-- The app deletes the previous profile image when the user changes their photo.
-- Without a DELETE policy, storage.remove() fails (e.g. 403) and old files stay in the bucket.

create policy "Authenticated users can delete profile images"
on storage.objects
for delete
to authenticated
using (bucket_id = 'profile-images');
