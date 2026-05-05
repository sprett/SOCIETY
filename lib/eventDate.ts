import { format, isToday, isTomorrow } from "date-fns";

// Mirrors EventDateFormatter.swift's compact display:
//   "Today · 19:00"  /  "Tomorrow · 19:00"  /  "Sat 8 Mar · 19:00"
export function formatEventStart(iso: string): string {
  const d = new Date(iso);
  const time = format(d, "HH:mm");
  if (isToday(d)) return `Today · ${time}`;
  if (isTomorrow(d)) return `Tomorrow · ${time}`;
  return `${format(d, "EEE d MMM")} · ${time}`;
}
