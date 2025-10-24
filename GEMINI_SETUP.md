# 🚀 Switching to Google Gemini 2.5 Flash

## Why Gemini Instead of OpenAI?

### The Problem with GPT-4o Vision
❌ **GPT-4o Vision does NOT support video files** - only images  
❌ Error: `"Invalid MIME type. Only image types are supported."`  
❌ Cannot analyze video + audio together

### Why Gemini 2.5 Flash is Better
✅ **Native video support** (up to 45 minutes with audio)  
✅ Analyzes video + audio together in one call  
✅ No need to split into frames + separate audio transcription  
✅ **Production-ready** and officially supported  
✅ More accurate for video analysis tasks  
✅ Better understanding of body language, gestures, eye contact  

---

## 📋 Setup Instructions

### Step 1: Get a Gemini API Key

1. Go to: https://ai.google.dev/
2. Click "Get API key"
3. Sign in with your Google account
4. Click "Create API key"
5. Copy the key (starts with `AIza...`)

### Step 2: Set the API Key in Supabase

```bash
cd /Users/khubairnasirm/Desktop/MirrorMate

# Replace YOUR_ACTUAL_KEY with your Gemini API key
npx supabase secrets set GEMINI_API_KEY=YOUR_ACTUAL_KEY
```

**Verify it's set:**
```bash
npx supabase secrets list
```

You should see:
```
GEMINI_API_KEY | [hash]
```

### Step 3: Deploy the New Function

```bash
npx supabase functions deploy analyze-video-gemini
```

### Step 4: Update finalize-session to Call Gemini

Open `supabase/functions/finalize-session/index.ts` and change:

**FROM:**
```typescript
await supabase.functions.invoke("analyze-video", {
  body: { sessionId },
});
```

**TO:**
```typescript
await supabase.functions.invoke("analyze-video-gemini", {
  body: { sessionId },
});
```

Then redeploy:
```bash
npx supabase functions deploy finalize-session
```

---

## 🎯 How It Works

### Old Flow (OpenAI - BROKEN)
```
1. Download video from Supabase Storage
2. Call Whisper API for audio transcription ✅
3. Convert video to base64
4. Send to GPT-4o Vision ❌ FAILS - "Invalid MIME type"
```

### New Flow (Gemini - WORKS)
```
1. Download video from Supabase Storage
2. Upload video to Gemini Files API
3. Wait for video processing
4. Call Gemini 2.5 Flash with video reference
5. Get comprehensive analysis (video + audio)
6. Save results and clean up
```

---

## 📊 Technical Details

### Gemini API Endpoints

**1. Upload Video:**
```
POST https://generativelanguage.googleapis.com/upload/v1beta/files
```

**2. Check Processing Status:**
```
GET https://generativelanguage.googleapis.com/v1beta/files/{fileId}
```

**3. Generate Analysis:**
```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent
```

**4. Delete File:**
```
DELETE https://generativelanguage.googleapis.com/v1beta/files/{fileId}
```

### File Size Limits
- **Gemini Free Tier**: 20MB per file
- **Gemini Pro**: Up to 2GB per file
- **Our App**: Videos are already < 25MB after conversion

### Processing Time
| Stage | Time |
|-------|------|
| Upload to Gemini | 2-4s |
| Video processing | 2-6s |
| AI analysis | 5-10s |
| **Total** | **10-20s** |

### Cost Comparison

| Service | Cost per Analysis | Notes |
|---------|-------------------|-------|
| **OpenAI (old)** | $0.03-0.05 | Whisper + GPT-4o (broken for video) |
| **Gemini 2.5 Flash** | **$0.00** | FREE up to 15 RPM! |
| **Gemini 2.5 Pro** | $0.02-0.04 | If you need higher limits |

🎉 **Gemini is FREE for your use case!**

---

## 🧪 Testing

### Test the New Function Directly

```bash
# Create a test session first, then:
curl -X POST \
  https://YOUR_PROJECT.supabase.co/functions/v1/analyze-video-gemini \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "YOUR_SESSION_ID"}'
```

### Check Logs

```bash
npx supabase functions logs analyze-video-gemini --limit 20
```

**Look for:**
- ✅ "Video downloaded: [SIZE] bytes"
- ✅ "Uploading video to Gemini Files API..."
- ✅ "Video uploaded to Gemini: [URI]"
- ✅ "Video processed and ready for analysis"
- ✅ "Calling Gemini 2.5 Flash for video analysis..."
- ✅ "Gemini response received"
- ✅ "Analysis parsed successfully"
- ✅ "Analysis complete for session: [ID]"

---

## 🔧 Troubleshooting

### Error: "GEMINI_API_KEY not configured"
**Solution:**
```bash
npx supabase secrets set GEMINI_API_KEY=YOUR_KEY
npx supabase secrets list  # Verify it's set
```

### Error: "Video file too large (>20MB)"
**Solution**: The iOS app already converts videos to < 25MB. If this happens:
- Record shorter videos (< 15 seconds)
- The low-quality export fallback should handle this

### Error: "Gemini video processing timeout"
**Solution**: Video took too long to process (rare)
- Wait 2 minutes and try again
- Check Gemini API status: https://status.cloud.google.com/

### Error: "Failed to parse AI analysis"
**Solution**: Gemini returned invalid JSON
- Check logs for the raw response
- The prompt might need adjustment

---

## 📝 Files Modified

### New Files:
1. `/supabase/functions/analyze-video-gemini/index.ts` - New Gemini-based analysis

### Files to Modify:
1. `/supabase/functions/finalize-session/index.ts` - Change function call

### Files to Keep (for reference):
1. `/supabase/functions/analyze-video/index.ts` - Old OpenAI version (deprecated)

---

## ✅ Verification Checklist

After setup, verify:

- [ ] Gemini API key obtained from https://ai.google.dev/
- [ ] `GEMINI_API_KEY` set in Supabase secrets
- [ ] `analyze-video-gemini` function deployed
- [ ] `finalize-session` updated to call new function
- [ ] `finalize-session` function redeployed
- [ ] Test video analysis end-to-end
- [ ] Check session status in database (`complete`, not `error`)
- [ ] View results in app

---

## 🎉 Benefits Summary

| Feature | OpenAI | Gemini 2.5 Flash |
|---------|---------|------------------|
| **Video Support** | ❌ No | ✅ Yes (native) |
| **Audio Support** | ✅ Yes (Whisper) | ✅ Yes (built-in) |
| **Cost (per analysis)** | $0.03-0.05 | **FREE** |
| **Rate Limit** | 3500 TPM | 15 RPM (free tier) |
| **Max Video Length** | N/A | 45 minutes |
| **Body Language Analysis** | ❌ No | ✅ Yes |
| **Eye Contact Detection** | ❌ No | ✅ Yes |
| **Gesture Recognition** | ❌ No | ✅ Yes |
| **Production Ready** | ❌ For images only | ✅ Yes |

---

## 🚀 Ready to Deploy!

Once you've set up the Gemini API key and deployed the functions, your app will:

1. ✅ Record video on iOS (MOV format)
2. ✅ Convert to MP4 on-device
3. ✅ Upload to Supabase Storage
4. ✅ Upload to Gemini Files API
5. ✅ Analyze video + audio with Gemini 2.5 Flash
6. ✅ Get comprehensive feedback
7. ✅ Display results to user

**Total time**: 15-25 seconds  
**Cost**: **FREE** (Gemini free tier)  
**Accuracy**: Better than OpenAI for video tasks! 🎯

