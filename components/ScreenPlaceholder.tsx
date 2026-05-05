import { Text, View } from "react-native";

export function ScreenPlaceholder({ label }: { label: string }) {
  return (
    <View className="flex-1 items-center justify-center bg-black">
      <Text className="text-white text-lg">{label}</Text>
    </View>
  );
}
