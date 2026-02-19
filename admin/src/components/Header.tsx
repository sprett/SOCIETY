import { useState } from "react"
import { useRefresh } from "@/contexts/RefreshContext"
import { Input } from "@/components/ui/input"
import { SidebarTrigger } from "@/components/ui/sidebar"
import { Button } from "@/components/ui/button"
import { RefreshCw, Search } from "lucide-react"
import { Separator } from "@/components/ui/separator"
import { SupabaseStatusIndicator } from "@/components/SupabaseStatusIndicator"
import { cn } from "@/lib/utils"

export function Header() {
  const { triggerRefresh } = useRefresh()
  const [isRefreshing, setIsRefreshing] = useState(false)
  const [statusRefreshNonce, setStatusRefreshNonce] = useState(0)

  async function handleRefresh() {
    setIsRefreshing(true)
    setStatusRefreshNonce((current) => current + 1)
    triggerRefresh()
    setTimeout(() => setIsRefreshing(false), 1200)
  }

  return (
    <header className="flex h-14 shrink-0 items-center gap-2 border-b border-border/80 bg-transparent px-4 py-3 lg:gap-2 lg:px-6">
      <SidebarTrigger className="-ml-1" />
      <Separator orientation="vertical" className="mx-2 h-4" />
      <div className="flex flex-1 items-center gap-2">
        <div className="relative max-w-sm flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Search..."
            className="h-9 w-full rounded-md border border-border bg-background py-2 pl-9 pr-9 text-sm placeholder:text-muted-foreground focus-visible:ring-2 focus-visible:ring-primary/20 focus-visible:ring-offset-0"
            aria-label="Search"
          />
          <kbd className="pointer-events-none absolute right-2.5 top-1/2 hidden -translate-y-1/2 rounded border border-border/80 bg-muted/60 px-1.5 text-[10px] font-medium text-muted-foreground sm:inline-block">
            ⌘K
          </kbd>
        </div>
      </div>
      <div className="ml-auto flex items-center gap-2">
        <SupabaseStatusIndicator refreshNonce={statusRefreshNonce} />
        <Button
          variant="outline"
          size="icon"
          className="size-9 shrink-0"
          onClick={handleRefresh}
          disabled={isRefreshing}
          aria-label="Refresh stats"
          title="Refresh stats"
        >
          <RefreshCw className={cn("size-4", isRefreshing && "animate-spin")} />
        </Button>
      </div>
    </header>
  )
}
