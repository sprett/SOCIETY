// Mirrors the columns in supabase_events.sql
export interface EventRow {
  id: string;
  owner_id: string | null;
  title: string;
  category: string;
  about: string | null;
  start_at: string; // ISO timestamptz
  end_at: string | null;
  venue_name: string | null;
  address_line: string;
  neighborhood: string | null;
  latitude: number | null;
  longitude: number | null;
  image_url: string | null;
  is_featured: boolean;
  visibility: "public" | "private";
  created_at: string;
}
