import { useCallback, useEffect, useMemo, useState } from "react";
import { supabase } from "@/lib/supabase";
import { useNavigate } from "react-router-dom";

const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;
const THIRTY_DAYS_AGO_INITIAL = Date.now() - THIRTY_DAYS_MS;
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Search,
  Download,
  Pencil,
  Eye,
  Mail,
  EllipsisVertical,
  Trash2,
  ChevronsLeft,
  ChevronLeft,
  ChevronRight,
  ChevronsRight,
  Users,
  UserCheck,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { AdminUserRow } from "@/lib/users/types";
import { isValidUsername, normalizeUsername } from "@/lib/users/username";
import { ActiveUsersMapCard } from "@/components/users/ActiveUsersMapCard";
import { EditUserModal } from "@/components/users/EditUserModal";
import { DeleteUserConfirmDialog } from "@/components/users/DeleteUserConfirmDialog";

const ACTIVE_THRESHOLD_MINUTES = 1;
const ROWS_PER_PAGE_OPTIONS = [10, 15, 25, 50] as const;
const DEFAULT_ROWS_PER_PAGE = 15;

function formatJoinedDate(value: string | null) {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return new Intl.DateTimeFormat(undefined, {
    day: "numeric",
    month: "short",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).format(date);
}

function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "U";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
}

function isActive(lastSeenAt: string | null): boolean {
  if (!lastSeenAt) return false;
  const t = new Date(lastSeenAt).getTime();
  return (
    Number.isFinite(t) && Date.now() - t < ACTIVE_THRESHOLD_MINUTES * 60 * 1000
  );
}

/** Avatar with optional online status indicator (green dot when active within threshold). */
function UserAvatar({
  src,
  displayName,
  size = "md",
  isOnline,
}: {
  src: string | null;
  displayName: string;
  size?: "md" | "lg";
  isOnline: boolean;
}) {
  const sizeClass = size === "lg" ? "h-10 w-10" : "h-9 w-9";
  const dotClass = size === "lg" ? "h-3 w-3" : "h-3 w-3";
  return (
    <div className="relative shrink-0">
      {src ? (
        <img
          src={src}
          alt=""
          className={cn(sizeClass, "rounded-full object-cover")}
          loading="lazy"
        />
      ) : (
        <div
          className={cn(
            sizeClass,
            "flex items-center justify-center rounded-full bg-muted text-xs font-medium text-muted-foreground",
            size === "lg" && "text-sm",
          )}
        >
          {initials(displayName)}
        </div>
      )}
      {isOnline && (
        <span
          className={cn(
            "absolute bottom-0 right-0 rounded-full border-2 border-background bg-emerald-500",
            dotClass,
          )}
          title="Online"
        />
      )}
    </div>
  );
}

function SignInProviderBadge({ provider }: { provider: string | null }) {
  const p = (provider ?? "email").toLowerCase();
  if (p === "apple") {
    return (
      <span className="inline-flex items-center gap-1.5 rounded-md bg-muted px-2 py-0.5 text-xs font-medium text-foreground">
        <AppleIcon className="h-3.5 w-3.5" />
        Apple
      </span>
    );
  }
  if (p === "google") {
    return (
      <span className="inline-flex items-center gap-1.5 rounded-md bg-muted px-2 py-0.5 text-xs font-medium text-foreground">
        <GoogleIcon className="h-3.5 w-3.5" />
        Google
      </span>
    );
  }
  return (
    <span className="inline-flex items-center gap-1.5 rounded-md bg-muted px-2 py-0.5 text-xs font-medium text-foreground">
      <Mail className="h-3.5 w-3.5" />
      Email
    </span>
  );
}

function AppleIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden
    >
      <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
    </svg>
  );
}

function GoogleIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" aria-hidden>
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
  );
}

