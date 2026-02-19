import { createClient } from "@supabase/supabase-js"

// Same env key names as the Xcode project (Info.plist: SUPABASE_URL, SUPABASE_ANON_KEY)
const supabaseUrl = import.meta.env.SUPABASE_URL
const supabaseAnonKey = import.meta.env.SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    "Missing SUPABASE_URL or SUPABASE_ANON_KEY. Copy admin/.env.example to admin/.env.local and use the same values as the iOS app (Info.plist)."
  )
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storage:
      typeof window !== "undefined" ? window.localStorage : undefined,
  },
})
