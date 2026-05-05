module.exports = function (api) {
  api.cache(true);
  return {
    presets: [
      ["babel-preset-expo", { jsxImportSource: "nativewind" }],
      "nativewind/babel",
    ],
    plugins: [
      // Reanimated v4 / Worklets plugin must be listed LAST.
      "react-native-worklets/plugin",
    ],
  };
};
