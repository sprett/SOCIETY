import { Ionicons } from "@expo/vector-icons";
import { Image } from "expo-image";
import { Stack, router, useLocalSearchParams } from "expo-router";
import { useEffect, useState } from "react";
import {
  ActivityIndicator,
  Linking,
  Pressable,
  ScrollView,
  Text,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { formatEventStart } from "@/lib/eventDate";
import type { EventRow } from "@/models/Event";
import { fetchEventById } from "@/services/eventService";

export default function EventDetail() {
  const { eventId } = useLocalSearchParams<{ eventId: string }>();
  const [event, setEvent] = useState<EventRow | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!eventId) return;
    setLoading(true);
    fetchEventById(eventId)
      .then(setEvent)
      .catch((err) => setError(err?.message ?? String(err)))
      .finally(() => setLoading(false));
  }, [eventId]);

  function openInMaps() {
    if (!event) return;
    const q = encodeURIComponent(event.address_line ?? event.venue_name ?? "");
    Linking.openURL(`http://maps.apple.com/?q=${q}`);
  }

  return (
    <SafeAreaView className="flex-1 bg-black" edges={["top"]}>
      <Stack.Screen options={{ headerShown: false }} />
      <View className="px-5 py-3 flex-row items-center justify-between">
        <Pressable
          onPress={() => router.back()}
          hitSlop={12}
          className="w-10 h-10 rounded-full bg-white/10 items-center justify-center"
        >
          <Ionicons name="chevron-back" size={22} color="white" />
        </Pressable>
        <View className="w-10" />
      </View>

      {loading ? (
        <View className="flex-1 items-center justify-center">
          <ActivityIndicator color="white" />
        </View>
      ) : error ? (
        <View className="flex-1 items-center justify-center px-6">
          <Text className="text-red-400 text-center">{error}</Text>
        </View>
      ) : !event ? (
        <View className="flex-1 items-center justify-center">
          <Text className="text-white/60">Event not found.</Text>
        </View>
      ) : (
        <ScrollView contentContainerStyle={{ paddingBottom: 32 }}>
          {event.image_url ? (
            <Image
              source={{ uri: event.image_url }}
              style={{ width: "100%", height: 280 }}
              contentFit="cover"
              transition={200}
            />
          ) : (
            <View className="w-full h-[280px] bg-white/10 items-center justify-center">
              <Text className="text-white/40">{event.category}</Text>
            </View>
          )}

          <View className="px-5 pt-5 gap-2">
            <Text className="text-white/60 text-xs uppercase tracking-wider">
              {formatEventStart(event.start_at)}
            </Text>
            <Text className="text-white text-2xl font-bold">{event.title}</Text>
            <Text className="text-white/60 text-base">
              {event.venue_name ? `${event.venue_name}` : ""}
              {event.neighborhood ? ` · ${event.neighborhood}` : ""}
            </Text>
          </View>

          {event.about ? (
            <View className="px-5 pt-6">
              <Text className="text-white/80 text-base leading-6">{event.about}</Text>
            </View>
          ) : null}

          <View className="px-5 pt-6">
            <Pressable
              onPress={openInMaps}
              className="bg-white/10 rounded-xl p-4 flex-row items-center gap-3"
            >
              <Ionicons name="location-outline" size={20} color="white" />
              <Text className="text-white text-base flex-1">{event.address_line}</Text>
              <Ionicons name="chevron-forward" size={18} color="rgba(255,255,255,0.4)" />
            </Pressable>
          </View>
        </ScrollView>
      )}
    </SafeAreaView>
  );
}
