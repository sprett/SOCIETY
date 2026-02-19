import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react"
import { CheckCircle2, X } from "lucide-react"
import { cn } from "@/lib/utils"

type ToastKind = "success"

interface ToastItem {
  id: string
  kind: ToastKind
  message: ReactNode
  durationMs: number
}

interface ToastContextValue {
  success: (message: ReactNode, opts?: { durationMs?: number }) => void
  dismiss: (id: string) => void
}

const ToastContext = createContext<ToastContextValue | null>(null)

function createId(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID()
  }
  return `${Date.now()}-${Math.random().toString(16).slice(2)}`
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([])
  const timers = useRef<Map<string, number>>(new Map())

  const dismiss = useCallback((id: string) => {
    const t = timers.current.get(id)
    if (t) window.clearTimeout(t)
    timers.current.delete(id)
    setToasts((prev) => prev.filter((x) => x.id !== id))
  }, [])

  const push = useCallback(
    (item: Omit<ToastItem, "id">) => {
      const id = createId()
      setToasts((prev) => [{ ...item, id }, ...prev].slice(0, 3))
      const timer = window.setTimeout(() => dismiss(id), item.durationMs)
      timers.current.set(id, timer)
    },
    [dismiss]
  )

  const success = useCallback(
    (message: ReactNode, opts?: { durationMs?: number }) => {
      push({
        kind: "success",
        message,
        durationMs: opts?.durationMs ?? 4000,
      })
    },
    [push]
  )

  useEffect(() => {
    return () => {
      for (const t of timers.current.values()) window.clearTimeout(t)
      timers.current.clear()
    }
  }, [])

  const value = useMemo<ToastContextValue>(
    () => ({
      success,
      dismiss,
    }),
    [dismiss, success]
  )

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="pointer-events-none fixed right-4 top-4 z-50 flex w-[360px] max-w-[calc(100vw-2rem)] flex-col gap-2">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={cn(
              "pointer-events-auto flex items-start gap-3 rounded-xl border bg-card p-3 shadow-sm",
              "animate-in fade-in slide-in-from-right-4",
              t.kind === "success" && "border-emerald-500/30"
            )}
            role="status"
            aria-live="polite"
          >
            <div className="mt-0.5 text-emerald-600 dark:text-emerald-400">
              <CheckCircle2 className="h-4 w-4" />
            </div>
            <div className="min-w-0 flex-1 text-sm text-foreground">{t.message}</div>
            <button
              type="button"
              className="rounded-md p-1 text-muted-foreground hover:bg-accent hover:text-foreground"
              aria-label="Dismiss notification"
              onClick={() => dismiss(t.id)}
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  )
}

export function useToast() {
  const ctx = useContext(ToastContext)
  if (!ctx) throw new Error("useToast must be used within ToastProvider")
  return ctx
}

