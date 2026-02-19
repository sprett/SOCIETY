import { useAuth } from "@/contexts/AuthContext"
import { AccessDeniedPage } from "@/pages/AccessDeniedPage"
import { LoginPage } from "@/pages/LoginPage"

interface ProtectedRouteProps {
  children: React.ReactNode
}

export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const { session, loading, isAdmin } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <p className="text-muted-foreground">Loading…</p>
      </div>
    )
  }

  if (!session) {
    return <LoginPage />
  }

  if (!isAdmin) {
    return <AccessDeniedPage />
  }

  return <>{children}</>
}
