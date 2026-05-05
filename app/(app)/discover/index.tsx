import { Pressable, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useAuthStore } from "@/stores/authStore";

export default function Discover() {
  const profile = useAuthStore((s) => s.profile);
  const signOut = useAuthStore((s) => s.signOut);

  return (
    <SafeAreaView className="flex-1 bg-black">
      <View className="flex-1 items-center justify-center px-6 gap-3">
        <Text className="text-white text-2xl font-semibold">Discover</Text>
        {profile && (
          <Text className="text-white/60 text-base">
            Signed in as {profile.username ?? profile.full_name ?? "you"}
          </Text>
        )}
        <Pressable
          onPress={() => signOut()}
          className="mt-6 px-6 h-[44px] rounded-full border border-white/20 items-center justify-center"
        >
          <Text className="text-white text-sm">Sign out</Text>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}
