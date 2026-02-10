// SOCIETY - Delete account Edge Function
// Removes the user's profile image, event cover images, then deletes the auth user.
// Run: supabase functions deploy delete-account
// Requires: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (set in Supabase Dashboard)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function pathFromPublicUrl(url: string, bucket: string): string | null {
  try {
    const u = new URL(url);
    const path = decodeURIComponent(u.pathname);
    const marker = `/${bucket}/`;
    const i = path.indexOf(marker);
    if (i === -1) return null;
    return path.slice(i + marker.length).replace(/^\/+/, "").trim() || null;
  } catch {
    return null;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return new Response(
      JSON.stringify({ error: "Missing or invalid Authorization header" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!serviceRoleKey) {
    return new Response(
      JSON.stringify({ error: "Server misconfiguration" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Create client with the request's Authorization so getUser() uses the user's JWT
  const authClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const {
    data: { user },
    error: userError,
  } = await authClient.auth.getUser();

  if (userError || !user) {
    return new Response(
      JSON.stringify({
        error: "Invalid or expired token",
        detail: userError?.message ?? "No user",
      }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const userId = user.id;
  const admin = createClient(supabaseUrl, serviceRoleKey);

  try {
    const { data: profile } = await admin
      .from("profiles")
      .select("avatar_url")
      .eq("id", userId)
      .maybeSingle();

    if (profile?.avatar_url) {
      const path = pathFromPublicUrl(profile.avatar_url, "profile-images");
      if (path) {
        await admin.storage.from("profile-images").remove([path]);
      }
    }

    const { data: events } = await admin
      .from("events")
      .select("id, image_url")
      .eq("owner_id", userId);

    for (const event of events ?? []) {
      if (event?.image_url) {
        const path = pathFromPublicUrl(event.image_url, "event-images");
        if (path) {
          await admin.storage.from("event-images").remove([path]);
        }
      }
    }

    const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
    if (deleteError) {
      return new Response(
        JSON.stringify({ error: deleteError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
