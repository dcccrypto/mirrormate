// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { checkAndRecordRateLimit, RATE_LIMITS } from "../_shared/rateLimiter.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Extract user from JWT if present
    const authHeader = req.headers.get("Authorization");
    let userId = null;
    
    if (authHeader && authHeader.startsWith("Bearer ")) {
      const token = authHeader.replace("Bearer ", "");
      // Create a client with the user's token to verify auth
      const userSupabase = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_ANON_KEY") ?? "",
        { global: { headers: { Authorization: authHeader } } }
      );
      
      const { data: { user } } = await userSupabase.auth.getUser();
      if (user) {
        userId = user.id;
        console.log("Authenticated user session:", userId);
      }
    }

    const { maxDurationSec, deviceId } = await req.json();

    // Check rate limiting for authenticated users
    if (userId) {
      const rateLimitResult = await checkAndRecordRateLimit(
        supabase,
        userId,
        RATE_LIMITS.INIT_SESSION
      );
      
      if (!rateLimitResult.allowed) {
        console.log(`Rate limit exceeded for user ${userId}, action: init_session`);
        return new Response(
          JSON.stringify({ 
            error: 'Rate limit exceeded. Please try again in a few minutes.',
            remaining: rateLimitResult.remaining
          }),
          { 
            status: 429, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        );
      }
    }

    // Create session record
    const { data: session, error: sessionError } = await supabase
      .from("sessions")
      .insert({
        user_id: userId,
        device_id: deviceId || null,
        duration_sec: maxDurationSec || 60,
        status: "queued",
      })
      .select()
      .single();

    if (sessionError) throw sessionError;

    // Generate signed upload URL for video (use .mp4 for Whisper API compatibility)
    const videoPath = `${session.id}.mp4`;
    const { data: signedUrl, error: urlError } = await supabase.storage
      .from("videos")
      .createSignedUploadUrl(videoPath);

    if (urlError) throw urlError;

    // Update session with video path
    await supabase
      .from("sessions")
      .update({ video_path: videoPath })
      .eq("id", session.id);

    return new Response(
      JSON.stringify({
        sessionId: session.id,
        uploadUrl: signedUrl.signedUrl,
        uploadPath: videoPath,
        uploadToken: signedUrl.token,
        expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});

