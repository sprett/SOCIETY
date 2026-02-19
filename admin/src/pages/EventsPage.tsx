import { useEffect, useState } from "react"
import { supabase } from "@/lib/supabase"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

interface AdminEventRow {
  id: string
  title: string
  category: string
  start_at: string
  created_at: string
  visibility: string
  owner_id: string | null
  venue_name: string | null
}

function formatDate(value: string) {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return "—"
  return new Intl.DateTimeFormat(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(date)
}

export function EventsPage() {
  const [events, setEvents] = useState<AdminEventRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function load() {
      const { data, error: err } = await supabase.rpc("get_admin_events")
      if (err) {
        setError(err.message)
        setLoading(false)
        return
      }
      setEvents((data ?? []) as AdminEventRow[])
      setLoading(false)
    }
    load()
  }, [])

  if (loading) {
    return (
      <div className="flex items-center justify-center rounded-card border bg-card p-12 shadow-soft">
        <p className="text-muted-foreground">Loading events…</p>
      </div>
    )
  }

  if (error) {
    return (
      <Card>
        <CardContent className="p-6">
          <p className="text-destructive" role="alert">
            Failed to load events: {error}
          </p>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold tracking-tight">Events</h1>
      <Card>
        <CardHeader>
          <CardTitle className="text-base font-semibold">
            Event list ({events.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {events.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No events found.</p>
          ) : (
            <div className="overflow-hidden rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/50">
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Title</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Category</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Start</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Venue</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Visibility</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Created</th>
                  </tr>
                </thead>
                <tbody>
                  {events.map((event) => (
                    <tr
                      key={event.id}
                      className="border-b border-border last:border-0 transition-colors hover:bg-muted/30"
                    >
                      <td className="px-4 py-3 font-medium">{event.title}</td>
                      <td className="px-4 py-3 text-muted-foreground">{event.category}</td>
                      <td className="px-4 py-3 text-muted-foreground">{formatDate(event.start_at)}</td>
                      <td className="px-4 py-3 text-muted-foreground">{event.venue_name ?? "—"}</td>
                      <td className="px-4 py-3">
                        <span
                          className={
                            event.visibility === "public"
                              ? "text-success"
                              : "text-muted-foreground"
                          }
                        >
                          {event.visibility}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">{formatDate(event.created_at)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
