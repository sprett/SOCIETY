export type ProfileRole = "user" | "admin";
export type AvatarSource = "dicebear" | "upload";

export interface UserProfile {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
  first_name: string | null;
  last_name: string | null;
  bio: string | null;
  username: string | null;
  phone_number: string | null;
  instagram_handle: string | null;
  twitter_handle: string | null;
  youtube_handle: string | null;
  tiktok_handle: string | null;
  linkedin_handle: string | null;
  website_url: string | null;
  birthday: string | null;
  avatar_source: AvatarSource | null;
  avatar_seed: string | null;
  avatar_style: string | null;
  onboarding_completed: boolean;
  is_active: boolean;
  deleted_at: string | null;
  last_seen_at: string | null;
  last_app_open_at: string | null;
  expo_push_token: string | null;
  role: ProfileRole;
  created_at: string;
  updated_at: string;
}
