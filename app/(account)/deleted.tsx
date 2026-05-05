import { Pressable, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useAuthStore } from "@/stores/authStore";

export default function AccountDeleted() {
  const signOut = useAuthStore((s) => s.signOut);

  return (
    <SafeAreaView className="flex-1 bg-black">
      <View className="flex-1 items-center justify-center px-6 gap-4">
        <Text className="text-white text-2xl font-semibold text-center">
          Your account has been deleted
        </Text>
        <Text className="text-white/60 text-base text-center">
          If you feel this is incorrect, please reach out to us at support@society.com.
        </Text>

        <Pressable
          onPress={() => signOut()}
          className="mt-6 h-[52px] w-full rounded-xl bg-white items-center justify-center"
        >
          <Text className="text-black font-semibold text-base">Create new account</Text>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}
