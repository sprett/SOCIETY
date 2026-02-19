import { useEffect, useState } from "react"
import type { FeatureCollection, Point } from "geojson"
import { supabase } from "@/lib/supabase"
import { useRefresh } from "@/contexts/RefreshContext"
import { Card } from "@/components/ui/card"
import { Map, MapControls, MapClusterLayer } from "@/components/ui/map"

interface ActiveUsersMapData {
  active_count: number
  geo_json: {
    type: "FeatureCollection"
    features: Array<{
      type: "Feature"
      geometry: { type: "Point"; coordinates: [number, number] }
      properties?: Record<string, unknown>
    }>
  }
}

const CLUSTER_COLORS = ["#22c55e", "#16a34a", "#15803d"] as const

export function ActiveUsersMapCard() {
  const { refreshTrigger } = useRefresh()
  const [data, setData] = useState<ActiveUsersMapData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    setLoading(true)
    setError(null)
    void (async () => {
      try {
        const { data: result, error: err } = await supabase.rpc("get_active_users_map")
        if (err) {
          setError(err.message)
          setData(null)
          return
        }
        setData(result as ActiveUsersMapData)
      } catch {
        setError("Failed to load")
      } finally {
        setLoading(false)
      }
    })()
  }, [refreshTrigger])

  if (loading && !data) {
    return (
      <Card className="h-[400px] overflow-hidden border-border/60 shadow-sm">
        <div className="flex h-full items-center justify-center">
          <p className="text-sm text-muted-foreground">Loading map…</p>
        </div>
      </Card>
    )
  }

  if (error) {
    return (
      <Card className="h-[400px] overflow-hidden border-border/60 shadow-sm">
        <div className="flex h-full items-center justify-center">
          <p className="text-sm text-destructive">Failed to load: {error}</p>
        </div>
      </Card>
    )
  }

  const activeCount = data?.active_count ?? 0
  const geoJson = data?.geo_json ?? { type: "FeatureCollection", features: [] }
  const hasFeatures = geoJson.features && geoJson.features.length > 0

  return (
    <Card className="relative h-[400px] overflow-hidden border-border/60 shadow-sm">
      <Map
        center={[0, 20]}
        zoom={2}
        className="absolute inset-0 h-full w-full"
      >
        <MapControls position="bottom-right" showZoom showLocate={false} showCompass={false} showFullscreen={false} />
        {hasFeatures ? (
          <MapClusterLayer
            data={geoJson as FeatureCollection<Point>}
            clusterColors={[...CLUSTER_COLORS]}
            pointColor="#22c55e"
          />
        ) : null}
      </Map>

      {/* Stat overlay - top-left */}
      <div className="absolute left-4 top-4 z-10 rounded-lg border border-border/60 bg-card/95 px-4 py-3 shadow-sm backdrop-blur-sm">
        <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
          Active users
        </p>
        <p className="mt-0.5 text-2xl font-bold tabular-nums tracking-tight">
          {activeCount.toLocaleString()}
        </p>
        <p className="mt-0.5 text-xs text-muted-foreground">Last 1 min</p>
      </div>

      {/* Legend - bottom-left */}
      <div className="absolute bottom-4 left-4 z-10 flex items-center gap-4 rounded-lg border border-border/60 bg-card/95 px-3 py-2 shadow-sm backdrop-blur-sm">
        <span className="text-xs font-medium text-muted-foreground">Activity</span>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5">
            <span className="h-3 w-3 rounded-full bg-emerald-500/80" />
            <span className="text-xs text-muted-foreground">High</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="h-2.5 w-2.5 rounded-full bg-emerald-500/70" />
            <span className="text-xs text-muted-foreground">Medium</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="h-2 w-2 rounded-full bg-emerald-500/60" />
            <span className="text-xs text-muted-foreground">Low</span>
          </div>
        </div>
      </div>

      {/* Attribution - bottom-right (mapcn includes this by default, but we ensure it's visible) */}
      <div className="absolute bottom-4 right-14 z-10 text-[10px] text-muted-foreground/70">
        © CARTO, © OpenStreetMap
      </div>
    </Card>
  )
}
