import { router } from "expo-router";
import { useState } from "react";
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  Text,
  TextInput,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useAuthStore } from "@/stores/authStore";

export default function ProfileSetup() {
  const profile = useAuthStore((s) => s.profile);
  const [firstName, setFirstName] = useState(profile?.first_name ?? "");
  const [lastName, setLastName] = useState(profile?.last_name ?? "");
  const [busy, setBusy] = useState(false);

  const canContinue =
    firstName.trim().length >= 1 && lastName.trim().length >= 1 && !busy;

  function handleContinue() {
    setBusy(true);
    router.push({
      pathname: "/(onboarding)/avatar",
      params: { firstName: firstName.trim(), lastName: lastName.trim() },
    });
    setBusy(false);
  }

  return (
    <SafeAreaView className="flex-1 bg-black" edges={["top"]}>
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        className="flex-1"
      >
        <ScrollView
          contentContainerClassName="px-6 pt-6 pb-8 flex-1"
          keyboardShouldPersistTaps="handled"
        >
          <View className="h-1 bg-white/10 rounded-full mb-8 overflow-hidden">
            <View className="h-1 bg-white rounded-full" style={{ width: "50%" }} />
          </View>

          <Text className="text-white text-3xl font-bold">What's your name?</Text>
          <Text className="text-white/60 text-base mt-2">
            We'll use this on your profile and to suggest a username.
          </Text>

          <View className="mt-8 gap-3">
            <TextInput
              value={firstName}
              onChangeText={setFirstName}
              placeholder="First name"
              placeholderTextColor="#888"
              autoCapitalize="words"
              autoComplete="given-name"
              textContentType="givenName"
              className="bg-white/10 text-white rounded-xl px-4 py-4 text-base"
            />
            <TextInput
              value={lastName}
              onChangeText={setLastName}
              placeholder="Last name"
              placeholderTextColor="#888"
              autoCapitalize="words"
              autoComplete="family-name"
              textContentType="familyName"
              className="bg-white/10 text-white rounded-xl px-4 py-4 text-base"
            />
          </View>

          <View className="flex-1" />

          <Pressable
            onPress={handleContinue}
            disabled={!canContinue}
            className={`h-[52px] rounded-xl items-center justify-center mt-6 ${canContinue ? "bg-white" : "bg-white/40"}`}
          >
            {busy ? (
              <ActivityIndicator color="black" />
            ) : (
              <Text className="text-black font-semibold text-base">Continue</Text>
            )}
          </Pressable>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
