import { supabase } from "@/lib/supabase";
import type { EventCategoryRow } from "@/models/EventCategory";

export async function fetchCategories(): Promise<EventCategoryRow[]> {
  const { data, error } = await supabase
    .from("event_categories")
    .select("*")
    .order("display_order", { ascending: true });
  if (error) throw error;
  return (data ?? []) as EventCategoryRow[];
}

export async function fetchUserInterests(userId: string): Promise<Set<string>> {
  const { data, error } = await supabase
    .from("profile_interests")
    .select("category_id")
    .eq("user_id", userId);
  if (error) throw error;
  return new Set((data ?? []).map((row) => row.category_id as string));
}

export async function saveUserInterests(userId: string, categoryIds: string[]): Promise<void> {
  const del = await supabase.from("profile_interests").delete().eq("user_id", userId);
  if (del.error) throw del.error;
  if (categoryIds.length === 0) return;
  const inserts = categoryIds.map((category_id) => ({ user_id: userId, category_id }));
  const { error } = await supabase.from("profile_interests").insert(inserts);
  if (error) throw error;
}