export function UsersPage() {
  const navigate = useNavigate();
  const [users, setUsers] = useState<AdminUserRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [page, setPage] = useState(1);
  const [rowsPerPage, setRowsPerPage] = useState(DEFAULT_ROWS_PER_PAGE);
  const [editUser, setEditUser] = useState<AdminUserRow | null>(null);
  const [deleteUser, setDeleteUser] = useState<AdminUserRow | null>(null);

  const loadUsers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data, error: err } = await supabase.rpc("get_admin_users");
      if (err) {
        throw new Error(err.message);
      }
      setUsers((data ?? []) as AdminUserRow[]);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load users");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  const onEditSaved = useCallback(async () => {
    await loadUsers();
  }, [loadUsers]);

  const onDeleteCompleted = useCallback(async () => {
    await loadUsers();
  }, [loadUsers]);

  const goToUserProfile = useCallback(
    (username: string | null) => {
      const normalized = normalizeUsername(username);
      if (!isValidUsername(normalized)) {
        return;
      }
      navigate(`/users/${normalized}`);
    },
    [navigate],
  );

  const canViewProfile = useCallback((username: string | null) => {
    return isValidUsername(username);
  }, []);

  const sendEmail = useCallback((email: string | null) => {
    if (!email) return;
    window.location.href = `mailto:${email}`;
  }, []);

  const sortedUsers = useMemo(
    () =>
      [...users].sort((a, b) => {
        const aTime = a.created_at ? new Date(a.created_at).getTime() : 0;
        const bTime = b.created_at ? new Date(b.created_at).getTime() : 0;
        return bTime - aTime;
      }),
    [users],
  );

  const metrics = useMemo(() => {
    const thirtyDaysAgo = THIRTY_DAYS_AGO_INITIAL;
    let active30d = 0;
    let liveNow = 0;
    let new30d = 0;
    for (const u of users) {
      const lastActivity = u.last_login_at || u.last_app_open_at;
      if (lastActivity && new Date(lastActivity).getTime() >= thirtyDaysAgo)
        active30d++;
      if (isActive(u.last_seen_at)) liveNow++;
      if (u.created_at && new Date(u.created_at).getTime() >= thirtyDaysAgo)
        new30d++;
    }
    return {
      total: users.length,
      active30d,
      liveNow,
      new30d,
    };
  }, [users]);

  const filteredUsers = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return sortedUsers;
    return sortedUsers.filter(
      (u) =>
        (u.full_name ?? "").toLowerCase().includes(q) ||
        (u.email ?? "").toLowerCase().includes(q) ||
        (u.username ?? "").toLowerCase().includes(q),
    );
  }, [sortedUsers, searchQuery]);

  const totalRows = filteredUsers.length;
  const totalPages = Math.max(1, Math.ceil(totalRows / rowsPerPage));
  const safePage = Math.min(page, totalPages);
  const paginatedUsers = useMemo(() => {
    const start = (safePage - 1) * rowsPerPage;
    return filteredUsers.slice(start, start + rowsPerPage);
  }, [filteredUsers, safePage, rowsPerPage]);

  const startRow = totalRows === 0 ? 0 : (safePage - 1) * rowsPerPage + 1;
  const endRow = Math.min(safePage * rowsPerPage, totalRows);

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchQuery(e.target.value);
    setPage(1);
  };

  const handleRowsPerPageChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = Number(e.target.value);
    if (
      ROWS_PER_PAGE_OPTIONS.includes(
        value as (typeof ROWS_PER_PAGE_OPTIONS)[number],
      )
    ) {
      setRowsPerPage(value);
      setPage(1);
    }
  };

  function exportCsv() {
    const headers = [
      "Full name",
      "Email",
      "Username",
      "Join date",
      "Sign-in provider",
    ];
    const escape = (s: string) => {
      const t = String(s ?? "").replace(/"/g, '""');
      return t.includes(",") || t.includes('"') || t.includes("\n")
        ? `"${t}"`
        : t;
    };
    const providerLabel = (p: string | null) => {
      const x = (p ?? "email").toLowerCase();
      if (x === "apple") return "Apple";
      if (x === "google") return "Google";
      return "Email";
    };
    const rows = filteredUsers.map((u) =>
      [
        u.full_name ?? "",
        u.email ?? "",
        u.username ?? "",
        formatJoinedDate(u.created_at),
        providerLabel(u.sign_in_provider),
      ]
        .map(escape)
        .join(","),
    );
    const csv = [headers.map(escape).join(","), ...rows].join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `users-export-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  /** Page numbers to show: first, last, current ± 1, with ellipsis where needed */
  const pageNumbers = useMemo(() => {
    if (totalPages <= 7) {
      return Array.from({ length: totalPages }, (_, i) => i + 1);
    }
    const pages: (number | "ellipsis")[] = [1];
    if (safePage > 3) pages.push("ellipsis");
    const seen = new Set(pages.filter((x): x is number => x !== "ellipsis"));
    for (let p = safePage - 1; p <= safePage + 1; p++) {
      if (p >= 1 && p <= totalPages && !seen.has(p)) {
        pages.push(p);
        seen.add(p);
      }
    }
    if (safePage < totalPages - 2) pages.push("ellipsis");
    if (totalPages > 1 && !seen.has(totalPages)) pages.push(totalPages);
    return pages;
  }, [totalPages, safePage]);

  if (loading) {
    return (
      <div className="flex items-center justify-center rounded-card border bg-card p-12 shadow-soft">
        <p className="text-muted-foreground">Loading users…</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-lg border border-border/60 bg-background/80 px-4 py-3">
        <p className="text-sm text-destructive" role="alert">
          Failed to load users: {error}
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-0">
      {/* Active Users map */}
      <div className="mb-6">
        <ActiveUsersMapCard />
      </div>

      {/* Metric cards */}
      <div className="mb-6 grid gap-4 sm:grid-cols-2">
        <Card className="border-border/60 shadow-sm">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <p className="text-sm font-medium text-muted-foreground">
                Total users
              </p>
              <Users className="h-5 w-5 text-muted-foreground" />
            </div>
            <div className="mt-2 text-2xl font-bold">
              {metrics.total.toLocaleString()}
            </div>
          </CardContent>
        </Card>
        <Card className="border-border/60 shadow-sm">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <p className="text-sm font-medium text-muted-foreground">
                Active users (30d)
              </p>
              <UserCheck className="h-5 w-5 text-muted-foreground" />
            </div>
            <div className="mt-2 text-2xl font-bold">
              {metrics.active30d.toLocaleString()}
            </div>
            <p className="mt-1 text-xs text-muted-foreground">Last 30 days</p>
          </CardContent>
        </Card>
      </div>

      <div className="mb-6 py-4">
        <h1 className="text-2xl font-semibold tracking-tight">User list</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Manage society users and their accounts
        </p>
      </div>

      {/* Toolbar: search + export */}
      <div className="flex flex-wrap items-center justify-end gap-4 border-b border-border/60 pb-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Search users..."
            value={searchQuery}
            onChange={handleSearchChange}
            className="h-9 pl-9 bg-transparent border-border/60"
          />
        </div>
        <Button
          variant="outline"
          size="sm"
          className="h-9 gap-1.5"
          onClick={exportCsv}
        >
          <Download className="h-4 w-4" />
          Export
        </Button>
      </div>

      {/* Table */}
      <div className="pt-5">
        {filteredUsers.length === 0 ? (
          <p className="py-12 text-center text-sm text-muted-foreground">
            {searchQuery.trim()
              ? "No users match your search."
              : "No users found."}
          </p>
        ) : (
          <div className="overflow-x-auto -mx-px">
            <table className="w-full text-sm min-w-[640px]">
              <thead>
                <tr className="border-b border-border/60">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                    User
                  </th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                    Username
                  </th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                    Join date
                  </th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                    Sign-in provider
                  </th>
                  <th className="px-4 py-3 text-right font-medium text-muted-foreground">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody>
                {paginatedUsers.map((user) => {
                  const displayName =
                    user.full_name?.trim() || user.email || "Unnamed";
                  const active = isActive(user.last_seen_at);
                  const viewEnabled = canViewProfile(user.username);
                  return (
                    <tr
                      key={user.id}
                      className="border-b border-border/40 transition-colors hover:bg-muted/20"
                    >
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <UserAvatar
                            src={user.avatar_url}
                            displayName={displayName}
                            size="md"
                            isOnline={active}
                          />
                          <div className="flex flex-col min-w-0">
                            <span className="font-medium">{displayName}</span>
                            <a
                              href={`mailto:${user.email ?? ""}`}
                              className="text-sm text-muted-foreground hover:text-foreground hover:underline truncate"
                            >
                              {user.email ?? "—"}
                            </a>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {user.username ?? "—"}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {formatJoinedDate(user.created_at)}
                      </td>
                      <td className="px-4 py-3">
                        <SignInProviderBadge provider={user.sign_in_provider} />
                      </td>
                      <td className="px-4 py-3 text-right">
                        <div className="flex items-center justify-end gap-1">
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8"
                            title={
                              viewEnabled
                                ? "View profile"
                                : "Username missing or invalid"
                            }
                            onClick={() => goToUserProfile(user.username)}
                            disabled={!viewEnabled}
                          >
                            <Eye className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8"
                            title="Edit"
                            onClick={() => setEditUser(user)}
                          >
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button
                                variant="ghost"
                                size="icon"
                                className="h-8 w-8"
                              >
                                <EllipsisVertical className="h-4 w-4" />
                                <span className="sr-only">More actions</span>
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem disabled>
                                View Details
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                onSelect={(e) => {
                                  e.preventDefault();
                                  sendEmail(user.email);
                                }}
                                disabled={!user.email}
                              >
                                <Mail className="mr-2 h-4 w-4" />
                                Send Email
                              </DropdownMenuItem>
                              <DropdownMenuSeparator />
                              <DropdownMenuItem
                                variant="destructive"
                                onSelect={(e) => {
                                  e.preventDefault();
                                  setDeleteUser(user);
                                }}
                              >
                                <Trash2 className="mr-2 h-4 w-4" />
                                Delete User
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {filteredUsers.length > 0 && (
          <div className="mt-4 flex flex-wrap items-center justify-between gap-4 border-t border-border/60 pt-4">
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <span>Rows per page</span>
              <select
                value={rowsPerPage}
                onChange={handleRowsPerPageChange}
                className="h-9 rounded-md border border-border bg-background px-2.5 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
                aria-label="Rows per page"
              >
                {ROWS_PER_PAGE_OPTIONS.map((n) => (
                  <option key={n} value={n}>
                    {n}
                  </option>
                ))}
              </select>
              <span>
                {startRow}-{endRow} of {totalRows} rows
              </span>
            </div>
            <div className="flex items-center gap-0.5">
              <Button
                variant="outline"
                size="icon"
                className="h-9 w-9 shrink-0"
                disabled={safePage <= 1}
                onClick={() => setPage(1)}
                aria-label="First page"
              >
                <ChevronsLeft className="h-4 w-4" />
              </Button>
              <Button
                variant="outline"
                size="icon"
                className="h-9 w-9 shrink-0"
                disabled={safePage <= 1}
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                aria-label="Previous page"
              >
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <div className="flex items-center gap-0.5 px-1">
                {pageNumbers.map((item, i) =>
                  item === "ellipsis" ? (
                    <span
                      key={`ellipsis-${i}`}
                      className="px-2 py-1 text-sm text-muted-foreground"
                    >
                      …
                    </span>
                  ) : (
                    <button
                      key={item}
                      type="button"
                      onClick={() => setPage(item)}
                      className={cn(
                        "min-w-[2rem] rounded-md px-2 py-1.5 text-sm font-medium transition-colors",
                        item === safePage
                          ? "font-semibold text-foreground"
                          : "text-muted-foreground hover:bg-muted hover:text-foreground",
                      )}
                    >
                      {item}
                    </button>
                  ),
                )}
              </div>
              <Button
                variant="outline"
                size="icon"
                className="h-9 w-9 shrink-0"
                disabled={safePage >= totalPages}
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                aria-label="Next page"
              >
                <ChevronRight className="h-4 w-4" />
              </Button>
              <Button
                variant="outline"
                size="icon"
                className="h-9 w-9 shrink-0"
                disabled={safePage >= totalPages}
                onClick={() => setPage(totalPages)}
                aria-label="Last page"
              >
                <ChevronsRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        )}
      </div>
      <EditUserModal
        open={!!editUser}
        user={editUser}
        onOpenChange={(open) => {
          if (!open) setEditUser(null);
        }}
        onSaved={onEditSaved}
      />
      <DeleteUserConfirmDialog
        open={!!deleteUser}
        user={deleteUser}
        onOpenChange={(open) => {
          if (!open) setDeleteUser(null);
        }}
        onDeleted={onDeleteCompleted}
      />
    </div>
  );
}
