import {
  createContext,
  useCallback,
  useContext,
  useState,
  type ReactNode,
} from "react"

export type PeriodKey = "7" | "30" | "90" | "365"

const PERIOD_LABELS: Record<PeriodKey, string> = {
  "7": "Last 7 days",
  "30": "Last 30 days",
  "90": "Last 90 days",
  "365": "Last year",
}

interface PeriodContextValue {
  period: PeriodKey
  /** Effective number of days for the API (preset or custom) */
  periodDays: number
  setPeriod: (p: PeriodKey) => void
  /** When user picks a custom range, call this with the number of days */
  setCustomDays: (days: number | null) => void
  periodLabel: string
}

const PeriodContext = createContext<PeriodContextValue | null>(null)

const PRESET_DAYS: Record<PeriodKey, number> = {
  "7": 7,
  "30": 30,
  "90": 90,
  "365": 365,
}

export function PeriodProvider({ children }: { children: ReactNode }) {
  const [period, setPeriodState] = useState<PeriodKey>("30")
  const [customDays, setCustomDaysState] = useState<number | null>(null)
  const setPeriod = useCallback((p: PeriodKey) => {
    setPeriodState(p)
    setCustomDaysState(null)
  }, [])
  const setCustomDays = useCallback((days: number | null) => setCustomDaysState(days), [])
  const periodDays = customDays ?? PRESET_DAYS[period]
  const periodLabel = customDays != null ? `Last ${customDays} days` : PERIOD_LABELS[period]
  return (
    <PeriodContext.Provider
      value={{ period, periodDays, setPeriod, setCustomDays, periodLabel }}
    >
      {children}
    </PeriodContext.Provider>
  )
}

export function usePeriod() {
  const ctx = useContext(PeriodContext)
  if (!ctx) throw new Error("usePeriod must be used within PeriodProvider")
  return ctx
}

export { PERIOD_LABELS }
