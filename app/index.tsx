import { Redirect } from "expo-router";
import { ActivityIndicator, View } from "react-native";
import { deriveLaunchState } from "@/lib/launchState";
import { useAuthStore } from "@/stores/authStore";

export default function Index() {
  const { session, profile, initializing, profileLoading } = useAuthStore();
  const state = deriveLaunchState({ initializing, profileLoading, session, profile });

  switch (state) {
    case "loading":
      return (
        <View className="flex-1 items-center justify-center bg-black">
          <ActivityIndicator color="white" />
        </View>
      );
    case "unauthenticated":
      return <Redirect href="/(auth)/welcome" />;
    case "onboardingRequired":
      return <Redirect href="/(onboarding)/profile-setup" />;
    case "accountDeleted":
      return <Redirect href="/(account)/deleted" />;
    case "accountDisabled":
      return <Redirect href="/(account)/disabled" />;
    case "authenticatedReady":
      return <Redirect href="/(app)/discover" />;
  }
}
