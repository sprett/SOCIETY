import { useState, useEffect } from "react"
import { format, subDays, differenceInDays } from "date-fns"
import { DayPicker } from "react-day-picker"
import type { DateRange } from "react-day-picker"
import { Calendar as CalendarIcon } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Popover, PopoverContent } from "@/components/ui/popover"
import { cn } from "@/lib/utils"
import "react-day-picker/style.css"

function getToday() {
  const d = new Date()
  d.setHours(0, 0, 0, 0)
  return d
}

interface DateRangePickerProps {
  /** Number of days for the range (e.g. 30 = last 30 days) */
  periodDays: number
  /** Called when user selects a new range; pass the number of days */
  onRangeSelect: (days: number) => void
  /** Optional fixed preset label when not custom */
  presetLabel?: string
  className?: string
}

export function DateRangePicker({
  periodDays,
  onRangeSelect,
  presetLabel,
  className,
}: DateRangePickerProps) {
  const [open, setOpen] = useState(false)
  const today = getToday()
  const [range, setRange] = useState<DateRange>(() => ({
    from: subDays(today, periodDays),
    to: today,
  }))

  useEffect(() => {
    setRange({
      from: subDays(getToday(), periodDays),
      to: getToday(),
    })
  }, [periodDays])

  const handleSelect = (r: DateRange | undefined) => {
    if (!r?.from) return
    setRange(r)
    if (r.to) {
      const days = Math.max(1, differenceInDays(r.to, r.from) + 1)
      onRangeSelect(days)
      setOpen(false)
    }
  }

  const displayLabel = range?.from
    ? range.to
      ? `${format(range.from, "MMM d, yyyy")} - ${format(range.to, "MMM d, yyyy")}`
      : format(range.from, "MMM d, yyyy")
    : presetLabel ?? "Select dates"

  return (
    <Popover open={open} onOpenChange={setOpen} className={cn("flex", className)}>
      <Button
        variant="neutral"
        size="sm"
        type="button"
        className="h-9 rounded-l-full rounded-r-none border-0 bg-transparent shadow-none hover:bg-muted/40"
        onClick={() => setOpen(true)}
      >
        <CalendarIcon className="h-4 w-4 shrink-0" />
        <span className="hidden sm:inline">{displayLabel}</span>
      </Button>
      {open && (
      <PopoverContent className="left-0 w-auto p-0">
        <DayPicker
          mode="range"
          defaultMonth={range?.from ?? today}
          selected={range}
          onSelect={handleSelect}
          numberOfMonths={1}
          disabled={{ after: today }}
          classNames={{
            root: "rdp p-3",
            month: "space-y-4",
            month_caption: "flex justify-center pt-1 text-sm font-medium",
            nav: "flex gap-1",
            button_previous: "h-8 w-8 rounded-full hover:bg-muted",
            button_next: "h-8 w-8 rounded-full hover:bg-muted",
            weekdays: "flex",
            weekday: "w-9 rounded text-xs text-muted-foreground",
            week: "flex w-full mt-2",
            day: "h-9 w-9 rounded-full text-sm p-0 hover:bg-muted",
            day_button: "h-9 w-9 rounded-full",
            selected: "bg-primary text-primary-foreground hover:bg-primary/90",
            today: "font-semibold",
            outside: "text-muted-foreground opacity-50",
            range_start: "rounded-l-full bg-primary text-primary-foreground",
            range_end: "rounded-r-full bg-primary text-primary-foreground",
            range_middle: "rounded-none bg-primary/20",
          }}
        />
      </PopoverContent>
      )}
    </Popover>
  )
}
