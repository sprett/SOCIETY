import { useMemo, useState } from "react"
import * as PopoverPrimitive from "@radix-ui/react-popover"
import { format, parseISO } from "date-fns"
import { DayPicker } from "react-day-picker"
import { Calendar as CalendarIcon, X } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

import "react-day-picker/style.css"

function getToday() {
  const d = new Date()
  d.setHours(0, 0, 0, 0)
  return d
}

function toDate(value: string | null): Date | undefined {
  if (!value) return undefined
  try {
    const d = parseISO(value)
    return Number.isNaN(d.getTime()) ? undefined : d
  } catch {
    return undefined
  }
}

function toIsoDateString(value: Date): string {
  // YYYY-MM-DD for Postgres date.
  return format(value, "yyyy-MM-dd")
}

interface BirthdayPickerProps {
  value: string
  onChange: (value: string) => void
  disabled?: boolean
  className?: string
  /** When false, the clear (X) button is hidden so the user cannot remove the birthday. Default true. */
  showClearButton?: boolean
}

export function BirthdayPicker({ value, onChange, disabled, className, showClearButton = true }: BirthdayPickerProps) {
  const [open, setOpen] = useState(false)
  const today = useMemo(() => getToday(), [])
  const selected = useMemo(() => toDate(value) ?? undefined, [value])

  const label = selected ? format(selected, "MMM d, yyyy") : "Pick a date"

  return (
    <PopoverPrimitive.Root
      open={open}
      onOpenChange={(v) => !disabled && setOpen(v)}
      modal={false}
    >
      <div className={cn("flex w-full items-center gap-2", className)}>
        <PopoverPrimitive.Trigger asChild>
          <Button
            type="button"
            variant="outline"
            className={cn(
              "h-9 min-w-0 flex-1 justify-start gap-2 rounded-md border-border/60 bg-transparent px-3 text-sm font-normal",
              !selected && "text-muted-foreground"
            )}
            disabled={disabled}
          >
            <CalendarIcon className="h-4 w-4 shrink-0" />
            <span className="truncate">{label}</span>
          </Button>
        </PopoverPrimitive.Trigger>
        {showClearButton && selected && !disabled && (
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="h-9 w-9 shrink-0"
            title="Clear"
            onClick={() => onChange("")}
          >
            <X className="h-4 w-4" />
          </Button>
        )}
      </div>
      <PopoverPrimitive.Portal>
        <PopoverPrimitive.Content
          side="bottom"
          align="start"
          sideOffset={4}
          className={cn(
            "z-[100] w-auto rounded-xl border border-border/80 bg-card p-0 shadow-lg",
            "data-[state=open]:animate-in data-[state=closed]:animate-out",
            "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
            "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95"
          )}
          onOpenAutoFocus={(e) => e.preventDefault()}
        >
          <DayPicker
            mode="single"
            captionLayout="dropdown"
            fromYear={1900}
            toYear={today.getFullYear()}
            selected={selected}
            onSelect={(d) => {
              if (!d) return
              onChange(toIsoDateString(d))
              setOpen(false)
            }}
            defaultMonth={selected ?? today}
            disabled={{ after: today }}
            classNames={{
              root: "rdp p-3",
              month: "space-y-4",
              month_caption: "flex items-center justify-center gap-2 pt-1 text-sm font-medium",
              caption_label: "hidden",
              dropdowns: "flex items-center gap-2",
              dropdown_root: "relative",
              dropdown: "rounded-md border border-border bg-background px-2 py-1 text-sm",
              dropdown_month: "capitalize",
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
            }}
          />
        </PopoverPrimitive.Content>
      </PopoverPrimitive.Portal>
    </PopoverPrimitive.Root>
  )
}
