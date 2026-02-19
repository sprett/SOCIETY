export type SupabaseIndicator = "none" | "minor" | "major" | "critical" | "unknown"

export type SupabaseMappedStatus =
  | "live"
  | "degraded"
  | "partial_outage"
  | "down"
  | "unknown"

export type SupabaseStatusPayload = {
  ok: boolean
  overall: {
    indicator: SupabaseIndicator
    description: string
  }
  mappedStatus: SupabaseMappedStatus
  components: Array<{
    id: string
    name: string
    status: string
  }>
  incidents: Array<{
    id: string
    name: string
    status: string
    started_at: string
    url?: string
  }>
}

export const FALLBACK_SUPABASE_STATUS: SupabaseStatusPayload = {
  ok: false,
  overall: { indicator: "unknown", description: "Status unavailable" },
  mappedStatus: "unknown",
  components: [],
  incidents: [],
}
