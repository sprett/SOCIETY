import { Redirect, Stack } from "expo-router";
import { useAuthStore } from "@/stores/authStore";

export default function OnboardingLayout() {
  const session = useAuthStore((s) => s.session);
  const initializing = useAuthStore((s) => s.initializing);

  if (initializing) return null;
  if (!session) return <Redirect href="/" />;

  return <Stack screenOptions={{ headerShown: false }} />;
}
