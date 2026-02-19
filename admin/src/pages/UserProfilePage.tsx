import { useEffect, useMemo, useState } from "react"
import { Link, useParams } from "react-router-dom"
import { Bar, BarChart, CartesianGrid, Cell, Pie, PieChart, Tooltip, XAxis, YAxis } from "recharts"
import {
  AtSign,
  CalendarDays,
  Clock3,
  Globe,
  Instagram,
  Linkedin,
  Mail,
  Music2,
  Phone,
  User,
  Youtube,
} from "lucide-react"
import { buttonVariants } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ChartContainer, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart"
import { getAdminUserProfile } from "@/lib/users/api"
import type { AdminUserEventSummary, AdminUserProfileData } from "@/lib/users/types"
import { isValidUsername, normalizeUsername } from "@/lib/users/username"
import { cn } from "@/lib/utils"

const PERIODS = ["7", "30", "90", "365"] as const

const pieConfig = {
  value: {
    label: "Events",
    color: "hsl(var(--chart-1))",
  },
} satisfies ChartConfig

const barConfig = {
  count: {
    label: "Events",
    color: "hsl(var(--primary))",
  },
} satisfies ChartConfig

const CATEGORY_COLORS = [
  "hsl(var(--chart-1))",
  "hsl(var(--chart-2))",
  "hsl(var(--chart-3))",
  "hsl(var(--chart-4))",
  "hsl(var(--chart-5))",
  "#0ea5e9",
  "#16a34a",
]

function formatDate(value: string | null) {
  if (!value) return "-"
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return "-"
  return new Intl.DateTimeFormat(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(date)
}

function formatDateOnly(value: string | null) {
  if (!value) return "-"
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return "-"
  return new Intl.DateTimeFormat(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  }).format(date)
}

function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  if (parts.length === 0) return "U"
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase()
  return `${parts[0][0]}${parts[1][0]}`.toUpperCase()
}

