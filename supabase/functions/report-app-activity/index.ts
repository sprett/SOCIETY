// SOCIETY - Report app activity with IP geolocation
// Deploy: supabase functions deploy report-app-activity
//
// Called by iOS app on launch/foreground. Updates last_app_open_at, last_seen_at,
// last_known_lat/lng (from IP), and logs to app_open_events.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function getClientIp(req: Request): string | null {
  const forwarded = req.headers.get("x-forwarded-for");
  if (forwarded) {
    const first = forwarded.split(",")[0]?.trim();
    if (first) return first;
  }
  const cf = req.headers.get("cf-connecting-ip");
  if (cf) return cf;
  const real = req.headers.get("x-real-ip");
  if (real) return real;
  return null;
}

async function geolookup(ip: string): Promise<{ lat: number; lon: number } | null> {
  const isPrivate =
    ip.startsWith("10.") ||
    ip.startsWith("172.16.") ||
    ip.startsWith("172.17.") ||
    ip.startsWith("172.18.") ||
    ip.startsWith("172.19.") ||
    ip.startsWith("172.2") ||
    ip.startsWith("172.30.") ||
    ip.startsWith("172.31.") ||
    ip.startsWith("192.168.") ||
    ip === "127.0.0.1" ||
    ip === "::1" ||
    ip.startsWith("fc") ||
    ip.startsWith("fd");
  if (isPrivate) return null;

  try {
    const url = `http://ip-api.com/json/${encodeURIComponent(ip)}?fields=status,lat,lon`;
    const res = await fetch(url, { signal: AbortSignal.timeout(3000) });
    if (!res.ok) return null;
    const data = (await res.json()) as { status?: string; lat?: number; lon?: number };
    if (data?.status === "success" && typeof data.lat === "number" && typeof data.lon === "number") {
      return { lat: data.lat, lon: data.lon };
    }
  } catch {
    // ignore
  }
  return null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST" && req.method !== "GET") {
    return new Response(JSON.stringify({ success: false, error: "method_not_allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ success: false, error: "unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
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
    data: { user },
    error: authErr,
  } = await authClient.auth.getUser();

  if (authErr || !user) {
    return new Response(JSON.stringify({ success: false, error: "unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey);
  let lat: number | null = null;
  let lon: number | null = null;

  // Prefer device location from request body (iOS sends this)
  try {
    const body = (await req.json().catch(() => ({}))) as { latitude?: number; longitude?: number };
    if (typeof body?.latitude === "number" && typeof body?.longitude === "number") {
      lat = body.latitude;
      lon = body.longitude;
    }
  } catch {
    // no body or invalid json
  }

  // Fallback to IP geolocation if no device location
  if (lat == null || lon == null) {
    const ip = getClientIp(req);
    if (ip) {
      const geo = await geolookup(ip);
      if (geo) {
        lat = geo.lat;
        lon = geo.lon;
      }
    }
  }

  const updates: Record<string, unknown> = {
    last_app_open_at: new Date().toISOString(),
    last_seen_at: new Date().toISOString(),
  };
  if (lat != null && lon != null) {
    updates.last_known_lat = lat;
    updates.last_known_lng = lon;
  }

  const { error: updateErr } = await admin
    .from("profiles")
    .update(updates)
    .eq("id", user.id);

  if (updateErr) {
    return new Response(
      JSON.stringify({ success: false, error: updateErr.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const { error: insertErr } = await admin.from("app_open_events").insert({
    user_id: user.id,
    opened_at: new Date().toISOString(),
  });

  if (insertErr) {
    return new Response(
      JSON.stringify({ success: false, error: insertErr.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
