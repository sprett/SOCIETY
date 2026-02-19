import { Link, NavLink, useLocation } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import {
  LayoutDashboard,
  LogOut,
  Package,
  Settings,
  Users,
} from "lucide-react";
import { SocietyLogo } from "@/components/SocietyLogo";
import { Button } from "@/components/ui/button";
import {
  Sidebar,
  SidebarContent,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "@/components/ui/sidebar";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";

const mainNavItems = [
  { to: "/", label: "Dashboard", icon: LayoutDashboard },
  { to: "/users", label: "Users", icon: Users },
  { to: "/events", label: "Events", icon: Package },
];

export function AppSidebar() {
  const { signOut } = useAuth();
  const location = useLocation();
  const { state, isMobile } = useSidebar();

  return (
    <Sidebar side="left" variant="inset" collapsible="icon">
      <SidebarHeader className="pt-5 pb-8">
        <SidebarMenu>
          <SidebarMenuItem>
            <Link
              to="/"
              className="flex w-full items-center gap-2 overflow-hidden rounded-md text-left text-sm outline-none transition-[padding] duration-200 ease-linear [&>span:last-child]:truncate group-data-[collapsible=icon]:justify-center group-data-[collapsible=icon]:px-2"
            >
              <div className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-neutral-900 dark:bg-white">
                <SocietyLogo size={24} className="text-white dark:text-black" />
              </div>
              <div className="grid min-w-0 flex-1 text-sm leading-tight group-data-[collapsible=icon]:hidden">
                <span className="truncate font-medium">SOCIETY</span>
                <span className="truncate text-xs text-sidebar-foreground/80">
                  Admin Dashboard
                </span>
              </div>
            </Link>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>
      <SidebarContent className="gap-6 pt-0">
        <SidebarMenu>
          {mainNavItems.map((item) => (
            <SidebarMenuItem key={item.to}>
              <SidebarMenuButton
                asChild
                tooltip={item.label}
                isActive={
                  location.pathname === item.to &&
                  (item.to !== "/" || location.pathname === "/")
                }
              >
                <NavLink to={item.to} end={item.to === "/"}>
                  <item.icon className="size-4 shrink-0" />
                  <span className="group-data-[collapsible=icon]:hidden">
                    {item.label}
                  </span>
                </NavLink>
              </SidebarMenuButton>
            </SidebarMenuItem>
          ))}
        </SidebarMenu>
        <div className="mt-auto border-t border-sidebar-border pt-6">
          <SidebarMenu>
            <SidebarMenuItem>
              <SidebarMenuButton
                asChild
                tooltip="Settings"
                isActive={location.pathname === "/settings"}
              >
                <NavLink to="/settings">
                  <Settings className="size-4 shrink-0" />
                  <span className="group-data-[collapsible=icon]:hidden">
                    Settings
                  </span>
                </NavLink>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <Tooltip>
                <TooltipTrigger asChild>
                  <Button
                    variant="ghost"
                    className="h-9 w-full justify-start gap-2.5 rounded-md px-3 py-2.5 text-sm font-medium text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground group-data-[collapsible=icon]:!size-8 group-data-[collapsible=icon]:!p-2 group-data-[collapsible=icon]:min-w-0 group-data-[collapsible=icon]:justify-center"
                    onClick={() => signOut()}
                  >
                    <LogOut className="size-4 shrink-0" />
                    <span className="group-data-[collapsible=icon]:hidden">
                      Sign out
                    </span>
                  </Button>
                </TooltipTrigger>
                <TooltipContent
                  side="right"
                  align="center"
                  hidden={state !== "collapsed" || isMobile}
                >
                  Sign out
                </TooltipContent>
              </Tooltip>
            </SidebarMenuItem>
          </SidebarMenu>
        </div>
      </SidebarContent>
    </Sidebar>
  );
}
