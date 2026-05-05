import Constants, { ExecutionEnvironment } from "expo-constants";
import * as AppleAuthentication from "expo-apple-authentication";
import { makeRedirectUri } from "expo-auth-session";
import * as QueryParams from "expo-auth-session/build/QueryParams";
import * as WebBrowser from "expo-web-browser";
import { Platform } from "react-native";
import { supabase } from "@/lib/supabase";

WebBrowser.maybeCompleteAuthSession();

export const isExpoGo = Constants.executionEnvironment === ExecutionEnvironment.StoreClient;

// In a dev client / standalone build this resolves to dinoh.society://auth/callback.
// In Expo Go it resolves to exp://<lan-ip>:8081/--/auth/callback — that exact URL must
// be added to Supabase Dashboard → Authentication → URL Configuration → Redirect URLs.
export const oauthRedirectUrl = makeRedirectUri({
  scheme: "dinoh.society",
  path: "auth/callback",
});

if (__DEV__) {
  // eslint-disable-next-line no-console
  console.log("[auth] OAuth redirect URL:", oauthRedirectUrl);
}

export async function createSessionFromUrl(url: string) {
  const { params, errorCode } = QueryParams.getQueryParams(url);
  if (errorCode) throw new Error(errorCode);
  const { access_token, refresh_token } = params;
  if (!access_token || !refresh_token) return null;
  const { data, error } = await supabase.auth.setSession({
    access_token,
    refresh_token,
  });
  if (error) throw error;
  return data.session;
}

export async function signInWithGoogle() {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: oauthRedirectUrl,
      skipBrowserRedirect: true,
    },
  });
  if (error) throw error;
  if (!data?.url) throw new Error("Supabase did not return an OAuth URL");

  const result = await WebBrowser.openAuthSessionAsync(data.url, oauthRedirectUrl);
  if (result.type === "success") {
    const session = await createSessionFromUrl(result.url);
    if (!session) {
      throw new Error(
        "OAuth callback returned no tokens. Make sure '" +
          oauthRedirectUrl +
          "' is in Supabase → Authentication → URL Configuration → Redirect URLs.",
      );
    }
    return session;
  }
  if (result.type === "cancel" || result.type === "dismiss") {
    return null;
  }
  throw new Error("OAuth flow ended with type: " + result.type);
}

export async function signInWithApple() {
  if (Platform.OS !== "ios") {
    throw new Error("Apple Sign In is iOS only");
  }
  if (isExpoGo) {
    throw new Error(
      "Apple Sign In does not work in Expo Go (Apple's id_token is bound to bundle id 'host.exp.Exponent'). Build a dev client: `eas build --profile development --platform ios`.",
    );
  }
  const credential = await AppleAuthentication.signInAsync({
    requestedScopes: [
      AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
      AppleAuthentication.AppleAuthenticationScope.EMAIL,
    ],
  });
  if (!credential.identityToken) {
    throw new Error("Apple Sign In returned no identity token");
  }
  const { data, error } = await supabase.auth.signInWithIdToken({
    provider: "apple",
    token: credential.identityToken,
  });
  if (error) throw error;
  return data.session;
}

export async function signInWithEmail(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data.session;
}

export async function signUpWithEmail(email: string, password: string) {
  const { data, error } = await supabase.auth.signUp({ email, password });
  if (error) throw error;
  return data.session;
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}
