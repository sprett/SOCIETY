import { Redirect, Stack } from "expo-router";
import { useAuthStore } from "@/stores/authStore";

// Outer Stack so non-tab routes (map, profile, profile/edit/*,
// profile/settings/*) can be pushed on top of the tab bar without
// becoming siblings of the tab screens. The (tabs) child group owns
// the Tabs UI itself.
export default function AppLayout() {
  const session = useAuthStore((s) => s.session);
  const initializing = useAuthStore((s) => s.initializing);

  if (initializing) return null;
  if (!session) return <Redirect href="/" />;

  return <Stack screenOptions={{ headerShown: false }} />;
}
