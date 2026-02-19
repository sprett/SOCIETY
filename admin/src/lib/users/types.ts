export interface AdminUserRow {
  id: string
  full_name: string | null
  avatar_url: string | null
  created_at: string | null
  email: string | null
  phone_number: string | null
  events_attended: number | null
  events_hosted: number | null
  birthday: string | null
  last_login_at: string | null
  last_app_open_at: string | null
  last_seen_at: string | null
  username: string | null
  sign_in_provider: string | null
}

export interface AdminUserEventSummary {
  id: string
  title: string | null
  start_at: string | null
  category: string | null
  image_url: string | null
  venue_name: string | null
}

export interface AdminUserProfileData {
  profile: {
    id: string
    full_name: string | null
    username: string | null
    avatar_url: string | null
    birthday: string | null
    created_at: string | null
    last_login_at: string | null
    last_app_open_at: string | null
    last_seen_at: string | null
    email: string | null
    phone_number: string | null
    instagram_handle: string | null
    twitter_handle: string | null
    youtube_handle: string | null
    tiktok_handle: string | null
    linkedin_handle: string | null
    website_url: string | null
  }
  metrics: {
    app_opens_total: number
    app_opens_in_period: number
    hosted_total: number
    attended_past_total: number
    signed_up_upcoming_total: number
  }
  events: {
    hosted_recent: AdminUserEventSummary[]
    attended_past_recent: AdminUserEventSummary[]
    signed_up_upcoming_recent: AdminUserEventSummary[]
  }
  charts: {
    active_day: { day_index: number; day_name: string; count: number }[]
    categories: { category: string; count: number }[]
  }
}

export interface AdminUpdateUserProfileInput {
  user_id: string
  full_name: string | null
  username: string | null
  phone_number: string | null
  birthday: string | null
  avatar_url: string | null
  instagram_handle: string | null
  twitter_handle: string | null
  youtube_handle: string | null
  tiktok_handle: string | null
  linkedin_handle: string | null
  website_url: string | null
}
