"use client"

import {
  Area,
  AreaChart,
  CartesianGrid,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  ChartContainer,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart"
import { Ticket, MoreHorizontal } from "lucide-react"
import { cn } from "@/lib/utils"

const chartConfig = {
  rsvps: {
    label: "RSVPs",
    color: "hsl(var(--chart-1))",
  },
  signups: {
    label: "Signups",
    color: "hsl(var(--chart-2))",
  },
  events: {
    label: "Events",
    color: "hsl(var(--chart-3))",
  },
} satisfies ChartConfig

interface TotalRsvpsChartProps {
  data: {
    date: string
    signups_count: number
    events_count: number
    rsvps_count?: number
  }[]
  rsvpsInPeriod: number
  rsvpsPrevPeriod: number
}

function percentChange(current: number, previous: number): number {
  if (previous === 0) return current > 0 ? 100 : 0
  return ((current - previous) / previous) * 100
}

export function TotalRsvpsChart({
  data,
  rsvpsInPeriod,
  rsvpsPrevPeriod,
}: TotalRsvpsChartProps) {
  const chartData = data.map((item) => ({
    ...item,
    dateFull: new Date(item.date).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
    }),
    rsvps_count: item.rsvps_count ?? 0,
  }))

  const trend = percentChange(rsvpsInPeriod, rsvpsPrevPeriod)
  const isPositive = trend >= 0

  const totalRsvps = chartData.reduce((sum, d) => sum + (d.rsvps_count ?? 0), 0)
  const totalSignups = chartData.reduce((sum, d) => sum + d.signups_count, 0)
  const totalEvents = chartData.reduce((sum, d) => sum + d.events_count, 0)
  const maxVal = Math.max(
    ...chartData.map((d) => d.rsvps_count ?? 0),
    ...chartData.map((d) => d.signups_count),
    ...chartData.map((d) => d.events_count),
    1
  )

  return (
    <Card className="col-span-4 lg:col-span-3 border-border/60 shadow-sm">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <div>
          <CardTitle className="text-base font-semibold flex items-center gap-2">
            <Ticket
              className="h-4 w-4"
              style={{ color: "hsl(var(--chart-1))" }}
              aria-hidden
            />
            Total RSVPs
          </CardTitle>
          <div className="flex items-center gap-2 mt-1">
            <span className="text-3xl font-bold">{rsvpsInPeriod.toLocaleString()}</span>
            <span
              className={cn(
                "text-xs font-medium px-1.5 py-0.5 rounded",
                isPositive
                  ? "text-emerald-600 bg-emerald-50 dark:bg-emerald-950/50 dark:text-emerald-400"
                  : "text-rose-600 bg-rose-50 dark:bg-rose-950/50 dark:text-rose-400"
              )}
            >
              {isPositive ? "+" : ""}
              {trend.toFixed(1)}% vs. last period
            </span>
          </div>
        </div>
        <button
          type="button"
          className="text-muted-foreground hover:text-foreground rounded p-1"
          aria-label="More options"
        >
          <MoreHorizontal className="h-5 w-5" />
        </button>
      </CardHeader>
      <CardContent className="pl-0">
        <ChartContainer config={chartConfig} className="h-[300px] w-full">
          <AreaChart
            data={chartData}
            margin={{ top: 10, right: 30, left: 0, bottom: 0 }}
          >
            <defs>
              <linearGradient id="fillRsvps" x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="5%"
                  stopColor="hsl(var(--chart-1))"
                  stopOpacity={0.3}
                />
                <stop
                  offset="95%"
                  stopColor="hsl(var(--chart-1))"
                  stopOpacity={0}
                />
              </linearGradient>
              <linearGradient id="fillSignups" x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="5%"
                  stopColor="hsl(var(--chart-2))"
                  stopOpacity={0.3}
                />
                <stop
                  offset="95%"
                  stopColor="hsl(var(--chart-2))"
                  stopOpacity={0}
                />
              </linearGradient>
              <linearGradient id="fillEvents" x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="5%"
                  stopColor="hsl(var(--chart-3))"
                  stopOpacity={0.3}
                />
                <stop
                  offset="95%"
                  stopColor="hsl(var(--chart-3))"
                  stopOpacity={0}
                />
              </linearGradient>
            </defs>
            <CartesianGrid
              strokeDasharray="3 3"
              vertical={false}
              className="stroke-border"
            />
            <XAxis
              dataKey="dateFull"
              tickLine={false}
              axisLine={false}
              tick={{ fontSize: 12 }}
              className="text-muted-foreground"
              minTickGap={30}
            />
            <YAxis
              tickLine={false}
              axisLine={false}
              tick={{ fontSize: 11 }}
              className="text-muted-foreground"
              tickFormatter={(v) => (v >= 1000 ? `${(v / 1000).toFixed(0)}k` : String(v))}
              domain={[0, maxVal * 1.1]}
            />
            <Tooltip
              content={({ active, payload, label }) => {
                const rawDate = payload?.[0]?.payload?.date as string | undefined
                return (
                  <ChartTooltipContent
                    active={active}
                    payload={payload}
                    label={rawDate ?? label}
                    labelFormatter={(value) => {
                      const d = typeof value === "string" && /^\d{4}-\d{2}-\d{2}/.test(value)
                        ? new Date(value + "Z")
                        : new Date(value)
                      return d.toLocaleDateString("en-US", {
                        month: "short",
                        day: "numeric",
                        year: "numeric",
                      })
                    }}
                  />
                )
              }}
              contentStyle={{
                borderRadius: "8px",
                border: "1px solid hsl(var(--border))",
                backgroundColor: "hsl(var(--card))",
                color: "hsl(var(--card-foreground))",
                boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)",
              }}
            />
            <Area
              type="monotone"
              dataKey="rsvps_count"
              name="RSVPs"
              stroke="hsl(var(--chart-1))"
              strokeWidth={2}
              fillOpacity={1}
              fill="url(#fillRsvps)"
            />
            <Area
              type="monotone"
              dataKey="signups_count"
              name="Signups"
              stroke="hsl(var(--chart-2))"
              strokeWidth={2}
              fillOpacity={1}
              fill="url(#fillSignups)"
            />
            <Area
              type="monotone"
              dataKey="events_count"
              name="Events"
              stroke="hsl(var(--chart-3))"
              strokeWidth={2}
              fillOpacity={1}
              fill="url(#fillEvents)"
            />
          </AreaChart>
        </ChartContainer>

        <div className="flex flex-wrap items-center gap-6 px-6 mt-4">
          <div className="flex items-center gap-2">
            <div
              className="w-3 h-3 rounded-full shrink-0"
              style={{ backgroundColor: "hsl(var(--chart-1))" }}
              aria-hidden
            />
            <div>
              <p className="text-xs text-muted-foreground">RSVPs</p>
              <p className="text-sm font-bold">{totalRsvps.toLocaleString()}</p>
              <div
                className="h-1 w-24 rounded-full mt-1 overflow-hidden bg-muted"
                aria-hidden
              >
                <div
                  className="h-full rounded-full"
                  style={{
                    width: `${maxVal ? (totalRsvps / (totalRsvps + totalSignups + totalEvents || 1)) * 100 : 0}%`,
                    backgroundColor: "hsl(var(--chart-1))",
                  }}
                />
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div
              className="w-3 h-3 rounded-full shrink-0"
              style={{ backgroundColor: "hsl(var(--chart-2))" }}
              aria-hidden
            />
            <div>
              <p className="text-xs text-muted-foreground">Signups</p>
              <p className="text-sm font-bold">{totalSignups.toLocaleString()}</p>
              <div
                className="h-1 w-24 rounded-full mt-1 overflow-hidden bg-muted"
                aria-hidden
              >
                <div
                  className="h-full rounded-full"
                  style={{
                    width: `${maxVal ? (totalSignups / (totalRsvps + totalSignups + totalEvents || 1)) * 100 : 0}%`,
                    backgroundColor: "hsl(var(--chart-2))",
                  }}
                />
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div
              className="w-3 h-3 rounded-full shrink-0"
              style={{ backgroundColor: "hsl(var(--chart-3))" }}
              aria-hidden
            />
            <div>
              <p className="text-xs text-muted-foreground">Events</p>
              <p className="text-sm font-bold">{totalEvents.toLocaleString()}</p>
              <div
                className="h-1 w-24 rounded-full mt-1 overflow-hidden bg-muted"
                aria-hidden
              >
                <div
                  className="h-full rounded-full"
                  style={{
                    width: `${maxVal ? (totalEvents / (totalRsvps + totalSignups + totalEvents || 1)) * 100 : 0}%`,
                    backgroundColor: "hsl(var(--chart-3))",
                  }}
                />
              </div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
