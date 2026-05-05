-- SOCIETY - Expo push token storage on profiles
--
-- Run in: Supabase Dashboard -> SQL Editor
--
-- Replaces the no-op push registration that existed in the Swift app
-- (UIApplication.shared.registerForRemoteNotifications was called but
-- the device token was never persisted). The React Native app registers
-- an Expo push token at launch and upserts it here so the backend can
-- send notifications via the Expo Push API.

alter table public.profiles
  add column if not exists expo_push_token text;

notify pgrst, 'reload schema';
