const STATUS_SUMMARY_URL = "https://status.supabase.com/api/v2/summary.json"
const TTL_MS = 60_000

type SupabaseIndicator = "none" | "minor" | "major" | "critical" | "unknown"
type SupabaseMappedStatus = "live" | "degraded" | "partial_outage" | "down" | "unknown"

type SupabaseStatusPayload = {
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

type StatusSummaryResponse = {
  status?: {
    indicator?: string
    description?: string
  }
  components?: Array<{
    id?: string
    name?: string
    status?: string
  }>
  incidents?: Array<{
    id?: string
    name?: string
    status?: string
    started_at?: string
    shortlink?: string
  }>
}

type CachedValue = {
  expiresAt: number
  payload: SupabaseStatusPayload
}

let cache: CachedValue | null = null

const FALLBACK_PAYLOAD: SupabaseStatusPayload = {
  ok: false,
  overall: { indicator: "unknown", description: "Status unavailable" },
  mappedStatus: "unknown",
  components: [],
  incidents: [],
}

function mapIndicatorToStatus(indicator: string): SupabaseMappedStatus {
  switch (indicator) {
    case "none":
      return "live"
    case "minor":
      return "degraded"
    case "major":
      return "partial_outage"
    case "critical":
      return "down"
    case "failure":
      return "unknown"
    default:
      return "unknown"
  }
}

function normalizePayload(summary: StatusSummaryResponse): SupabaseStatusPayload {
  const indicatorRaw = summary.status?.indicator
  const indicator: SupabaseIndicator =
    indicatorRaw === "none" ||
    indicatorRaw === "minor" ||
    indicatorRaw === "major" ||
    indicatorRaw === "critical"
      ? indicatorRaw
      : "unknown"

  let mappedStatus = mapIndicatorToStatus(indicatorRaw ?? "failure")
  const components = (summary.components ?? [])
    .filter((component) => component.id && component.name && component.status)
    .map((component) => ({
      id: component.id as string,
      name: component.name as string,
      status: component.status as string,
    }))

  const hasMajorOutage = components.some((component) => component.status === "major_outage")
  if (hasMajorOutage && (mappedStatus === "live" || mappedStatus === "degraded")) {
    mappedStatus = "partial_outage"
  }

  const incidents = (summary.incidents ?? [])
    .filter((incident) => incident.id && incident.name && incident.status && incident.started_at)
    .map((incident) => ({
      id: incident.id as string,
      name: incident.name as string,
      status: incident.status as string,
      started_at: incident.started_at as string,
      url: incident.shortlink,
    }))

  return {
    ok: true,
    overall: {
      indicator,
      description: summary.status?.description ?? "Status unavailable",
    },
    mappedStatus,
    components,
    incidents,
  }
}

function json(payload: SupabaseStatusPayload, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "public, max-age=0, s-maxage=60, stale-while-revalidate=120",
    },
  })
}

export default async function handler(_request: Request): Promise<Response> {
  const now = Date.now()
  if (cache && cache.expiresAt > now) {
    return json(cache.payload)
  }

  try {
    const response = await fetch(STATUS_SUMMARY_URL, {
      method: "GET",
      headers: { accept: "application/json" },
    })

    if (!response.ok) {
      return json(FALLBACK_PAYLOAD)
    }

    const summary = (await response.json()) as StatusSummaryResponse
    const payload = normalizePayload(summary)

    cache = {
      payload,
      expiresAt: now + TTL_MS,
    }

    return json(payload)
  } catch {
    return json(FALLBACK_PAYLOAD)
  }
}
