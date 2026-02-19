import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Calendar, Smartphone, UserCheck, UserPlus } from "lucide-react"
import { cn } from "@/lib/utils"

interface StatCardProps {
  title: string
  value: string
  trend: number | null
  trendLabel?: string
  icon: React.ElementType
  iconColor: string
}

function StatCard({ title, value, trend, trendLabel, icon: Icon, iconColor }: StatCardProps) {
  const isPositive = trend != null && trend >= 0

  return (
    <Card className="border-border/60 shadow-sm hover:shadow-md transition-shadow">
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {title}
        </CardTitle>
        <Icon className={cn("h-4 w-4", iconColor)} />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value}</div>
        {trend != null && (
          <div className="mt-1 flex items-center text-xs text-muted-foreground">
            <span
              className={cn(
                "flex items-center gap-0.5 font-medium px-1.5 py-0.5 rounded mr-2",
                isPositive ? "text-emerald-600 bg-emerald-50" : "text-rose-600 bg-rose-50"
              )}
            >
              {isPositive ? "+" : ""}
              {trend.toFixed(1)}%
            </span>
            <span>{trendLabel ?? "vs. last period"}</span>
          </div>
        )}
        {trend == null && trendLabel && (
          <p className="mt-1 text-xs text-muted-foreground">{trendLabel}</p>
        )}
      </CardContent>
    </Card>
  )
}

interface DashboardStatsProps {
  stats: {
    signups_in_period: number
    signups_prev_period: number
    users_online: number
    events_in_period: number
    events_prev_period: number
  }
  appOpensInPeriod?: number
}

function percentChange(current: number, previous: number): number {
  if (previous === 0) return current > 0 ? 100 : 0
  return ((current - previous) / previous) * 100
}

export function StatsCards({ stats, appOpensInPeriod = 0 }: DashboardStatsProps) {
  const signupsChange = percentChange(stats.signups_in_period, stats.signups_prev_period)
  const eventsChange = percentChange(stats.events_in_period, stats.events_prev_period)

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title="Total signups"
        value={stats.signups_in_period.toLocaleString()}
        trend={signupsChange}
        trendLabel="vs. last period"
        icon={UserPlus}
        iconColor="text-blue-500"
      />
      <StatCard
        title="Events hosted"
        value={stats.events_in_period.toLocaleString()}
        trend={eventsChange}
        trendLabel="vs. last period"
        icon={Calendar}
        iconColor="text-indigo-500"
      />
      <StatCard
        title="Users online"
        value={stats.users_online.toLocaleString()}
        trend={null}
        trendLabel="Last 1 min"
        icon={UserCheck}
        iconColor="text-emerald-500"
      />
      <StatCard
        title="App opens"
        value={appOpensInPeriod.toLocaleString()}
        trend={null}
        trendLabel="In period"
        icon={Smartphone}
        iconColor="text-blue-400"
      />
    </div>
  )
}
