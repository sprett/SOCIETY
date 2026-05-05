import { useLocalSearchParams } from "expo-router";
import { ScreenPlaceholder } from "@/components/ScreenPlaceholder";

export default function DiscoverEventDetail() {
  const { eventId } = useLocalSearchParams<{ eventId: string }>();
  return <ScreenPlaceholder label={`discover/event/${eventId}`} />;
}
