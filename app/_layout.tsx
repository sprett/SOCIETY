import "../global.css";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { useEffect } from "react";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { supabase } from "@/lib/supabase";
import { fetchProfile } from "@/services/profileService";
import { useAuthStore } from "@/stores/authStore";

export default function RootLayout() {
  useEffect(() => {
    const { setSession, setInitializing } = useAuthStore.getState();
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setInitializing(false);
    });

    const { data: listener } = supabase.auth.onAuthStateChange((event, session) => {
      if (__DEV__) console.log("[auth] onAuthStateChange:", event, !!session);
      setSession(session);
    });

    return () => {
      listener.subscription.unsubscribe();
    };
  }, []);

  // Whenever the session's user changes, reload the profile row.
  const userId = useAuthStore((s) => s.session?.user.id ?? null);
  useEffect(() => {
    const { setProfile, setProfileLoading } = useAuthStore.getState();
    if (!userId) {
      setProfile(null);
      setProfileLoading(false);
      return;
    }
    setProfileLoading(true);
    let cancelled = false;
    fetchProfile(userId)
      .then((profile) => {
        if (!cancelled) setProfile(profile);
      })
      .catch((err) => {
        console.warn("fetchProfile failed", err);
        if (!cancelled) setProfile(null);
      })
      .finally(() => {
        if (!cancelled) setProfileLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [userId]);

  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: "#000" } }} />
    </SafeAreaProvider>
  );
}
