"use client"

import * as React from "react"
import { ResponsiveContainer } from "recharts"
import { cn } from "@/lib/utils"

export type ChartConfig = Record<
  string,
  { label?: string; color?: string; icon?: React.ComponentType<{ className?: string }> }
>

const ChartContext = React.createContext<{ config: ChartConfig } | null>(null)

function useChart() {
  const context = React.useContext(ChartContext)
  if (!context) {
    throw new Error("useChart must be used within a ChartContainer")
  }
  return context
}

interface ChartContainerProps extends React.HTMLAttributes<HTMLDivElement> {
  config: ChartConfig
  children: React.ReactNode
}

function ChartContainer({ config, children, className, ...props }: ChartContainerProps) {
  return (
    <ChartContext.Provider value={{ config }}>
      <div
        className={cn("w-full", className)}
        style={{ minHeight: "200px" }}
        {...props}
      >
        <ResponsiveContainer width="100%" height="100%" minHeight={200}>
          {children}
        </ResponsiveContainer>
      </div>
    </ChartContext.Provider>
  )
}

interface ChartTooltipContentProps {
  active?: boolean
  payload?: readonly { name?: string; value?: number; dataKey?: string; color?: string; fill?: string }[]
  label?: string | number
  labelFormatter?: (label: string | number) => React.ReactNode
  valueFormatter?: (value: number) => string
  hideLabel?: boolean
  indicator?: "line" | "dot" | "dashed"
  className?: string
}

function ChartTooltipContent({
  active,
  payload,
  label,
  labelFormatter,
  valueFormatter = (v) => v.toLocaleString(),
  hideLabel,
  indicator = "dot",
  className,
}: ChartTooltipContentProps) {
  const { config } = useChart()
  if (!active || !payload?.length) return null

  const displayLabel =
    label != null
      ? labelFormatter
        ? labelFormatter(label)
        : String(label)
      : null

  return (
    <div
      className={cn(
        "border-border/50 bg-card text-card-foreground grid min-w-[8rem] items-start gap-1.5 rounded-lg border px-2.5 py-1.5 text-xs shadow-xl",
        className
      )}
    >
      {!hideLabel && displayLabel && (
        <div className="font-medium">{displayLabel}</div>
      )}
      <div className="grid gap-1.5">
        {payload.map((item, index) => {
          const key = item.dataKey != null ? String(item.dataKey) : ""
          const name = (item.name != null && String(item.name).trim() !== ""
            ? item.name
            : (key ? config[key]?.label : undefined) ?? (key || "Value")) as string
          const color = item.color ?? item.fill ?? (key ? config[key]?.color : undefined) ?? "var(--chart-1)"
          return (
            <div
              key={index}
              className={cn(
                "flex w-full items-stretch gap-2",
                indicator === "dot" && "items-center"
              )}
            >
              <div
                className={cn(
                  "shrink-0 rounded-[2px] border-[--color-border] bg-[--color-bg]",
                  indicator === "dot" && "h-2.5 w-2.5",
                  indicator === "line" && "w-1",
                  indicator === "dashed" && "w-0 border-[1.5px] border-dashed bg-transparent"
                )}
                style={
                  {
                    "--color-bg": color,
                    "--color-border": color,
                  } as React.CSSProperties
                }
              />
              <div className="flex flex-1 justify-between leading-none">
                <span className="text-muted-foreground">{String(name)}</span>
                <span className="font-mono font-medium tabular-nums">
                  {valueFormatter(Number(item.value ?? 0))}
                </span>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}

export {
  ChartContainer,
  ChartTooltipContent,
  useChart,
}
