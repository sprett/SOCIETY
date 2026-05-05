import { Link, Stack } from "expo-router";
import { Text, View } from "react-native";

export default function NotFound() {
  return (
    <>
      <Stack.Screen options={{ title: "Not found" }} />
      <View className="flex-1 items-center justify-center bg-black">
        <Text className="text-white text-lg mb-4">This screen doesn't exist.</Text>
        <Link href="/" className="text-white underline">
          Go home
        </Link>
      </View>
    </>
  );
}
