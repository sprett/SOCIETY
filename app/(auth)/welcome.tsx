import * as AppleAuthentication from "expo-apple-authentication";
import { Link } from "expo-router";
import { useState } from "react";
import { ActivityIndicator, Alert, Image, Platform, Pressable, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { signInWithApple, signInWithGoogle } from "@/services/authService";

export default function Welcome() {
  const [busy, setBusy] = useState<"apple" | "google" | null>(null);

  async function handleApple() {
    try {
      setBusy("apple");
      await signInWithApple();
    } catch (err: any) {
      if (err?.code !== "ERR_REQUEST_CANCELED") {
        Alert.alert("Apple Sign In failed", err?.message ?? String(err));
      }
    } finally {
      setBusy(null);
    }
  }

  async function handleGoogle() {
    try {
      setBusy("google");
      await signInWithGoogle();
    } catch (err: any) {
      Alert.alert("Google Sign In failed", err?.message ?? String(err));
    } finally {
      setBusy(null);
    }
  }

  return (
    <SafeAreaView className="flex-1 bg-black">
      <View className="flex-1 items-center justify-center px-8">
        <Image
          source={require("../../assets/icon.png")}
          className="w-28 h-28 rounded-3xl mb-6"
          resizeMode="cover"
        />
        <Text className="text-white text-5xl font-bold mb-2">SOCIETY</Text>
        <Text className="text-white/60 text-base mb-16">Discover events near you.</Text>
      </View>

      <View className="px-8 pb-12 gap-3">
        {Platform.OS === "ios" && (
          <AppleAuthentication.AppleAuthenticationButton
            buttonType={AppleAuthentication.AppleAuthenticationButtonType.SIGN_IN}
            buttonStyle={AppleAuthentication.AppleAuthenticationButtonStyle.WHITE}
            cornerRadius={12}
            style={{ width: "100%", height: 52 }}
            onPress={handleApple}
          />
        )}

        <Pressable
          onPress={handleGoogle}
          disabled={busy !== null}
          className="h-[52px] rounded-xl bg-white items-center justify-center flex-row"
        >
          {busy === "google" ? (
            <ActivityIndicator color="black" />
          ) : (
            <Text className="text-black font-semibold text-base">Continue with Google</Text>
          )}
        </Pressable>

        <Link href="/(auth)/login" asChild>
          <Pressable className="h-[44px] items-center justify-center">
            <Text className="text-white/70 text-sm">Sign in with email</Text>
          </Pressable>
        </Link>

        {busy === "apple" && (
          <View className="absolute inset-0 items-center justify-center">
            <ActivityIndicator color="white" />
          </View>
        )}
      </View>
    </SafeAreaView>
  );
}
