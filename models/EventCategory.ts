// Mirrors the columns in event_categories
export interface EventCategoryRow {
  id: string;
  name: string;
  icon_identifier: string;
  accent_color_hex: string | null;
  display_order: number;
}
