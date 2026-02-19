import { useMemo, useState } from "react"
import * as PopoverPrimitive from "@radix-ui/react-popover"
import { Check, ChevronDown, Search } from "lucide-react"

import { Input } from "@/components/ui/input"
import { cn } from "@/lib/utils"
import type { CountryPhoneCode } from "@/lib/phone/countryPhoneCodes"
import { COUNTRY_PHONE_CODES } from "@/lib/phone/countryPhoneCodes"

function flagEmojiFromIso2(iso2: string): string {
  const s = (iso2 ?? "").trim().toUpperCase()
  if (s.length !== 2) return ""
  const a = 127397
  return String.fromCodePoint(a + s.charCodeAt(0), a + s.charCodeAt(1))
}

interface CountryCodeSelectProps {
  value: CountryPhoneCode
  onChange: (value: CountryPhoneCode) => void
  disabled?: boolean
  className?: string
  compact?: boolean
}

export function CountryCodeSelect({
  value,
  onChange,
  disabled,
  className,
  compact,
}: CountryCodeSelectProps) {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState("")

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return COUNTRY_PHONE_CODES
    return COUNTRY_PHONE_CODES.filter((c) => {
      return (
        c.name.toLowerCase().includes(q) ||
        c.id.toLowerCase().includes(q) ||
        c.dialingCode.includes(q)
      )
    })
  }, [query])

  return (
    <PopoverPrimitive.Root
      open={open}
      onOpenChange={(v) => {
        if (disabled) return
        setOpen(v)
        if (!v) setQuery("")
      }}
      modal={false}
    >
      <PopoverPrimitive.Trigger asChild>
        <button
          type="button"
          disabled={disabled}
          className={cn(
            "h-9 w-full rounded-md border border-border/60 bg-muted/10 px-3 text-left text-sm",
            "flex items-center justify-between gap-2",
            "hover:bg-muted/30 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
            "disabled:cursor-not-allowed disabled:opacity-50",
            className
          )}
        >
          <span className="flex min-w-0 items-center gap-2">
            <span className="shrink-0" aria-hidden>
              {flagEmojiFromIso2(value.id)}
            </span>
            <span className="shrink-0 font-medium">{value.dialingCode}</span>
            {!compact && (
              <span className="min-w-0 truncate text-muted-foreground">{value.name}</span>
            )}
          </span>
          <ChevronDown className="h-4 w-4 shrink-0 text-muted-foreground" />
        </button>
      </PopoverPrimitive.Trigger>
      <PopoverPrimitive.Portal>
        <PopoverPrimitive.Content
          side="bottom"
          align="start"
          sideOffset={4}
          className={cn(
            "z-[100] w-[22rem] rounded-xl border border-border/80 bg-card p-2 shadow-lg",
            "data-[state=open]:animate-in data-[state=closed]:animate-out",
            "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
            "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95"
          )}
          onOpenAutoFocus={(e) => e.preventDefault()}
        >
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search country or code..."
              className="h-9 pl-9"
              onKeyDown={(e) => e.stopPropagation()}
            />
          </div>

          <div className="mt-2 max-h-64 overflow-auto rounded-md border border-border/60">
            {filtered.length === 0 ? (
              <p className="p-3 text-sm text-muted-foreground">No matches.</p>
            ) : (
              <ul className="divide-y divide-border/60" role="listbox" aria-label="Country code">
                {filtered.map((c) => {
                  const selected = c.id === value.id && c.dialingCode === value.dialingCode
                  return (
                    <li key={`${c.id}-${c.dialingCode}`}>
                      <button
                        type="button"
                        className={cn(
                          "flex w-full items-center justify-between gap-3 px-3 py-2 text-left text-sm",
                          "hover:bg-muted/40"
                        )}
                        onClick={() => {
                          onChange(c)
                          setOpen(false)
                          setQuery("")
                        }}
                        role="option"
                        aria-selected={selected}
                      >
                        <span className="flex min-w-0 items-center gap-2">
                          <span className="shrink-0" aria-hidden>
                            {flagEmojiFromIso2(c.id)}
                          </span>
                          <span className="shrink-0 font-medium">{c.dialingCode}</span>
                          <span className="min-w-0 truncate text-muted-foreground">{c.name}</span>
                        </span>
                        {selected && <Check className="h-4 w-4 text-primary" />}
                      </button>
                    </li>
                  )
                })}
              </ul>
            )}
          </div>
        </PopoverPrimitive.Content>
      </PopoverPrimitive.Portal>
    </PopoverPrimitive.Root>
  )
}
