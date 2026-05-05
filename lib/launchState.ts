import type { Session } from "@supabase/supabase-js";
import type { UserProfile } from "@/models/UserProfile";

export type LaunchState =
  | "loading"
  | "unauthenticated"
  | "onboardingRequired"
  | "authenticatedReady"
  | "accountDeleted"
  | "accountDisabled";

export interface LaunchInputs {
  initializing: boolean;
  profileLoading: boolean;
  session: Session | null;
  profile: UserProfile | null;
}

export function deriveLaunchState({
  initializing,
  profileLoading,
  session,
  profile,
}: LaunchInputs): LaunchState {
  if (initializing) return "loading";
  if (!session) return "unauthenticated";
  if (profileLoading) return "loading";
  if (!profile) return "accountDeleted";
  if (!profile.is_active || profile.deleted_at) return "accountDisabled";
  if (!profile.onboarding_completed) return "onboardingRequired";
  return "authenticatedReady";
}