function normalizeExternalUrl(value: string) {
  const trimmed = value.trim()
  if (!trimmed) return ""
  if (/^https?:\/\//i.test(trimmed)) return trimmed
  return `https://${trimmed}`
}

function EventStrip({ title, events }: { title: string; events: AdminUserEventSummary[] }) {
  return (
    <Card className="border-border/60 shadow-sm">
      <CardHeader className="pb-3">
        <CardTitle className="text-base">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        {events.length === 0 ? (
          <p className="text-sm text-muted-foreground">No events.</p>
        ) : (
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
            {events.map((event) => (
              <div key={event.id} className="overflow-hidden rounded-lg border border-border/60 bg-muted/10">
                {event.image_url ? (
                  <img src={event.image_url} alt="" className="h-28 w-full object-cover" loading="lazy" />
                ) : (
                  <div className="flex h-28 w-full items-center justify-center bg-muted text-xs text-muted-foreground">
                    No image
                  </div>
                )}
                <div className="space-y-1 p-3">
                  <p className="line-clamp-1 font-medium">{event.title ?? "Untitled event"}</p>
                  <p className="text-xs text-muted-foreground">{formatDate(event.start_at)}</p>
                  <p className="line-clamp-1 text-xs text-muted-foreground">
                    {(event.category ?? "Uncategorized") + (event.venue_name ? ` · ${event.venue_name}` : "")}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  )
}

export function UserProfilePage() {
  const { username } = useParams()
  const normalizedUsername = normalizeUsername(username)
  const validUsername = isValidUsername(normalizedUsername)
  const [period, setPeriod] = useState<string>("90")
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [payload, setPayload] = useState<AdminUserProfileData | null>(null)

  useEffect(() => {
    if (!validUsername) {
      return
    }

    let active = true

    getAdminUserProfile(normalizedUsername, period)
      .then((data) => {
        if (!active) return
        if (!data) {
          setError("User not found")
          setPayload(null)
          return
        }
        setPayload(data)
      })
      .catch((e) => {
        if (!active) return
        setError(e instanceof Error ? e.message : "Failed to load profile")
        setPayload(null)
      })
      .finally(() => {
        if (active) setLoading(false)
      })

    return () => {
      active = false
    }
  }, [normalizedUsername, period, validUsername])

  const profile = payload?.profile
  const metrics = payload?.metrics

  const pieData = useMemo(() => {
    const source = payload?.charts.categories ?? []
    return source.map((item, index) => ({
      name: item.category || "Uncategorized",
      value: item.count,
      fill: CATEGORY_COLORS[index % CATEGORY_COLORS.length],
    }))
  }, [payload?.charts.categories])

  const totalPie = pieData.reduce((sum, row) => sum + row.value, 0)
  const maxBar = Math.max(...(payload?.charts.active_day.map((d) => d.count) ?? [0]))

  if (!validUsername) {
    return (
      <Card>
        <CardContent className="space-y-4 p-6">
          <p className="text-sm text-destructive" role="alert">
            Invalid username
          </p>
          <Link to="/users" className={buttonVariants({ variant: "outline", size: "sm" })}>
            Back to users
          </Link>
        </CardContent>
      </Card>
    )
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center rounded-card border bg-card p-12 shadow-soft">
        <p className="text-muted-foreground">Loading profile...</p>
      </div>
    )
  }

  if (error || !profile || !metrics) {
    return (
      <Card>
        <CardContent className="space-y-4 p-6">
          <p className="text-sm text-destructive" role="alert">
            {error ?? "Profile not found"}
          </p>
          <Link to="/users" className={buttonVariants({ variant: "outline", size: "sm" })}>
            Back to users
          </Link>
        </CardContent>
      </Card>
    )
  }

  const displayName = profile.full_name?.trim() || profile.email || "Unnamed"

  const socialLinks = [
    { label: "Instagram", href: profile.instagram_handle ? `https://instagram.com/${profile.instagram_handle.replace(/^@/, "")}` : "", icon: Instagram },
    { label: "Twitter", href: profile.twitter_handle ? `https://x.com/${profile.twitter_handle.replace(/^@/, "")}` : "", icon: AtSign },
    { label: "YouTube", href: profile.youtube_handle ? `https://youtube.com/${profile.youtube_handle.replace(/^@/, "")}` : "", icon: Youtube },
    { label: "TikTok", href: profile.tiktok_handle ? `https://www.tiktok.com/@${profile.tiktok_handle.replace(/^@/, "")}` : "", icon: Music2 },
    { label: "LinkedIn", href: profile.linkedin_handle ? `https://linkedin.com/in/${profile.linkedin_handle.replace(/^@/, "")}` : "", icon: Linkedin },
    { label: "Website", href: profile.website_url ? normalizeExternalUrl(profile.website_url) : "", icon: Globe },
  ].filter((item) => item.href)

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <Link to="/users" className={buttonVariants({ variant: "outline", size: "sm" })}>
          Back to users
        </Link>
        <div className="inline-flex items-center rounded-md border border-border p-1">
          {PERIODS.map((value) => (
            <button
              key={value}
              type="button"
              onClick={() => {
                if (value === period) return
                setLoading(true)
                setError(null)
                setPeriod(value)
              }}
              className={cn(
                "rounded px-3 py-1.5 text-sm",
                period === value
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:bg-muted"
              )}
            >
              {value}d
            </button>
          ))}
        </div>
      </div>

      <Card className="border-border/60 shadow-sm">
        <CardContent className="p-6">
          <div className="flex flex-wrap items-center gap-5">
            {profile.avatar_url ? (
              <img src={profile.avatar_url} alt="" className="h-28 w-28 rounded-full object-cover" />
            ) : (
              <div className="flex h-28 w-28 items-center justify-center rounded-full bg-muted text-3xl font-semibold text-muted-foreground">
                {initials(displayName)}
              </div>
            )}
            <div className="min-w-0 flex-1 space-y-2">
              <div className="min-w-0">
                <div className="flex min-w-0 items-baseline gap-3">
                  <h1 className="min-w-0 truncate text-2xl font-semibold">{displayName}</h1>
                  <span className="shrink-0 truncate text-muted-foreground">
                    @{profile.username ?? "-"}
                  </span>
                </div>
              </div>

              <div className="space-y-2 text-sm text-muted-foreground">
                <div className="flex items-start gap-2">
                  <Mail className="mt-0.5 h-4 w-4 shrink-0" />
                  <span className="break-all">{profile.email ?? "-"}</span>
                </div>
                <div className="flex items-start gap-2">
                  <Phone className="mt-0.5 h-4 w-4 shrink-0" />
                  <span className="break-all">{profile.phone_number ?? "-"}</span>
                </div>
                <div className="flex items-start gap-2">
                  <User className="mt-0.5 h-4 w-4 shrink-0" />
                  <span>Birthday {formatDateOnly(profile.birthday)}</span>
                </div>
              </div>
            </div>

            <div className="ml-auto flex w-full flex-col items-start gap-3 sm:w-auto sm:items-end">
              {socialLinks.length > 0 && (
                <div className="flex items-center justify-end gap-2">
                  {socialLinks.map((item) => (
                    <a
                      key={item.label}
                      href={item.href}
                      target="_blank"
                      rel="noreferrer"
                      className="rounded-md border border-border p-2 text-muted-foreground hover:bg-muted hover:text-foreground"
                      title={item.label}
                    >
                      <item.icon className="h-4 w-4" />
                    </a>
                  ))}
                </div>
              )}

              <div className="space-y-2 text-sm text-muted-foreground sm:text-right">
                <div className="flex items-start gap-2 sm:flex-row-reverse sm:justify-end">
                  <CalendarDays className="mt-0.5 h-4 w-4 shrink-0" />
                  <span>Joined {formatDateOnly(profile.created_at)}</span>
                </div>
                <div className="flex items-start gap-2 sm:flex-row-reverse sm:justify-end">
                  <Clock3 className="mt-0.5 h-4 w-4 shrink-0" />
                  <span>Last seen {formatDate(profile.last_seen_at)}</span>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <Card className="border-border/60"><CardContent className="pt-6"><p className="text-xs text-muted-foreground">App opens (all)</p><p className="mt-1 text-2xl font-semibold">{metrics.app_opens_total.toLocaleString()}</p></CardContent></Card>
        <Card className="border-border/60"><CardContent className="pt-6"><p className="text-xs text-muted-foreground">App opens ({period}d)</p><p className="mt-1 text-2xl font-semibold">{metrics.app_opens_in_period.toLocaleString()}</p></CardContent></Card>
        <Card className="border-border/60"><CardContent className="pt-6"><p className="text-xs text-muted-foreground">Hosted</p><p className="mt-1 text-2xl font-semibold">{metrics.hosted_total.toLocaleString()}</p></CardContent></Card>
        <Card className="border-border/60"><CardContent className="pt-6"><p className="text-xs text-muted-foreground">Attended</p><p className="mt-1 text-2xl font-semibold">{metrics.attended_past_total.toLocaleString()}</p></CardContent></Card>
        <Card className="border-border/60"><CardContent className="pt-6"><p className="text-xs text-muted-foreground">Signed up</p><p className="mt-1 text-2xl font-semibold">{metrics.signed_up_upcoming_total.toLocaleString()}</p></CardContent></Card>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="border-border/60 shadow-sm">
          <CardHeader>
            <CardTitle className="text-base">Most active day</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[260px]">
              <ChartContainer config={barConfig} className="h-full w-full">
                <BarChart data={payload.charts.active_day} margin={{ top: 8, right: 8, left: 8, bottom: 8 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} className="stroke-border" />
                  <XAxis dataKey="day_name" axisLine={false} tickLine={false} />
                  <YAxis axisLine={false} tickLine={false} />
                  <Tooltip content={({ active, payload: toolPayload, label }) => <ChartTooltipContent active={active} payload={toolPayload} label={label} />} />
                  <Bar dataKey="count" name="Events" radius={[4, 4, 0, 0]}>
                    {payload.charts.active_day.map((entry, index) => (
                      <Cell
                        key={`active-${index}`}
                        fill={entry.count === maxBar && maxBar > 0 ? "hsl(var(--primary))" : "hsl(var(--muted))"}
                      />
                    ))}
                  </Bar>
                </BarChart>
              </ChartContainer>
            </div>
          </CardContent>
        </Card>

        <Card className="border-border/60 shadow-sm">
          <CardHeader>
            <CardTitle className="text-base">Event categories</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[260px]">
              {totalPie === 0 ? (
                <p className="flex h-full items-center justify-center text-sm text-muted-foreground">
                  No category activity in selected period.
                </p>
              ) : (
                <ChartContainer config={pieConfig} className="h-full w-full">
                  <PieChart>
                    <Pie data={pieData} dataKey="value" nameKey="name" innerRadius={50} outerRadius={85}>
                      {pieData.map((row, index) => (
                        <Cell key={`pie-${index}`} fill={row.fill} />
                      ))}
                    </Pie>
                    <Tooltip content={({ active, payload: toolPayload, label }) => <ChartTooltipContent active={active} payload={toolPayload} label={label} />} />
                  </PieChart>
                </ChartContainer>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="space-y-4">
        <EventStrip title="Hosted events" events={payload.events.hosted_recent} />
        <EventStrip title="Attended events" events={payload.events.attended_past_recent} />
        <EventStrip title="Signed up events" events={payload.events.signed_up_upcoming_recent} />
      </div>
    </div>
  )
}
