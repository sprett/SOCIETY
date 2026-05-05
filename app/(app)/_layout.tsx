import { Redirect, Tabs } from "expo-router";
import { useAuthStore } from "@/stores/authStore";

export default function AppLayout() {
  const session = useAuthStore((s) => s.session);
  const initializing = useAuthStore((s) => s.initializing);

  if (initializing) return null;
  if (!session) return <Redirect href="/" />;

  return (
    <Tabs screenOptions={{ headerShown: false }}>
      <Tabs.Screen name="discover" options={{ title: "Discover" }} />
      <Tabs.Screen name="events" options={{ title: "Home" }} />
      <Tabs.Screen name="feed" options={{ title: "Feed" }} />
      <Tabs.Screen name="map" options={{ href: null }} />
      <Tabs.Screen name="profile" options={{ href: null }} />
    </Tabs>
  );
}
