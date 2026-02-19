import * as React from "react"
import { Outlet } from "react-router-dom"
import { PeriodProvider } from "@/contexts/PeriodContext"
import { RefreshProvider } from "@/contexts/RefreshContext"
import { AppSidebar } from "@/components/AppSidebar"
import { Header } from "@/components/Header"
import { SidebarInset, SidebarProvider } from "@/components/ui/sidebar"

export function Layout() {
  return (
    <PeriodProvider>
      <RefreshProvider>
        <SidebarProvider
          style={
            {
              "--sidebar-width": "16rem",
              "--sidebar-width-icon": "3rem",
            } as React.CSSProperties
          }
        >
          <AppSidebar />
          <SidebarInset>
            <Header />
            <div className="flex min-h-0 flex-1 flex-col overflow-y-auto">
              <div className="flex flex-1 flex-col gap-4 px-4 py-4 md:gap-6 md:py-6 lg:px-6">
                <Outlet />
              </div>
            </div>
          </SidebarInset>
        </SidebarProvider>
      </RefreshProvider>
    </PeriodProvider>
  )
}
