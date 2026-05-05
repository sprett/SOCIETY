import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  RefreshControl,
  ScrollView,
  Text,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { CategoryChip } from "@/components/CategoryChip";
import { EventCard } from "@/components/EventCard";
import type { EventRow } from "@/models/Event";
import type { EventCategoryRow } from "@/models/EventCategory";
import { fetchCategories } from "@/services/categoryService";
import { fetchUpcomingEvents } from "@/services/eventService";
import { useAuthStore } from "@/stores/authStore";

const ALL = "All";

export default function Discover() {
  const profile = useAuthStore((s) => s.profile);
  const signOut = useAuthStore((s) => s.signOut);

  const [events, setEvents] = useState<EventRow[]>([]);
  const [categories, setCategories] = useState<EventCategoryRow[]>([]);
  const [selected, setSelected] = useState<string>(ALL);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      const [evts, cats] = await Promise.all([fetchUpcomingEvents(), fetchCategories()]);
      setEvents(evts);
      setCategories(cats);
    } catch (err: any) {
      setError(err?.message ?? String(err));
    }
  }, []);

  useEffect(() => {
    setLoading(true);
    load().finally(() => setLoading(false));
  }, [load]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await load();
    setRefreshing(false);
  }, [load]);

  const filtered = useMemo(() => {
    if (selected === ALL) return events;
    return events.filter((e) => e.category === selected);
  }, [events, selected]);

  return (
    <SafeAreaView className="flex-1 bg-black" edges={["top"]}>
      <View className="px-5 pt-2 pb-3 flex-row items-center justify-between">
        <Text className="text-white text-3xl font-bold">Discover</Text>
        <Pressable
          onPress={() => signOut()}
          hitSlop={12}
          className="w-10 h-10 rounded-full bg-white/10 items-center justify-center"
        >
          <Ionicons name="log-out-outline" size={20} color="white" />
        </Pressable>
      </View>

      {profile ? (
        <Text className="px-5 text-white/40 text-xs mb-2">
          @{profile.username ?? profile.full_name ?? "you"}
        </Text>
      ) : null}

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerClassName="px-5 gap-2"
        className="max-h-12 mb-3"
      >
        <CategoryChip title={ALL} selected={selected === ALL} onPress={() => setSelected(ALL)} />
        {categories.map((cat) => (
          <CategoryChip
            key={cat.id}
            title={cat.name}
            selected={selected === cat.name}
            onPress={() => setSelected(cat.name)}
          />
        ))}
      </ScrollView>

      {loading ? (
        <View className="flex-1 items-center justify-center">
          <ActivityIndicator color="white" />
        </View>
      ) : error ? (
        <View className="flex-1 items-center justify-center px-6">
          <Text className="text-red-400 text-center mb-3">{error}</Text>
          <Pressable
            onPress={onRefresh}
            className="px-5 h-10 rounded-full bg-white/10 items-center justify-center"
          >
            <Text className="text-white">Retry</Text>
          </Pressable>
        </View>
      ) : (
        <FlatList
          data={filtered}
          keyExtractor={(e) => e.id}
          renderItem={({ item }) => (
            <EventCard
              event={item}
              onPress={() => router.push(`/(app)/discover/${item.id}`)}
            />
          )}
          contentContainerStyle={{ padding: 20, paddingTop: 4, gap: 16 }}
          ListEmptyComponent={
            <View className="items-center justify-center py-16">
              <Text className="text-white/60 text-base">
                {selected === ALL ? "No upcoming events." : `No events in ${selected}.`}
              </Text>
            </View>
          }
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor="white"
            />
          }
        />
      )}
    </SafeAreaView>
  );
}
