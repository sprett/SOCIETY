import { Pressable, Text } from "react-native";

interface Props {
  title: string;
  selected: boolean;
  onPress: () => void;
}

export function CategoryChip({ title, selected, onPress }: Props) {
  return (
    <Pressable
      onPress={onPress}
      className={`px-4 h-9 rounded-full items-center justify-center ${selected ? "bg-white" : "bg-white/10"}`}
    >
      <Text className={`text-sm font-medium ${selected ? "text-black" : "text-white"}`}>
        {title}
      </Text>
    </Pressable>
  );
}
