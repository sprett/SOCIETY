import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react"
import type { Session } from "@supabase/supabase-js"
import { supabase } from "@/lib/supabase"
import type { Profile } from "@/types/profile"

interface AuthState {
  session: Session | null
  profile: Profile | null
  loading: boolean
  isAdmin: boolean
}

interface AuthContextValue extends AuthState {
  signIn: (email: string, password: string) => Promise<{ error: string | null }>
  signInWithGoogle: () => Promise<{ error: string | null }>
  signOut: () => Promise<void>
  refreshProfile: () => Promise<void>
  authError: string | null
  clearAuthError: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)


async function fetchProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase
    .from("profiles")
    .select("id, role")
    .eq("id", userId)
    .maybeSingle()
  if (error) {
    throw new Error(error.message)
  }
  if (!data) return null
  return { id: data.id, role: data.role as "user" | "admin" }
}

const NOT_ADMIN_MESSAGE = "You don't have access to the admin dashboard."

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [authError, setAuthError] = useState<string | null>(null)

  const clearAuthError = useCallback(() => setAuthError(null), [])

  const refreshProfile = useCallback(async () => {
    const { data: { session: s } } = await supabase.auth.getSession()
    if (!s?.user?.id) {
      setProfile(null)
      return
    }
    const p = await fetchProfile(s.user.id)
    setProfile(p)
  }, [])

  useEffect(() => {
    let isActive = true

    const loadSession = async () => {
      try {
        const {
          data: { session: s },
          error,
        } = await supabase.auth.getSession()

        if (!isActive) return

        if (error) {
          console.error("[Auth] getSession error:", error.message)
          setSession(null)
          setProfile(null)
          await supabase.auth.signOut()
          return
        }

        setSession(s)
        if (s?.user?.id) {
          try {
            const p = await fetchProfile(s.user.id)
            if (!isActive) return
            if (p?.role !== "admin") {
              setAuthError(NOT_ADMIN_MESSAGE)
              setSession(null)
              setProfile(null)
              await supabase.auth.signOut()
              return
            }
            setProfile(p)
          } catch (profileError) {
            console.error("[Auth] profile load failed:", profileError)
            if (!isActive) return
            setSession(null)
            setProfile(null)
            await supabase.auth.signOut()
            return
          }
        } else {
          setProfile(null)
        }
      } catch (e) {
        if (!isActive) return
        console.error("[Auth] initial session load failed:", e)
        setSession(null)
        setProfile(null)
      } finally {
        if (isActive) setLoading(false)
      }
    }

    loadSession()

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, s) => {
      if (!isActive) return
      setSession(s)
      if (s?.user?.id) {
        setLoading(true)
        // CRITICAL: Defer supabase calls until after callback returns (auth-js #762)
        const userId = s.user.id
        setTimeout(() => {
          if (!isActive) return
          fetchProfile(userId)
            .then((p) => {
              if (!isActive) return
              if (p?.role !== "admin") {
                setAuthError(NOT_ADMIN_MESSAGE)
                setSession(null)
                setProfile(null)
                void supabase.auth.signOut()
              } else {
                setProfile(p)
              }
            })
            .catch((profileError) => {
              console.error("[Auth] auth state profile load failed:", profileError)
              if (!isActive) return
              setSession(null)
              setProfile(null)
              void supabase.auth.signOut()
            })
            .finally(() => {
              if (isActive) setLoading(false)
            })
        }, 0)
      } else {
        setProfile(null)
        if (isActive) setLoading(false)
      }
    })

    return () => {
      isActive = false
      subscription.unsubscribe()
    }
  }, [])

  const signIn = useCallback(
    async (email: string, password: string): Promise<{ error: string | null }> => {
      setAuthError(null)
      try {
        const { data, error } = await supabase.auth.signInWithPassword({
          email,
          password,
        })
        if (error) return { error: error.message }
        if (!data.user?.id) return { error: "Sign in failed" }
        const p = await fetchProfile(data.user.id)
        if (p?.role !== "admin") {
          await supabase.auth.signOut()
          return { error: NOT_ADMIN_MESSAGE }
        }
        setSession(data.session)
        setProfile(p)
        return { error: null }
      } catch (e) {
        const isAbort = e instanceof Error && e.name === "AbortError"
        const msg = isAbort
          ? "Connection timed out. If your Supabase project was paused, try again in a minute."
          : (e instanceof Error ? e.message : "Sign in failed")
        if (!isAbort) console.error("[Auth] signIn error:", e)
        return { error: msg }
      }
    },
    []
  )

  const signInWithGoogle = useCallback(async (): Promise<{ error: string | null }> => {
    setAuthError(null)
    try {
      // redirectTo uses current origin so it works with ngrok/tunnels; add tunnel URL in Supabase Dashboard → Auth → URL Configuration → Redirect URLs
      const { error } = await supabase.auth.signInWithOAuth({
        provider: "google",
        options: { redirectTo: window.location.origin },
      })
      if (error) return { error: error.message }
      return { error: null }
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Sign in with Google failed"
      console.error("[Auth] signInWithGoogle error:", e)
      return { error: msg }
    }
  }, [])

  const signOut = useCallback(async () => {
    await supabase.auth.signOut()
    setSession(null)
    setProfile(null)
  }, [])

  const value: AuthContextValue = {
    session,
    profile,
    loading,
    isAdmin: profile?.role === "admin",
    signIn,
    signInWithGoogle,
    signOut,
    refreshProfile,
    authError,
    clearAuthError,
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error("useAuth must be used within AuthProvider")
  return ctx
}
