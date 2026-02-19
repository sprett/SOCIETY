import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { MoreHorizontal, Calendar } from "lucide-react"

interface RecentEvent {
  id: string
  title: string
  category: string
  start_at: string
  venue_name: string
  created_at: string
}

interface TopProductsProps {
    data: RecentEvent[]
}

export function TopProducts({ data }: TopProductsProps) {
  return (
    <Card className="col-span-4 md:col-span-2 border-border/60 shadow-sm h-[400px] overflow-hidden flex flex-col">
      <CardHeader className="flex flex-row items-center justify-between pb-2 shrink-0">
        <CardTitle className="text-base font-semibold">Recent Events</CardTitle>
        <button className="text-muted-foreground hover:text-foreground">
            <MoreHorizontal className="h-5 w-5" />
        </button>
      </CardHeader>
      <CardContent className="p-0 overflow-y-auto flex-1">
        <table className="w-full text-sm text-left">
            <thead className="text-xs text-muted-foreground uppercase bg-muted/20 sticky top-0 z-10">
                <tr>
                    <th className="px-6 py-3 font-medium">Date</th>
                    <th className="px-6 py-3 font-medium">Event Name</th>
                    <th className="px-6 py-3 font-medium">Category</th>
                    <th className="px-6 py-3 font-medium text-right">Venue</th>
                </tr>
            </thead>
            <tbody>
                {data.map((event) => (
                    <tr key={event.id} className="border-b border-border/40 hover:bg-muted/10 transition-colors">
                        <td className="px-6 py-4 font-medium text-muted-foreground whitespace-nowrap">
                            {new Date(event.start_at).toLocaleDateString()}
                        </td>
                        <td className="px-6 py-4 font-medium flex items-center gap-3">
                             <div className="h-8 w-8 rounded bg-muted/50 flex items-center justify-center text-xs text-muted-foreground">
                                <Calendar className="h-4 w-4" />
                             </div>
                            <span className="truncate max-w-[150px]" title={event.title}>{event.title}</span>
                        </td>
                        <td className="px-6 py-4 text-muted-foreground">{event.category}</td>
                        <td className="px-6 py-4 text-right font-medium text-foreground">{event.venue_name || "TBD"}</td>
                    </tr>
                ))}
                {data.length === 0 && (
                    <tr>
                        <td colSpan={4} className="px-6 py-8 text-center text-muted-foreground">No recent events found.</td>
                    </tr>
                )}
            </tbody>
        </table>
      </CardContent>
    </Card>
  )
}
