import { Stack, router } from "expo-router";
import { useState } from "react";
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  Text,
  TextInput,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { signInWithEmail, signUpWithEmail } from "@/services/authService";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState<"signin" | "signup" | null>(null);
  const [error, setError] = useState<string | null>(null);

  const canSubmit = email.includes("@") && password.length >= 6 && busy === null;

  async function handle(action: "signin" | "signup") {
    setError(null);
    try {
      setBusy(action);
      if (action === "signin") {
        await signInWithEmail(email.trim(), password);
      } else {
        await signUpWithEmail(email.trim(), password);
        Alert.alert(
          "Check your inbox",
          "We sent a confirmation link to " + email.trim() + ".",
        );
      }
    } catch (err: any) {
      setError(err?.message ?? String(err));
    } finally {
      setBusy(null);
    }
  }

  return (
    <SafeAreaView className="flex-1 bg-black" edges={["top"]}>
      <Stack.Screen options={{ headerShown: false }} />
      <View className="flex-row items-center justify-between px-5 py-3">
        <View className="w-12" />
        <Pressable onPress={() => router.back()} hitSlop={12}>
          <Text className="text-white text-base">Close</Text>
        </Pressable>
      </View>

      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        className="flex-1"
      >
        <ScrollView
          contentContainerClassName="px-5 pt-6 pb-8"
          keyboardShouldPersistTaps="handled"
        >
          <Text className="text-white text-3xl font-bold">Sign in</Text>
          <Text className="text-white/40 text-sm mt-2">Create and manage your events.</Text>

          <View className="mt-6 gap-3">
            <TextInput
              value={email}
              onChangeText={setEmail}
              placeholder="Email"
              placeholderTextColor="#888"
              autoCapitalize="none"
              autoComplete="email"
              keyboardType="email-address"
              textContentType="emailAddress"
              className="bg-white/10 text-white rounded-xl px-4 py-4 text-base"
            />
            <TextInput
              value={password}
              onChangeText={setPassword}
              placeholder="Password"
              placeholderTextColor="#888"
              secureTextEntry
              autoComplete="password"
              textContentType="password"
              className="bg-white/10 text-white rounded-xl px-4 py-4 text-base"
            />
          </View>

          {error ? <Text className="text-red-400 text-sm mt-3">{error}</Text> : null}

          <View className="mt-5 gap-3">
            <Pressable
              onPress={() => handle("signin")}
              disabled={!canSubmit}
              className={`h-[52px] rounded-xl items-center justify-center flex-row ${canSubmit ? "bg-white" : "bg-white/40"}`}
            >
              {busy === "signin" ? (
                <ActivityIndicator color="black" />
              ) : (
                <Text className="text-black font-semibold text-base">Sign in</Text>
              )}
            </Pressable>

            <Pressable
              onPress={() => handle("signup")}
              disabled={!canSubmit}
              className="h-[52px] rounded-xl items-center justify-center border border-white/20 bg-white/5"
            >
              {busy === "signup" ? (
                <ActivityIndicator color="white" />
              ) : (
                <Text className="text-white font-semibold text-base">Create account</Text>
              )}
            </Pressable>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
