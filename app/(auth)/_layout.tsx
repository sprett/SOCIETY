import { Redirect, Stack } from "expo-router";
import { useAuthStore } from "@/stores/authStore";

export default function AuthLayout() {
  const session = useAuthStore((s) => s.session);
  const initializing = useAuthStore((s) => s.initializing);

  if (initializing) return null;
  // If a session arrives while we're on a (auth) screen, kick back to "/"
  // and let the launch gate route to onboarding or the app.
  if (session) return <Redirect href="/" />;

  return <Stack screenOptions={{ headerShown: false }} />;
}
