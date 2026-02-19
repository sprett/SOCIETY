// SOCIETY - Admin delete user Edge Function
// Deploy: supabase functions deploy admin-delete-user

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

function badRequest(message: string) {
  return new Response(JSON.stringify({ success: false, error: message }), {
    status: 400,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ success: false, error: "unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: { targetUserId?: string; expectedUsername?: string };
  try {
    body = await req.json();
  } catch {
    return badRequest("invalid_json");
  }

  const targetUserId = body.targetUserId?.trim();
  const expectedUsername = body.expectedUsername?.trim().toLowerCase();
  if (!targetUserId || !expectedUsername) {
    return badRequest("missing_target_or_username");
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!serviceRoleKey) {
    return new Response(JSON.stringify({ success: false, error: "server_misconfigured" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const authClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user: caller },
    error: callerErr,
  } = await authClient.auth.getUser();

  if (callerErr || !caller) {
    return new Response(JSON.stringify({ success: false, error: "unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey);

  const { data: callerProfile, error: roleErr } = await admin
    .from("profiles")
    .select("role")
    .eq("id", caller.id)
    .maybeSingle();

  if (roleErr || callerProfile?.role !== "admin") {
    return new Response(JSON.stringify({ success: false, error: "forbidden" }), {
      status: 403,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { data: targetProfile, error: targetErr } = await admin
    .from("profiles")
    .select("id, username, avatar_url")
    .eq("id", targetUserId)
    .maybeSingle();

  if (targetErr || !targetProfile) {
    return new Response(JSON.stringify({ success: false, error: "target_not_found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!targetProfile.username || targetProfile.username.trim().length === 0) {
    return new Response(JSON.stringify({ success: false, error: "missing_username" }), {
      status: 409,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const serverUsername = (targetProfile.username ?? "").trim().toLowerCase();
  if (!serverUsername || serverUsername !== expectedUsername) {
    return new Response(JSON.stringify({ success: false, error: "username_mismatch" }), {
      status: 409,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    if (targetProfile.avatar_url) {
      const path = pathFromPublicUrl(targetProfile.avatar_url, "profile-images");
      if (path) {
        await admin.storage.from("profile-images").remove([path]);
      }
    }

    const { data: events } = await admin
      .from("events")
      .select("id, image_url")
      .eq("owner_id", targetUserId);

    for (const event of events ?? []) {
      if (!event?.image_url) continue;
      const path = pathFromPublicUrl(event.image_url, "event-images");
      if (path) {
        await admin.storage.from("event-images").remove([path]);
      }
    }

    const { error: deleteErr } = await admin.auth.admin.deleteUser(targetUserId);
    if (deleteErr) {
      return new Response(JSON.stringify({ success: false, error: deleteErr.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({
        success: false,
        error: err instanceof Error ? err.message : "delete_failed",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
