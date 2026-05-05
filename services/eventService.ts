import { supabase } from "@/lib/supabase";
import type { EventRow } from "@/models/Event";

// Mirrors SupabaseEventRepository.fetchEvents(): upcoming events only
// (end_at >= now AND start_at >= start-of-today), oldest start first.
export async function fetchUpcomingEvents(): Promise<EventRow[]> {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const { data, error } = await supabase
    .from("events")
    .select("*")
    .gte("end_at", now.toISOString())
    .gte("start_at", startOfToday.toISOString())
    .order("start_at", { ascending: true });
  if (error) throw error;
  return (data ?? []) as EventRow[];
}

export async function fetchEventById(id: string): Promise<EventRow | null> {
  const { data, error } = await supabase
    .from("events")
    .select("*")
    .eq("id", id)
    .maybeSingle();
  if (error) throw error;
  return (data as EventRow | null) ?? null;
}
