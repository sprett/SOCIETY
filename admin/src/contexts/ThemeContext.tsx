import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react"

export type Theme = "light" | "dark" | "system"

const STORAGE_KEY = "society-admin-theme"

function getSystemDark(): boolean {
  if (typeof window === "undefined") return false
  return window.matchMedia("(prefers-color-scheme: dark)").matches
}

function getStoredTheme(): Theme {
  if (typeof window === "undefined") return "system"
  const stored = localStorage.getItem(STORAGE_KEY) as Theme | null
  return stored === "light" || stored === "dark" || stored === "system" ? stored : "system"
}

function applyTheme(theme: Theme) {
  const root = document.documentElement
  const isDark =
    theme === "dark" || (theme === "system" && getSystemDark())
  if (isDark) {
    root.classList.add("dark")
  } else {
    root.classList.remove("dark")
  }
}

interface ThemeContextValue {
  theme: Theme
  setTheme: (t: Theme) => void
  /** Resolved: true if UI should be dark right now */
  resolvedDark: boolean
}

const ThemeContext = createContext<ThemeContextValue | null>(null)

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState<Theme>("system")
  const [resolvedDark, setResolvedDark] = useState(false)

  const setTheme = useCallback((t: Theme) => {
    setThemeState(t)
    localStorage.setItem(STORAGE_KEY, t)
    applyTheme(t)
    setResolvedDark(t === "dark" || (t === "system" && getSystemDark()))
  }, [])

  useEffect(() => {
    const stored = getStoredTheme()
    setThemeState(stored)
    applyTheme(stored)
    setResolvedDark(stored === "dark" || (stored === "system" && getSystemDark()))
  }, [])

  useEffect(() => {
    if (theme !== "system") return
    const mq = window.matchMedia("(prefers-color-scheme: dark)")
    const handle = () => {
      applyTheme("system")
      setResolvedDark(getSystemDark())
    }
    mq.addEventListener("change", handle)
    return () => mq.removeEventListener("change", handle)
  }, [theme])

  return (
    <ThemeContext.Provider
      value={{
        theme,
        setTheme,
        resolvedDark,
      }}
    >
      {children}
    </ThemeContext.Provider>
  )
}

export function useTheme() {
  const ctx = useContext(ThemeContext)
  if (!ctx) throw new Error("useTheme must be used within ThemeProvider")
  return ctx
}
