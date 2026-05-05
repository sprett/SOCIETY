import { Linking, Pressable, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useAuthStore } from "@/stores/authStore";

export default function AccountDisabled() {
  const signOut = useAuthStore((s) => s.signOut);

  return (
    <SafeAreaView className="flex-1 bg-black">
      <View className="flex-1 items-center justify-center px-6 gap-4">
        <Text className="text-white text-2xl font-semibold text-center">
          Account unavailable
        </Text>
        <Text className="text-white/60 text-base text-center">
          Your account is disabled.
        </Text>

        <View className="w-full mt-6 gap-3">
          <Pressable
            onPress={() => signOut()}
            className="h-[52px] rounded-xl bg-white items-center justify-center"
          >
            <Text className="text-black font-semibold text-base">Sign out</Text>
          </Pressable>

          <Pressable
            onPress={() => Linking.openURL("mailto:support@society.com")}
            className="h-[44px] items-center justify-center"
          >
            <Text className="text-white/70 text-base">Contact support</Text>
          </Pressable>
        </View>
      </View>
    </SafeAreaView>
  );
}
