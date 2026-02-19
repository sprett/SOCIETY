import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ChartContainer, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart"
import { Smartphone } from "lucide-react"
import { cn } from "@/lib/utils"

const chartConfig = {
  count: {
    label: "App opens",
    color: "hsl(var(--primary))",
  },
} satisfies ChartConfig

interface ActiveDayChartProps {
  data: { day_index: number; day_name: string; count: number }[]
  className?: string
}

export function ActiveDayChart({ data, className }: ActiveDayChartProps) {
  const maxVal = data.length ? Math.max(...data.map((d) => d.count)) : 0
  const totalOpens = data.reduce((sum, d) => sum + d.count, 0)

  return (
    <Card className={cn("border-border/80 shadow-sm", className)}>
      <CardHeader className="pb-2">
        <CardTitle className="text-base font-semibold flex items-center gap-2">
          <Smartphone className="h-4 w-4 text-muted-foreground" aria-hidden />
          Most active day
        </CardTitle>
        <p className="text-xs text-muted-foreground">
          App opens by day of week
          {totalOpens > 0 && (
            <span className="ml-1">
              · {totalOpens.toLocaleString()} total in period
            </span>
          )}
        </p>
      </CardHeader>
      <CardContent>
        <div className="h-[250px] w-full">
          {data.length === 0 || totalOpens === 0 ? (
            <p className="flex h-full items-center justify-center text-sm text-muted-foreground">
              No app open data in period
            </p>
          ) : (
            <ChartContainer config={chartConfig} className="h-full w-full">
              <BarChart data={data} margin={{ top: 8, right: 8, left: 8, bottom: 8 }}>
                <CartesianGrid
                  strokeDasharray="3 3"
                  vertical={false}
                  className="stroke-border"
                />
                <XAxis
                  dataKey="day_name"
                  tickLine={false}
                  axisLine={false}
                  tick={{ fontSize: 12 }}
                  className="text-muted-foreground"
                />
                <YAxis
                  tickLine={false}
                  axisLine={false}
                  tick={{ fontSize: 11 }}
                  className="text-muted-foreground"
                  tickFormatter={(v) => v.toLocaleString()}
                />
                <Tooltip
                  cursor={{ fill: "hsl(var(--muted) / 0.3)" }}
                  content={({ active, payload, label }) => (
                    <ChartTooltipContent
                      active={active}
                      payload={payload}
                      label={label}
                    />
                  )}
                  contentStyle={{
                    borderRadius: "8px",
                    border: "1px solid hsl(var(--border))",
                    backgroundColor: "hsl(var(--card))",
                    color: "hsl(var(--card-foreground))",
                    boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)",
                  }}
                />
                <Bar dataKey="count" name="App opens" radius={[4, 4, 0, 0]} barSize={28}>
                  {data.map((entry, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={
                        entry.count === maxVal && maxVal > 0
                          ? "hsl(var(--primary))"
                          : "hsl(var(--muted))"
                      }
                    />
                  ))}
                </Bar>
              </BarChart>
            </ChartContainer>
          )}
        </div>
      </CardContent>
    </Card>
  )
}
