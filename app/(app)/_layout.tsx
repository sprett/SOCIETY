import { Tabs } from "expo-router";

export default function AppLayout() {
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
