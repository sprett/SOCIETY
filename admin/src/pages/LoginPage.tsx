import { useState, useEffect } from "react"
import { useNavigate } from "react-router-dom"
import { useAuth } from "@/contexts/AuthContext"
import { SocietyLogo } from "@/components/SocietyLogo"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

function GoogleIcon() {
  return (
    <svg className="size-5" viewBox="0 0 24 24" aria-hidden>
      <path
        fill="#4285F4"
        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
      />
      <path
        fill="#34A853"
        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
      />
      <path
        fill="#FBBC05"
        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
      />
      <path
        fill="#EA4335"
        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
      />
    </svg>
  )
}

export function LoginPage() {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [googleLoading, setGoogleLoading] = useState(false)
  const { signIn, signInWithGoogle, authError, clearAuthError } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    clearAuthError()
  }, [clearAuthError])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (submitting) return
    setError(null)
    setSubmitting(true)
    try {
      const result = await signIn(email, password)
      if (result.error) {
        setError(result.error)
        return
      }
      navigate("/", { replace: true })
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Sign in failed"
      console.error("[Login] sign in failed:", e)
      setError(msg)
    } finally {
      setSubmitting(false)
    }
  }

  async function handleGoogleSignIn() {
    if (googleLoading) return
    setError(null)
    setGoogleLoading(true)
    try {
      const result = await signInWithGoogle()
      if (result.error) {
        setError(result.error)
        return
      }
      // Redirect will happen; no navigate needed
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Sign in with Google failed"
      setError(msg)
    } finally {
      setGoogleLoading(false)
    }
  }

  const displayError = error ?? authError

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <div className="w-full max-w-sm flex flex-col items-center gap-8">
        <div className="flex flex-col items-center gap-3">
          <SocietyLogo size={40} />
          <h1 className="text-2xl font-bold text-foreground tracking-tight">
            Login
          </h1>
          <p className="text-sm text-center text-muted-foreground dark:text-neutral-300">
            Sign in to access the dashboard.
          </p>
        </div>

        <div className="w-full space-y-4">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <label htmlFor="email" className="text-sm font-medium text-foreground">
                Email
              </label>
              <Input
                id="email"
                type="email"
                autoComplete="email"
                value={email}
                onChange={(e) => {
                  setEmail(e.target.value)
                  if (authError) clearAuthError()
                }}
                required
                placeholder="Email"
                className="dark:border-neutral-500 dark:placeholder:text-neutral-400"
              />
            </div>
            <div className="space-y-2">
              <label htmlFor="password" className="text-sm font-medium text-foreground">
                Password
              </label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value)
                  if (authError) clearAuthError()
                }}
                required
                placeholder="Password"
                className="dark:border-neutral-500 dark:placeholder:text-neutral-400"
              />
            </div>
            {displayError && (
              <p className="text-sm text-destructive" role="alert">
                {displayError}
              </p>
            )}
            <Button
              type="submit"
              className="w-full rounded-lg"
              disabled={submitting}
            >
              {submitting ? "Signing in…" : "Login"}
            </Button>
          </form>

          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <span className="w-full border-t border-border dark:border-neutral-500" />
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-background px-2 text-muted-foreground dark:text-neutral-300">or</span>
            </div>
          </div>

          <Button
            type="button"
            variant="outline"
            className="w-full rounded-lg dark:border-neutral-500 dark:bg-card dark:hover:bg-accent"
            disabled={googleLoading}
            onClick={handleGoogleSignIn}
          >
            <GoogleIcon />
            {googleLoading ? "Signing in…" : "Google"}
          </Button>
        </div>
      </div>
    </div>
  )
}
