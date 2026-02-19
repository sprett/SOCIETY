import { supabase } from "@/lib/supabase"
import type {
  AdminUpdateUserProfileInput,
  AdminUserProfileData,
} from "@/lib/users/types"

const PERIOD_OPTIONS = new Set(["7", "30", "90", "365"])

function assertPeriod(value: string): string {
  return PERIOD_OPTIONS.has(value) ? value : "90"
}

async function extractEdgeFunctionErrorMessage(error: unknown): Promise<string> {
  if (!(error instanceof Error)) return "Edge Function call failed"

  const anyErr = error as unknown as {
    message?: unknown
    context?: unknown
    details?: unknown
  }

  if (typeof anyErr.details === "string" && anyErr.details.trim().length > 0) {
    return anyErr.details
  }

  const ctx = anyErr.context as unknown
  const response =
    ctx instanceof Response
      ? ctx
      : (ctx as { response?: unknown } | null)?.response instanceof Response
        ? (ctx as { response: Response }).response
        : null

  if (response) {
    try {
      const json = (await response.clone().json()) as unknown
      if (json && typeof json === "object") {
        const obj = json as { error?: unknown; message?: unknown }
        if (typeof obj.error === "string" && obj.error.trim().length > 0) return obj.error
        if (typeof obj.message === "string" && obj.message.trim().length > 0) return obj.message
      }
    } catch {
      // Ignore JSON parse failures.
    }

    try {
      const text = (await response.clone().text()).trim()
      if (text) return text
    } catch {
      // Ignore read failures.
    }
  }

  if (typeof anyErr.message === "string" && anyErr.message.trim().length > 0) {
    return anyErr.message
  }

  return "Edge Function call failed"
}

export async function getAdminUserProfile(username: string, periodDays: string) {
  const { data, error } = await supabase.rpc("get_admin_user_profile", {
    p_username: username,
    p_period_days: assertPeriod(periodDays),
  })
  if (error) {
    throw new Error(error.message)
  }
  if (!data) return null
  return data as AdminUserProfileData
}

export async function adminUpdateUserProfile(input: AdminUpdateUserProfileInput) {
  const { data, error } = await supabase.rpc("admin_update_user_profile", {
    p_user_id: input.user_id,
    p_full_name: input.full_name,
    p_username: input.username,
    p_phone_number: input.phone_number,
    p_birthday: input.birthday,
    p_avatar_url: input.avatar_url,
    p_instagram_handle: input.instagram_handle,
    p_twitter_handle: input.twitter_handle,
    p_youtube_handle: input.youtube_handle,
    p_tiktok_handle: input.tiktok_handle,
    p_linkedin_handle: input.linkedin_handle,
    p_website_url: input.website_url,
  })
  if (error) {
    throw new Error(error.message)
  }
  const payload = data as {
    success: boolean
    error?: string
    profile: { username: string | null } | null
  }
  if (!payload?.success) {
    throw new Error(payload?.error ?? "Failed to update profile")
  }
  return payload
}

export async function adminDeleteUser(targetUserId: string, expectedUsername: string) {
  const {
    data: { session },
    error: sessionError,
  } = await supabase.auth.getSession()
  if (sessionError || !session?.access_token) {
    throw new Error("unauthorized")
  }

  // Sanity check: if the current session JWT is invalid, functions will always fail with 401.
  const {
    data: { user: currentUser },
    error: userError,
  } = await supabase.auth.getUser()
  if (userError || !currentUser?.id) {
    throw new Error(userError?.message ?? "unauthorized")
  }

  const { data, error } = await supabase.functions.invoke("admin-delete-user", {
    headers: {
      Authorization: `Bearer ${session.access_token}`,
    },
    body: {
      targetUserId,
      expectedUsername,
    },
  })
  if (error) {
    throw new Error(await extractEdgeFunctionErrorMessage(error))
  }
  return data as { success: boolean; error?: string }
}
