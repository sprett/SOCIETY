import path from "path"
import type { IncomingMessage, ServerResponse } from "node:http"
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

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

const FALLBACK_PAYLOAD: SupabaseStatusPayload = {
  ok: false,
  overall: { indicator: "unknown", description: "Status unavailable" },
  mappedStatus: "unknown",
  components: [],
  incidents: [],
}

let cache: CachedValue | null = null

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

async function getSupabaseStatusPayload(): Promise<SupabaseStatusPayload> {
  const now = Date.now()
  if (cache && cache.expiresAt > now) {
    return cache.payload
  }

  try {
    const response = await fetch(STATUS_SUMMARY_URL, {
      method: "GET",
      headers: { accept: "application/json" },
    })

    if (!response.ok) {
      return FALLBACK_PAYLOAD
    }

    const summary = (await response.json()) as StatusSummaryResponse
    const payload = normalizePayload(summary)

    cache = {
      payload,
      expiresAt: now + TTL_MS,
    }

    return payload
  } catch {
    return FALLBACK_PAYLOAD
  }
}

function sendJson(res: ServerResponse<IncomingMessage>, payload: SupabaseStatusPayload) {
  res.statusCode = 200
  res.setHeader("Content-Type", "application/json; charset=utf-8")
  res.setHeader("Cache-Control", "public, max-age=0, s-maxage=60, stale-while-revalidate=120")
  res.end(JSON.stringify(payload))
}

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {
    plugins: [
      react(),
      {
        name: "supabase-status-api-dev-route",
        configureServer(server) {
          server.middlewares.use("/api/supabase-status", async (req, res) => {
            if (req.method !== "GET") {
              res.statusCode = 405
              res.end("Method Not Allowed")
              return
            }

            const payload = await getSupabaseStatusPayload()
            sendJson(res, payload)
          })
        },
      },
    ],
    server: {
      port: 3000,
      allowedHosts: true, // allow ngrok and other tunnel hosts in dev
    },
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "./src"),
      },
    },
    define: {
      'import.meta.env.SUPABASE_URL': JSON.stringify(env.SUPABASE_URL ?? ''),
      'import.meta.env.SUPABASE_ANON_KEY': JSON.stringify(env.SUPABASE_ANON_KEY ?? ''),
    },
  }
})
