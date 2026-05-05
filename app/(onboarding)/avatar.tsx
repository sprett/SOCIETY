import { Image } from "expo-image";
import { router, useLocalSearchParams } from "expo-router";
import { useMemo, useState } from "react";
import { ActivityIndicator, Alert, Pressable, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { buildDiceBearPngUrl } from "@/lib/avatar";
import { generateUsername } from "@/lib/usernameGen";
import { fetchProfile, updateProfile } from "@/services/profileService";
import { useAuthStore } from "@/stores/authStore";

export default function Avatar() {
  const { firstName, lastName } = useLocalSearchParams<{
    firstName?: string;
    lastName?: string;
  }>();
  const session = useAuthStore((s) => s.session);
  const setProfile = useAuthStore((s) => s.setProfile);
  const userId = session?.user.id;

  const [seedSuffix, setSeedSuffix] = useState(0);
  const [busy, setBusy] = useState(false);

  const seed = useMemo(() => {
    const base = userId ?? "anonymous";
    return seedSuffix === 0 ? base : `${base}-${seedSuffix}`;
  }, [userId, seedSuffix]);

  const avatarUrl = buildDiceBearPngUrl(seed);

  async function handleContinue() {
    if (!userId) {
      Alert.alert("Sign-in required", "Please sign in again.");
      return;
    }
    setBusy(true);
    try {
      const fullName = `${firstName ?? ""} ${lastName ?? ""}`.trim();
      const username = generateUsername(fullName);
      await updateProfile(userId, {
        first_name: firstName ?? null,
        last_name: lastName ?? null,
        full_name: fullName || null,
        username,
        avatar_url: avatarUrl,
        avatar_source: "dicebear",
        avatar_seed: seed,
        avatar_style: "notionists",
        onboarding_completed: true,
      });
      const fresh = await fetchProfile(userId);
      setProfile(fresh);
      // The launch gate at app/index will route to /(app)/discover automatically,
      // but since we navigated here via push, replace to root to re-evaluate.
      router.replace("/");
    } catch (err: any) {
      Alert.alert("Could not save profile", err?.message ?? String(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <SafeAreaView className="flex-1 bg-black" edges={["top"]}>
      <View className="px-6 pt-6 flex-1">
        <View className="h-1 bg-white/10 rounded-full mb-8 overflow-hidden">
          <View className="h-1 bg-white rounded-full" style={{ width: "100%" }} />
        </View>

        <Text className="text-white text-3xl font-bold">Pick your avatar</Text>
        <Text className="text-white/60 text-base mt-2">
          Tap shuffle until you find one you like.
        </Text>

        <View className="flex-1 items-center justify-center">
          <View className="w-56 h-56 rounded-full bg-white overflow-hidden items-center justify-center">
            <Image
              source={{ uri: avatarUrl }}
              style={{ width: "100%", height: "100%" }}
              contentFit="cover"
              transition={200}
            />
          </View>

          <Pressable
            onPress={() => setSeedSuffix((n) => n + 1)}
            className="mt-6 px-6 h-[44px] rounded-full bg-white/10 items-center justify-center"
          >
            <Text className="text-white font-medium text-base">Shuffle</Text>
          </Pressable>
        </View>

        <Pressable
          onPress={handleContinue}
          disabled={busy}
          className={`h-[52px] rounded-xl items-center justify-center mb-4 ${busy ? "bg-white/40" : "bg-white"}`}
        >
          {busy ? (
            <ActivityIndicator color="black" />
          ) : (
            <Text className="text-black font-semibold text-base">Continue</Text>
          )}
        </Pressable>
      </View>
    </SafeAreaView>
  );
}
