import "../global.css";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import * as Linking from "expo-linking";
import { useEffect } from "react";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { supabase } from "@/lib/supabase";
import { createSessionFromUrl } from "@/services/authService";
import { fetchProfile } from "@/services/profileService";
import { useAuthStore } from "@/stores/authStore";

export default function RootLayout() {
  const url = Linking.useURL();

  useEffect(() => {
    const { setSession, setInitializing } = useAuthStore.getState();
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setInitializing(false);
    });

    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
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

  useEffect(() => {
    if (!url) return;
    createSessionFromUrl(url).catch((err) => {
      console.warn("Failed to create session from deep link", err);
    });
  }, [url]);

  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: "#000" } }} />
    </SafeAreaProvider>
  );
}
