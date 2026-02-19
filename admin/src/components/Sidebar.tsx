import { NavLink } from "react-router-dom"
import { useAuth } from "@/contexts/AuthContext"
import { cn } from "@/lib/utils"
import { LayoutDashboard, LogOut, Package, Settings, Users } from "lucide-react"
import { SocietyLogo } from "@/components/SocietyLogo"
import { Button } from "@/components/ui/button"

const mainNavItems = [
  { to: "/", label: "Dashboard", icon: LayoutDashboard },
  { to: "/users", label: "Users", icon: Users },
  { to: "/events", label: "Events", icon: Package },
]

export function Sidebar() {
  const { signOut } = useAuth()

  return (
    <aside className="flex h-svh w-64 shrink-0 flex-col border-r border-sidebar-border bg-sidebar text-sidebar-foreground hidden md:flex">
      <div className="flex h-16 shrink-0 items-center px-6">
        <div className="flex items-center gap-2 font-bold text-xl tracking-tight text-sidebar-foreground">
          <SocietyLogo size={28} className="shrink-0" />
          <span>SOCIETY</span>
        </div>
      </div>

      <div className="flex min-h-0 flex-1 flex-col overflow-y-auto px-4 py-4">
        <nav className="space-y-1">
          {mainNavItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === "/"}
              className={({ isActive }) =>
                cn(
                  "group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
                  isActive ? "bg-sidebar-accent text-sidebar-accent-foreground font-medium" : "text-sidebar-foreground"
                )
              }
            >
              <item.icon
                className={cn(
                  "h-5 w-5 shrink-0",
                  "text-sidebar-foreground group-hover:text-sidebar-accent-foreground"
                )}
              />
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="mt-auto border-t border-sidebar-border pt-4">
          <NavLink
            to="/settings"
            className={({ isActive }) =>
              cn(
                "group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
                isActive ? "bg-sidebar-accent text-sidebar-accent-foreground font-medium" : "text-sidebar-foreground"
              )
            }
          >
            <Settings className="h-5 w-5 shrink-0" />
            <span>Settings</span>
          </NavLink>
          <Button
            variant="ghost"
            className="mt-1 w-full justify-start gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
            onClick={() => signOut()}
          >
            <LogOut className="h-5 w-5 shrink-0" />
            Sign out
          </Button>
        </div>

      </div>
    </aside>
  )
}
