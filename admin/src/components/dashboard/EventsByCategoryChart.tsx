import {
  Cell,
  Pie,
  PieChart,
  Tooltip,
} from "recharts"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ChartContainer, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart"
import { PieChart as PieChartIcon } from "lucide-react"

const CATEGORY_COLORS = [
  "hsl(var(--chart-1))",
  "hsl(var(--chart-2))",
  "hsl(var(--chart-3))",
  "hsl(var(--chart-4))",
  "hsl(var(--chart-5))",
  "#0ea5e9",
  "#8b5cf6",
  "#64748b",
]

const chartConfig = {
  value: {
    label: "Events",
    color: "hsl(var(--chart-1))",
  },
} satisfies ChartConfig

interface EventsByCategoryChartProps {
  data: { category: string; count: number }[]
}

export function EventsByCategoryChart({ data }: EventsByCategoryChartProps) {
  const total = data.reduce((sum, d) => sum + d.count, 0)

  const chartData = data.map((d, i) => ({
    name: d.category || "Uncategorized",
    value: d.count,
    fill: CATEGORY_COLORS[i % CATEGORY_COLORS.length],
  }))

  return (
    <Card className="col-span-4 lg:col-span-1 border-border/80 shadow-sm">
      <CardHeader className="pb-2">
        <CardTitle className="text-base font-semibold flex items-center gap-2">
          <PieChartIcon className="h-4 w-4 text-muted-foreground" aria-hidden />
          Events by category
        </CardTitle>
        <p className="text-xs text-muted-foreground">
          In selected period
          {total > 0 && (
            <span className="ml-1">
              · {total.toLocaleString()} total
            </span>
          )}
        </p>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="h-[200px] w-full">
          {chartData.length === 0 || total === 0 ? (
            <p className="flex h-full items-center justify-center text-sm text-muted-foreground">
              No events in period
            </p>
          ) : (
            <ChartContainer config={chartConfig} className="h-full w-full">
              <PieChart margin={{ top: 8, right: 8, left: 8, bottom: 8 }}>
                <Pie
                  data={chartData}
                  cx="50%"
                  cy="50%"
                  innerRadius={48}
                  outerRadius={72}
                  paddingAngle={2}
                  dataKey="value"
                  nameKey="name"
                >
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.fill} />
                  ))}
                </Pie>
                <Tooltip
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
              </PieChart>
            </ChartContainer>
          )}
        </div>
        {chartData.length > 0 && total > 0 && (
          <ul className="flex flex-wrap gap-x-4 gap-y-2 text-xs" role="list" aria-label="Events by category legend">
            {chartData.map((entry) => {
              const pct = ((entry.value / total) * 100).toFixed(0)
              return (
                <li key={entry.name} className="flex items-center gap-1.5">
                  <span
                    className="h-2 w-2 shrink-0 rounded-full"
                    style={{ backgroundColor: entry.fill }}
                    aria-hidden
                  />
                  <span className="text-muted-foreground">
                    {entry.name}: {entry.value.toLocaleString()} ({pct}%)
                  </span>
                </li>
              )
            })}
          </ul>
        )}
      </CardContent>
    </Card>
  )
}
