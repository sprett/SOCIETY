import { useCallback, useEffect, useMemo, useState } from "react"
import { ExternalLink } from "lucide-react"
import { buttonVariants } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip"
import { cn } from "@/lib/utils"
import {
  FALLBACK_SUPABASE_STATUS,
  type SupabaseMappedStatus,
  type SupabaseStatusPayload,
} from "@/types/supabase-status"

const STATUS_LABEL: Record<SupabaseMappedStatus, string> = {
  live: "Live",
  degraded: "Degraded",
  partial_outage: "Partial Outage",
  down: "Down",
  unknown: "Unknown",
}

const STATUS_CLASSES: Record<SupabaseMappedStatus, string> = {
  live: "border-emerald-500/30 bg-emerald-500/10 text-emerald-600 dark:text-emerald-400",
  degraded: "border-yellow-500/30 bg-yellow-500/10 text-yellow-700 dark:text-yellow-400",
  partial_outage: "border-orange-500/30 bg-orange-500/10 text-orange-700 dark:text-orange-400",
  down: "border-red-500/30 bg-red-500/10 text-red-600 dark:text-red-400",
  unknown: "border-slate-500/30 bg-slate-500/10 text-slate-600 dark:text-slate-400",
}

const DOT_CLASSES: Record<SupabaseMappedStatus, string> = {
  live: "bg-emerald-500",
  degraded: "bg-yellow-500",
  partial_outage: "bg-orange-500",
  down: "bg-red-500",
  unknown: "bg-slate-500",
}

function sortIncidents(incidents: SupabaseStatusPayload["incidents"]) {
  return [...incidents].sort((a, b) => {
    const aUnresolved = a.status !== "resolved"
    const bUnresolved = b.status !== "resolved"
    if (aUnresolved !== bUnresolved) return aUnresolved ? -1 : 1
    return Date.parse(b.started_at) - Date.parse(a.started_at)
  })
}

function sortComponents(components: SupabaseStatusPayload["components"]) {
  return [...components].sort((a, b) => {
    const aImpacted = a.status !== "operational"
    const bImpacted = b.status !== "operational"
    if (aImpacted !== bImpacted) return aImpacted ? -1 : 1
    return a.name.localeCompare(b.name)
  })
}

function formatStatus(status: string) {
  return status.replaceAll("_", " ").replace(/\b\w/g, (char) => char.toUpperCase())
}

export function SupabaseStatusIndicator({ refreshNonce = 0 }: { refreshNonce?: number }) {
  const [status, setStatus] = useState<SupabaseStatusPayload>(FALLBACK_SUPABASE_STATUS)

  const fetchStatus = useCallback(async () => {
    try {
      const response = await fetch("/api/supabase-status", { method: "GET" })
      if (!response.ok) {
        setStatus(FALLBACK_SUPABASE_STATUS)
        return
      }
      const payload = (await response.json()) as SupabaseStatusPayload
      setStatus(payload)
    } catch {
      setStatus(FALLBACK_SUPABASE_STATUS)
    }
  }, [])

  useEffect(() => {
    fetchStatus()
  }, [fetchStatus, refreshNonce])

  useEffect(() => {
    const timer = window.setInterval(() => {
      void fetchStatus()
    }, 60_000)

    return () => window.clearInterval(timer)
  }, [fetchStatus])

  const impactedComponents = useMemo(
    () => status.components.filter((component) => component.status !== "operational"),
    [status.components]
  )

  const incidents = useMemo(() => sortIncidents(status.incidents), [status.incidents])
  const latestIncident = incidents[0]
  const sortedComponents = useMemo(
    () => sortComponents(status.components),
    [status.components]
  )
  const label = STATUS_LABEL[status.mappedStatus]

  return (
    <Dialog>
      <TooltipProvider delayDuration={100}>
        <Tooltip>
          <TooltipTrigger asChild>
            <DialogTrigger asChild>
              <button
                type="button"
                className={cn(
                  "flex items-center gap-1.5 rounded-md border px-2.5 py-1.5 text-xs font-medium",
                  STATUS_CLASSES[status.mappedStatus]
                )}
                aria-label={`Supabase status: ${label}. Click for details.`}
              >
                <span className={cn("size-2 rounded-full", DOT_CLASSES[status.mappedStatus])} />
                {label}
              </button>
            </DialogTrigger>
          </TooltipTrigger>
          <TooltipContent sideOffset={8} className="max-w-xs space-y-1.5 bg-popover text-popover-foreground">
            <p className="font-medium">Supabase: {label}</p>
            <p>{status.overall.description}</p>
            <p>Impacted components: {impactedComponents.length}</p>
            <p>Latest incident: {latestIncident ? latestIncident.name : "None"}</p>
            <p className="text-muted-foreground">Click for details</p>
          </TooltipContent>
        </Tooltip>
      </TooltipProvider>

      <DialogContent className="w-[calc(100vw-2rem)] max-w-2xl overflow-hidden p-0 sm:max-h-[85vh]" showCloseButton>
        <DialogHeader className="border-b px-6 pb-4 pt-6">
          <DialogTitle>Supabase Status</DialogTitle>
          <DialogDescription>
            {label}: {status.overall.description}
          </DialogDescription>
        </DialogHeader>

        <div className="max-h-[calc(85vh-8rem)] space-y-6 overflow-y-auto px-6 pb-6">
          <section className="space-y-3">
            <h3 className="text-sm font-semibold">Impacted components</h3>
            <div className="space-y-2">
              {sortedComponents.length === 0 && (
                <p className="text-sm text-muted-foreground">No component data available.</p>
              )}
              {sortedComponents.map((component) => (
                <div
                  key={component.id}
                  className="flex items-center justify-between rounded-md border px-3 py-2"
                >
                  <span className="text-sm">{component.name}</span>
                  <span
                    className={cn(
                      "rounded-full border px-2 py-0.5 text-xs",
                      component.status === "operational"
                        ? "border-emerald-500/30 bg-emerald-500/10 text-emerald-700 dark:text-emerald-400"
                        : "border-orange-500/30 bg-orange-500/10 text-orange-700 dark:text-orange-400"
                    )}
                  >
                    {formatStatus(component.status)}
                  </span>
                </div>
              ))}
            </div>
          </section>

          <section className="space-y-3">
            <h3 className="text-sm font-semibold">Incidents</h3>
            <div className="space-y-2">
              {incidents.length === 0 && (
                <p className="text-sm text-muted-foreground">No incidents reported.</p>
              )}
              {incidents.map((incident) => (
                <div key={incident.id} className="rounded-md border px-3 py-2">
                  <div className="flex items-start justify-between gap-4">
                    <div className="space-y-0.5">
                      <p className="text-sm font-medium">{incident.name}</p>
                      <p className="text-xs text-muted-foreground">
                        {new Date(incident.started_at).toLocaleString()}
                      </p>
                    </div>
                    {incident.url && (
                      <a
                        href={incident.url}
                        target="_blank"
                        rel="noreferrer"
                        className={buttonVariants({ variant: "outline", size: "sm" })}
                      >
                        View incident
                      </a>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </section>

          <div className="pt-1">
            <a
              href="https://status.supabase.com/"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline"
            >
              Open status page
              <ExternalLink className="size-3.5" />
            </a>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
