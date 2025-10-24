// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let sessionId: string | undefined;
  
  try {
    const body = await req.json();
    sessionId = body.sessionId;
    const openaiKey = Deno.env.get("OPENAI_API_KEY");

    if (!openaiKey) {
      throw new Error("OPENAI_API_KEY not configured");
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    console.log(`Analyzing session: ${sessionId}`);

    // Get session
    const { data: session, error: sessionError } = await supabase
      .from("sessions")
      .select("*")
      .eq("id", sessionId)
      .single();

    if (sessionError || !session) {
      console.error("Session not found:", sessionError);
      throw new Error("Session not found");
    }

    // Download video from storage
    console.log(`Downloading video: ${session.video_path}`);
    const { data: videoBlob, error: downloadError } = await supabase.storage
      .from("videos")
      .download(session.video_path);

    if (downloadError || !videoBlob) {
      console.error("Video download failed:", downloadError);
      throw (downloadError ?? new Error("Video missing"));
    }

    console.log(`Video downloaded: ${videoBlob.size} bytes`);

    // Update progress - Audio transcription starting
    await supabase.from("sessions").update({ progress: 0.2 }).eq("id", sessionId);

    // Step 1: Transcribe audio with Whisper
    console.log("Calling Whisper API for audio transcription...");
    
    // Check file size (Whisper has 25MB limit)
    const fileSizeMB = videoBlob.size / (1024 * 1024);
    console.log(`Video file size: ${fileSizeMB.toFixed(2)} MB`);
    
    if (fileSizeMB > 25) {
      throw new Error(`Video file too large for Whisper API (${fileSizeMB.toFixed(2)} MB). Max: 25 MB`);
    }
    
    // Create a new Blob with explicit MP4 MIME type for Whisper API
    const mp4Blob = new Blob([videoBlob], { type: 'video/mp4' });
    
    const audioFormData = new FormData();
    audioFormData.append("file", mp4Blob, "video.mp4");
    audioFormData.append("model", "whisper-1");

    const transcriptResp = await fetch("https://api.openai.com/v1/audio/transcriptions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${openaiKey}` },
      body: audioFormData,
    });

    if (!transcriptResp.ok) {
      const errorText = await transcriptResp.text();
      console.error("Whisper API error:", transcriptResp.status, errorText);
      throw new Error(`Whisper API failed: ${errorText}`);
    }

    const transcriptData = await transcriptResp.json();
    const transcript = transcriptData.text || "";
    console.log(`Transcript (${transcript.length} chars): ${transcript.substring(0, 100)}...`);

    // Update progress - Video analysis starting
    await supabase.from("sessions").update({ progress: 0.4 }).eq("id", sessionId);

    // Step 2: Analyze transcript for filler words
    const fillerWords: Record<string, number> = {};
    const fillers = ["uh", "um", "like", "you know", "sort of", "kind of"];
    const lowerTranscript = transcript.toLowerCase();
    fillers.forEach((filler) => {
      const count = (lowerTranscript.match(new RegExp(`\\b${filler}\\b`, "g")) || []).length;
      if (count > 0) fillerWords[filler] = count;
    });
    console.log("Filler words detected:", fillerWords);

    // Step 3: Convert video to base64 for GPT-4o Vision analysis
    console.log("Converting video to base64 for vision analysis...");
    const arrayBuffer = await videoBlob.arrayBuffer();
    const base64Video = btoa(
      new Uint8Array(arrayBuffer).reduce((data, byte) => data + String.fromCharCode(byte), "")
    );
    
    // Update progress - AI analysis starting
    await supabase.from("sessions").update({ progress: 0.6 }).eq("id", sessionId);

    // Step 4: Use GPT-4o (with vision) to analyze the video
    console.log("Calling GPT-4o Vision API for video analysis...");
    const analysisPrompt = `You are an AI communication coach analyzing a person's self-presentation video.

**TRANSCRIPT:** "${transcript}"

**FILLER WORDS DETECTED:** ${JSON.stringify(fillerWords)}

Analyze BOTH the visual presentation (body language, eye contact, facial expressions, gestures) and the audio content (tone, confidence, clarity, filler words).

Provide a JSON response with:
{
  "confidenceScore": 0-100 (based on voice, posture, eye contact, gestures),
  "impressionTags": ["tag1", "tag2", "tag3", "tag4", "tag5"] (e.g., "confident", "friendly", "nervous", "engaging", "professional"),
  "toneTimeline": [
    {"t": 0, "energy": 0.0-1.0},
    {"t": 5, "energy": 0.0-1.0},
    {"t": 10, "energy": 0.0-1.0}
  ],
  "emotionBreakdown": {
    "joy": 0.0-1.0,
    "neutral": 0.0-1.0,
    "sad": 0.0-1.0,
    "angry": 0.0-1.0,
    "surprise": 0.0-1.0
  } (must sum to 1.0),
  "gazeEyeContactPct": 0.0-1.0 (estimate based on video),
  "feedback": "2-3 sentences of specific, actionable feedback on both visual presence and vocal delivery"
}

Return ONLY valid JSON, no markdown.`;

    const gptResp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${openaiKey}`,
      },
      body: JSON.stringify({
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: analysisPrompt },
              {
                type: "image_url",
                image_url: {
                  url: `data:video/mp4;base64,${base64Video}`,
                  detail: "low" // Use "low" for faster processing
                }
              }
            ]
          }
        ],
        max_tokens: 1000,
        temperature: 0.7,
      }),
    });

    if (!gptResp.ok) {
      const errorText = await gptResp.text();
      console.error("GPT-4o API error:", gptResp.status, errorText);
      throw new Error(`GPT-4o API failed: ${errorText}`);
    }

    const gptData = await gptResp.json();
    console.log("GPT-4o response received");
    
    let analysis;
    try {
      const content = gptData.choices[0].message.content;
      // Remove markdown code blocks if present
      const jsonMatch = content.match(/```(?:json)?\s*(\{[\s\S]*\})\s*```/);
      const jsonStr = jsonMatch ? jsonMatch[1] : content;
      analysis = JSON.parse(jsonStr);
      console.log("Analysis parsed successfully");
    } catch (parseError) {
      console.error("Failed to parse GPT response:", gptData.choices[0].message.content);
      throw new Error(`Failed to parse AI analysis: ${parseError}`);
    }

    // Update progress - Saving results
    await supabase.from("sessions").update({ progress: 0.9 }).eq("id", sessionId);

    // Step 5: Write analysis report
    console.log("Saving analysis report...");
    const { error: reportError } = await supabase
      .from("analysis_reports")
      .insert({
        session_id: sessionId,
        confidence_score: analysis.confidenceScore,
        impression_tags: analysis.impressionTags,
        filler_words: fillerWords,
        tone_timeline: analysis.toneTimeline,
        emotion_breakdown: analysis.emotionBreakdown,
        gaze_eye_contact_pct: analysis.gazeEyeContactPct,
        feedback: analysis.feedback,
      });

    if (reportError) {
      console.error("Failed to save report:", reportError);
      throw reportError;
    }

    // Step 6: Update session to complete
    await supabase
      .from("sessions")
      .update({ status: "complete", progress: 1.0 })
      .eq("id", sessionId);

    // Step 7: Delete video from storage
    console.log("Cleaning up video file...");
    await supabase.storage.from("videos").remove([session.video_path]);

    console.log(`Analysis complete for session: ${sessionId}`);
    return new Response(
      JSON.stringify({ success: true, sessionId }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error: any) {
    console.error("Analysis error:", error);
    console.error("Error stack:", error.stack);
    
    // Mark session as error if we have the sessionId
    if (sessionId) {
      try {
        const supabase = createClient(
          Deno.env.get("SUPABASE_URL") ?? "",
          Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
        );
        await supabase
          .from("sessions")
          .update({ status: "error", error_message: error.message })
          .eq("id", sessionId);
      } catch (updateError) {
        console.error("Failed to update session error status:", updateError);
      }
    }

    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
