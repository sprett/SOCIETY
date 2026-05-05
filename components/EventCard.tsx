import { Image } from "expo-image";
import { Pressable, Text, View } from "react-native";
import { formatEventStart } from "@/lib/eventDate";
import type { EventRow } from "@/models/Event";

interface Props {
  event: EventRow;
  onPress: () => void;
}

export function EventCard({ event, onPress }: Props) {
  const subtitle = [event.venue_name, event.neighborhood].filter(Boolean).join(" · ");

  return (
    <Pressable onPress={onPress} className="rounded-2xl overflow-hidden bg-white/5">
      {event.image_url ? (
        <Image
          source={{ uri: event.image_url }}
          style={{ width: "100%", height: 180 }}
          contentFit="cover"
          transition={200}
        />
      ) : (
        <View className="w-full h-[180px] bg-white/10 items-center justify-center">
          <Text className="text-white/40 text-sm">{event.category}</Text>
        </View>
      )}

      <View className="px-4 py-3 gap-1">
        <Text className="text-white/60 text-xs uppercase tracking-wider">
          {formatEventStart(event.start_at)}
        </Text>
        <Text className="text-white text-lg font-semibold" numberOfLines={2}>
          {event.title}
        </Text>
        {subtitle ? (
          <Text className="text-white/60 text-sm" numberOfLines={1}>
            {subtitle}
          </Text>
        ) : null}
      </View>
    </Pressable>
  );
}
