import { useLocalSearchParams } from "expo-router";
import { ScreenPlaceholder } from "@/components/ScreenPlaceholder";

export default function EventDetail() {
  const { eventId } = useLocalSearchParams<{ eventId: string }>();
  return <ScreenPlaceholder label={`events/${eventId}`} />;
}
