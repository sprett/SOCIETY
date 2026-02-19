import { useEffect, useState } from "react"
import { supabase } from "@/lib/supabase"
import { usePeriod, type PeriodKey } from "@/contexts/PeriodContext"
import { useRefresh } from "@/contexts/RefreshContext"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Download } from "lucide-react"
import { cn } from "@/lib/utils"
import { StatsCards } from "@/components/dashboard/StatsCards"
import { TotalRsvpsChart } from "@/components/dashboard/TotalRsvpsChart"
import { ActiveDayChart } from "@/components/dashboard/ActiveDayChart"
import { EventsByCategoryChart } from "@/components/dashboard/EventsByCategoryChart"
import { TopProducts } from "@/components/dashboard/TopProducts"
import { DateRangePicker } from "@/components/dashboard/DateRangePicker"

interface DashboardStats {
  signups_in_period: number
  signups_prev_period: number
  events_in_period: number
  events_prev_period: number
  rsvps_in_period?: number
  rsvps_prev_period?: number
  users_online: number
  period_days: number
}

interface DashboardData {
  stats: DashboardStats
  time_series: {
    date: string
    signups_count: number
    events_count: number
    rsvps_count?: number
  }[]
  events_by_category: { category: string; count: number }[]
  app_opens_by_dow?: { day_index: number; day_name: string; count: number }[]
}

interface RecentEvent {
  id: string
  title: string
  category: string
  start_at: string
  venue_name: string
  created_at: string
}

async function fetchDashboard(periodDays: number): Promise<{ dashboard: DashboardData; recentEvents: RecentEvent[] } | null> {
  const dashboardPromise = supabase.rpc("get_admin_dashboard", {
    period_days: String(periodDays),
  })
  
  const eventsPromise = supabase
    .from("events")
    .select("id, title, category, start_at, venue_name, created_at")
    .order("created_at", { ascending: false })
    .limit(5)

  const [dashboardRes, eventsRes] = await Promise.all([dashboardPromise, eventsPromise])

  if (dashboardRes.error) throw new Error(dashboardRes.error.message)
  if (eventsRes.error) throw new Error(eventsRes.error.message)

  return {
    dashboard: dashboardRes.data as DashboardData,
    recentEvents: eventsRes.data as RecentEvent[]
  }
}

export function DashboardPage() {
  const { period, periodDays, setPeriod, setCustomDays } = usePeriod()
  const { refreshTrigger } = useRefresh()
  const [data, setData] = useState<{ dashboard: DashboardData; recentEvents: RecentEvent[] } | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    setLoading(true)
    setError(null)
    fetchDashboard(periodDays)
      .then((result) => {
        setData(result)
      })
      .catch((err: Error) => {
        setError(err.message)
      })
      .finally(() => setLoading(false))
  }, [periodDays, refreshTrigger])

  if (loading && !data) {
     // Skeleton or loading state matching the new design roughly
    return (
      <div className="flex items-center justify-center p-12">
        <p className="text-muted-foreground animate-pulse">Loading dashboard...</p>
      </div>
    )
  }

  if (error) {
    return (
      <Card className="rounded-card shadow-soft">
        <CardContent className="p-6">
          <p className="text-destructive" role="alert">
            Failed to load dashboard: {error}
          </p>
        </CardContent>
      </Card>
    )
  }

  if (!data) {
    return (
      <div className="rounded-card border bg-card p-12 shadow-soft">
        <p className="text-muted-foreground">No data available.</p>
      </div>
    )
  }

  const { dashboard, recentEvents } = data

  const appOpensInPeriod = (dashboard.app_opens_by_dow || []).reduce((sum, d) => sum + d.count, 0)

  return (
    <div className="space-y-6">
      {/* Dashboard Top Controls */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <h1 className="text-2xl font-bold tracking-tight text-foreground">Dashboard</h1>

        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center rounded-full border border-border/80 bg-card shadow-sm">
            <DateRangePicker
              periodDays={periodDays}
              onRangeSelect={(days) => setCustomDays(days)}
            />
            <div className="h-5 w-5 shrink-0 border-l border-border/80" aria-hidden />
            <select
              value={period}
              onChange={(e) => setPeriod(e.target.value as PeriodKey)}
              className={cn(
                "h-9 rounded-r-full rounded-l-none border-0 bg-transparent pl-3 pr-8 text-sm font-medium text-foreground focus:bg-muted/30 focus:outline-none focus:ring-0",
                "appearance-none"
              )}
              style={{ backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`, backgroundPosition: `right 0.5rem center`, backgroundRepeat: `no-repeat`, backgroundSize: `1.5em 1.5em` }}
            >
              <option value="7">Last 7 days</option>
              <option value="30">Last 30 days</option>
              <option value="90">Last 90 days</option>
              <option value="365">Last year</option>
            </select>
          </div>

          <Button size="sm" className="h-9 bg-primary text-primary-foreground shadow-sm hover:bg-primary/90">
            <Download className="h-4 w-4" />
            Export
          </Button>
        </div>
      </div>

      <StatsCards stats={dashboard.stats} appOpensInPeriod={appOpensInPeriod} />

      <div className="grid grid-cols-4 gap-6">
        <TotalRsvpsChart
          data={dashboard.time_series}
          rsvpsInPeriod={dashboard.stats.rsvps_in_period ?? 0}
          rsvpsPrevPeriod={dashboard.stats.rsvps_prev_period ?? 0}
        />
        <EventsByCategoryChart data={dashboard.events_by_category} />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <TopProducts data={recentEvents} />
        <ActiveDayChart data={dashboard.app_opens_by_dow || []} className="col-span-4 md:col-span-2" />
      </div>
    </div>
  )
}
