import { Redirect } from "expo-router";
import { ActivityIndicator, View } from "react-native";
import { useAuthStore } from "@/stores/authStore";

export default function Index() {
  const { session, initializing } = useAuthStore();

  if (initializing) {
    return (
      <View className="flex-1 items-center justify-center bg-black">
        <ActivityIndicator color="white" />
      </View>
    );
  }

  return <Redirect href={session ? "/(app)/discover" : "/(auth)/welcome"} />;
}
