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
    const geminiKey = Deno.env.get("GEMINI_API_KEY");

    if (!geminiKey) {
      throw new Error("GEMINI_API_KEY not configured");
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    console.log(`Analyzing session with Gemini: ${sessionId}`);

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

    const videoSizeBytes = videoBlob.size;
    console.log(`Video downloaded: ${videoSizeBytes} bytes`);

    // Check file size (Gemini has 20MB limit for inline upload)
    const fileSizeMB = videoSizeBytes / (1024 * 1024);
    console.log(`Video file size: ${fileSizeMB.toFixed(2)} MB`);
    
    if (fileSizeMB > 20) {
      throw new Error(`Video file too large for Gemini API (${fileSizeMB.toFixed(2)} MB). Max: 20 MB`);
    }

    // Extract actual video duration using ffprobe-like approach
    // For Edge Function, we'll use Gemini's ability to analyze video duration
    // For now, use file size estimation but improve it
    const estimatedDurationSec = Math.round(videoSizeBytes / 200000);
    console.log(`Estimated video duration: ${estimatedDurationSec} seconds`);
    
    // Store estimated duration in session for reference
    await supabase.from("sessions").update({ 
      duration_sec: estimatedDurationSec 
    }).eq("id", sessionId);

    // Update progress - Uploading to Gemini
    await supabase.from("sessions").update({ progress: 0.2 }).eq("id", sessionId);

    console.log("Uploading video to Gemini Files API...");
    
    // Convert video blob to Uint8Array for binary upload
    const arrayBuffer = await videoBlob.arrayBuffer();
    const videoBytes = new Uint8Array(arrayBuffer);
    
    // Create proper multipart/related request
    const boundary = "==boundary==" + Math.random().toString(36).substring(2);
    
    // Metadata part (JSON)
    const metadata = JSON.stringify({
      file: {
        display_name: session.video_path,
      }
    });
    
    // Build multipart body manually
    const encoder = new TextEncoder();
    const metadataPart = encoder.encode(
      `--${boundary}\r\n` +
      `Content-Type: application/json; charset=UTF-8\r\n\r\n` +
      `${metadata}\r\n`
    );
    
    const filePart = encoder.encode(
      `--${boundary}\r\n` +
      `Content-Type: video/mp4\r\n\r\n`
    );
    
    const endBoundary = encoder.encode(`\r\n--${boundary}--\r\n`);
    
    // Combine all parts
    const requestBody = new Uint8Array(
      metadataPart.length + filePart.length + videoBytes.length + endBoundary.length
    );
    requestBody.set(metadataPart, 0);
    requestBody.set(filePart, metadataPart.length);
    requestBody.set(videoBytes, metadataPart.length + filePart.length);
    requestBody.set(endBoundary, metadataPart.length + filePart.length + videoBytes.length);
    
    // Upload file to Gemini Files API
    const uploadResp = await fetch(
      `https://generativelanguage.googleapis.com/upload/v1beta/files?key=${geminiKey}`,
      {
        method: "POST",
        headers: {
          "Content-Type": `multipart/related; boundary=${boundary}`,
          "X-Goog-Upload-Protocol": "multipart",
        },
        body: requestBody,
      }
    );

    if (!uploadResp.ok) {
      const errorText = await uploadResp.text();
      console.error("Gemini upload error:", uploadResp.status, errorText);
      throw new Error(`Gemini upload failed: ${errorText}`);
    }

    const uploadData = await uploadResp.json();
    const fileUri = uploadData.file.uri;
    console.log(`Video uploaded to Gemini: ${fileUri}`);

    // Update progress - AI analysis starting
    await supabase.from("sessions").update({ progress: 0.4 }).eq("id", sessionId);

    // Wait for file to be ready (Gemini processes videos asynchronously)
    let fileReady = false;
    let attempts = 0;
    while (!fileReady && attempts < 10) {
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      const checkResp = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/${fileUri.replace('https://generativelanguage.googleapis.com/v1beta/', '')}?key=${geminiKey}`
      );
      
      if (checkResp.ok) {
        const checkData = await checkResp.json();
        if (checkData.state === "ACTIVE") {
          fileReady = true;
          console.log("Video processed and ready for analysis");
        }
      }
      attempts++;
    }

    if (!fileReady) {
      throw new Error("Gemini video processing timeout");
    }

    // Update progress - Generating analysis
    await supabase.from("sessions").update({ progress: 0.6 }).eq("id", sessionId);

    // Call Gemini API with video - ENHANCED WITH ADVANCED PROMPTING
    console.log("Calling Gemini 2.5 Flash for comprehensive video analysis...");
    
    // Chain-of-Thought + Few-Shot + Structured Output Prompting
    const analysisPrompt = `You are an expert communication coach with 20 years of experience analyzing presentations, interviews, and public speaking. You've coached Fortune 500 executives, TED speakers, and professional communicators.

🎯 YOUR MISSION: Provide a comprehensive, actionable analysis of this person's communication skills.

📋 ANALYSIS FRAMEWORK - Follow this step-by-step process:

STEP 1: OBSERVE & COUNT (Be meticulous)
- Watch the ENTIRE video start to finish
- Count EVERY filler word you hear: "um", "uh", "like", "you know", "so", "actually", "basically", "literally"
- Note the ACTUAL video duration by observing the content
- Track vocal patterns: pace (words per minute), volume variations, tone shifts
- Observe body language: posture, hand gestures, facial micro-expressions, eye movement

STEP 2: ANALYZE (Think like a professional coach)
- How confident does this person appear? (Consider: posture, eye contact, voice steadiness, gesture purposefulness)
- What's their pacing? (Too fast = nervous, too slow = boring, moderate = engaging)
- How natural vs. rehearsed do they seem?
- What emotions are they conveying through facial expressions?
- Are they connecting with the camera/audience?
- What's their energy level throughout?

STEP 3: IDENTIFY PATTERNS
- When do filler words cluster? (Beginning, transitions, thinking moments?)
- Does energy drop or spike at certain points?
- Are there recurring nervous habits? (touching face, shifting weight, avoiding eye contact)
- What gestures are effective vs. distracting?

STEP 4: GENERATE INSIGHTS & RECOMMENDATIONS
- What are their TOP 3 strengths?
- What are their TOP 3 areas for improvement?
- What specific, actionable steps can they take TODAY?
- What practice exercises would help them most?

Now, analyze the video and provide your response in this EXACT JSON format:

{
  "durationSec": <ACTUAL video duration in seconds - count carefully by observing the video>,
  "confidenceScore": <0-100, holistic score considering: voice steadiness (25%), posture (20%), eye contact (20%), gesture purposefulness (15%), minimal filler words (10%), vocal variety (10%)>,
  
  "impressionTags": [<4-5 tags from: "confident", "friendly", "nervous", "engaging", "professional", "approachable", "enthusiastic", "calm", "energetic", "articulate", "authentic", "polished", "relaxed", "poised", "warm", "natural", "credible", "composed", "dynamic", "persuasive">],
  
  "fillerWords": {
    "um": <exact count>,
    "uh": <exact count>,
    "like": <exact count>,
    "you know": <exact count>,
    "so": <exact count>,
    "actually": <exact count>,
    "basically": <exact count>,
    "literally": <exact count>
  },
  
  "vocalAnalysis": {
    "paceWordsPerMin": <estimate 120-180 = moderate, <120 = slow, >180 = fast>,
    "volumeConsistency": <0.0-1.0, how consistent is volume>,
    "tonalVariety": <0.0-1.0, how much vocal variety vs. monotone>,
    "clarity": <0.0-1.0, how clear is pronunciation>,
    "pauseEffectiveness": <0.0-1.0, are pauses used strategically or awkwardly>
  },
  
  "bodyLanguageAnalysis": {
    "postureScore": <0.0-1.0, upright and open vs. slouched/closed>,
    "gestureNaturalness": <0.0-1.0, purposeful vs. fidgety>,
    "facialExpressiveness": <0.0-1.0, animated vs. flat>,
    "eyeContactPct": <0.0-1.0, percentage of time looking at camera>,
    "movementPurpose": <0.0-1.0, intentional movement vs. nervous shifting>
  },
  
  "emotionBreakdown": {
    "joy": <0.0-1.0>,
    "neutral": <0.0-1.0>,
    "anxious": <0.0-1.0>,
    "engaged": <0.0-1.0>,
    "surprise": <0.0-1.0>
  },
  
  "toneTimeline": [
    {"t": 0, "energy": <0.0-1.0>, "confidence": <0.0-1.0>},
    {"t": 5, "energy": <0.0-1.0>, "confidence": <0.0-1.0>},
    <continue every 5 seconds>
  ],
  
  "strengths": [
    "<Specific strength #1 with evidence>",
    "<Specific strength #2 with evidence>",
    "<Specific strength #3 with evidence>"
  ],
  
  "areasForImprovement": [
    "<Specific area #1 with actionable advice>",
    "<Specific area #2 with actionable advice>",
    "<Specific area #3 with actionable advice>"
  ],
  
  "feedback": "<3-4 sentences: Start with a positive observation, mention specific metrics (e.g., 'You used 7 filler words in 30 seconds' or 'Your eye contact was strong at 85%'), identify the biggest opportunity for improvement, end with encouragement>",
  
  "practiceExercises": [
    "<Exercise #1: Specific drill they can do today>",
    "<Exercise #2: Another practical exercise>",
    "<Exercise #3: A third focused practice>"
  ],
  
  "keyMoments": [
    {"timestamp": <seconds>, "type": "strength", "description": "<What happened that was good>"},
    {"timestamp": <seconds>, "type": "improvement", "description": "<What happened that needs work>"}
  ]
}

CRITICAL RULES:
✅ Count filler words ACCURATELY - if you hear "um" 5 times, write 5, not 0!
✅ Base durationSec on ACTUAL video observation, not file size
✅ emotionBreakdown MUST sum to exactly 1.0
✅ Be SPECIFIC in feedback - use actual numbers and observations
✅ Make recommendations ACTIONABLE - tell them exactly what to do
✅ Return ONLY valid JSON - no markdown, no code blocks, no extra text

Example of GOOD feedback:
"You maintained excellent eye contact (90%) and spoke clearly throughout the 28-second video. However, you used 8 filler words ('um' appeared 5 times), which decreased your professional presence. Practice the 'pause technique' - when you feel an 'um' coming, pause silently for 1 second instead. Your confident posture and warm facial expressions are major strengths - keep those!"

Example of BAD feedback:
"Good job! You did well. Try to improve your speaking skills."

Now analyze the video:`;

    const geminiResp = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${geminiKey}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: analysisPrompt },
                {
                  file_data: {
                    mime_type: "video/mp4",
                    file_uri: fileUri
                  }
                }
              ]
            }
          ],
          generationConfig: {
            temperature: 0.4, // Lower for more consistent, factual analysis
            maxOutputTokens: 4096, // Increased for comprehensive response
            topP: 0.95,
            topK: 40
          }
        }),
      }
    );

    if (!geminiResp.ok) {
      const errorText = await geminiResp.text();
      console.error("Gemini API error:", geminiResp.status, errorText);
      throw new Error(`Gemini API failed: ${errorText}`);
    }

    const geminiData = await geminiResp.json();
    console.log("Gemini response received");
    
    let analysis;
    try {
      const content = geminiData.candidates[0].content.parts[0].text;
      // Remove markdown code blocks if present
      const jsonMatch = content.match(/```(?:json)?\s*(\{[\s\S]*\})\s*```/);
      const jsonStr = jsonMatch ? jsonMatch[1] : content;
      analysis = JSON.parse(jsonStr);
      console.log("Analysis parsed successfully");
    } catch (parseError) {
      console.error("Failed to parse Gemini response:", geminiData.candidates[0].content.parts[0].text);
      throw new Error(`Failed to parse AI analysis: ${parseError}`);
    }

    // Update progress - Saving results
    await supabase.from("sessions").update({ progress: 0.9 }).eq("id", sessionId);

    // Write analysis report
    console.log("Saving analysis report...");
    const { error: reportError } = await supabase
      .from("analysis_reports")
      .insert({
        session_id: sessionId,
        confidence_score: analysis.confidenceScore,
        impression_tags: analysis.impressionTags,
        filler_words: analysis.fillerWords || {},
        tone_timeline: analysis.toneTimeline,
        emotion_breakdown: analysis.emotionBreakdown,
        gaze_eye_contact_pct: analysis.bodyLanguageAnalysis?.eyeContactPct || 0,
        feedback: analysis.feedback,
        duration_sec: analysis.durationSec || estimatedDurationSec,
        // NEW ENHANCED FIELDS
        vocal_analysis: analysis.vocalAnalysis || {},
        body_language_analysis: analysis.bodyLanguageAnalysis || {},
        strengths: analysis.strengths || [],
        areas_for_improvement: analysis.areasForImprovement || [],
        practice_exercises: analysis.practiceExercises || [],
        key_moments: analysis.keyMoments || [],
      });

    if (reportError) {
      console.error("Failed to save report:", reportError);
      throw reportError;
    }

    // Update session to complete
    await supabase
      .from("sessions")
      .update({ status: "complete", progress: 1.0 })
      .eq("id", sessionId);

    // Delete video from storage
    console.log("Cleaning up video file...");
    await supabase.storage.from("videos").remove([session.video_path]);

    // Delete file from Gemini
    console.log("Cleaning up Gemini file...");
    await fetch(
      `https://generativelanguage.googleapis.com/v1beta/${fileUri.replace('https://generativelanguage.googleapis.com/v1beta/', '')}?key=${geminiKey}`,
      { method: "DELETE" }
    );

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

