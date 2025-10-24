# MirrorMate - Complete Testing Guide 🧪

## Function Status ✅

All Edge Functions are deployed and ACTIVE:

| Function | Version | Status | Key Features |
|----------|---------|--------|--------------|
| `init-session` | v5 | ✅ ACTIVE | Creates `.mp4` files (not `.mov`) |
| `finalize-session` | v2 | ✅ ACTIVE | Triggers analysis |
| `analyze-video` | v6 | ✅ ACTIVE | MIME type fix + 25MB check |

## Pre-Flight Checklist

Before testing, verify:

### 1. ✅ OpenAI API Key
```bash
cd /Users/khubairnasirm/Desktop/MirrorMate
npx supabase secrets list
```

**Expected Output:**
```
NAME            VALUE (PREVIEW)
OPENAI_API_KEY  sk-proj-...
```

If missing, set it:
```bash
npx supabase secrets set OPENAI_API_KEY=sk-proj-YOUR_KEY_HERE
```

### 2. ✅ OpenAI Credits
- Go to: https://platform.openai.com/account/billing
- Ensure you have at least $1 in credits
- Each test costs ~$0.03-0.05

### 3. ✅ iOS Permissions
- Camera: Allowed ✅
- Microphone: Allowed ✅
- Check in: Settings → MirrorMate → Permissions

## Test Procedure

### Test 1: End-to-End Happy Path 🎯

**Goal**: Record → Upload → Analyze → View Results

1. **Open MirrorMate App**
   - Launch on your iOS device/simulator
   - Should see HomeView with "Start Recording" button

2. **Record Video**
   - Tap "Start Recording"
   - Camera should open (not black screen)
   - Record for **5-10 seconds** (say something!)
   - Tap red stop button

3. **Upload**
   - "Upload & Analyze" button should appear
   - Tap it
   - Should show loading state:
     - "Preparing upload..."
     - "Uploading video..."
     - "Creating session..."
     - "Finalizing..."

4. **Processing**
   - Auto-navigate to ProcessingView
   - Should show AI pulse animation
   - Progress updates:
     - 20% - "Transcribing audio..."
     - 40% - "Analyzing video..."
     - 60% - "Generating insights..."
     - 90% - "Finalizing report..."
     - 100% - "Complete!"

5. **Results**
   - Auto-navigate to ResultsView
   - Should display:
     - ✅ Confidence Score (0-100)
     - ✅ Impression Tags (5 words)
     - ✅ Emotion Breakdown (chart)
     - ✅ Tone Timeline (graph)
     - ✅ AI Feedback (text)
     - ✅ Eye Contact % (gauge)

**Expected Time**: 15-25 seconds total

### Test 2: Verify Database Entry 🗄️

After successful analysis, check the database:

```bash
cd /Users/khubairnasirm/Desktop/MirrorMate
npx supabase db execute "SELECT id, status, video_path, progress, created_at FROM sessions ORDER BY created_at DESC LIMIT 1"
```

**Expected Output:**
```
id                  | status   | video_path                              | progress | created_at
--------------------|----------|----------------------------------------|----------|------------------
[UUID]              | complete | [UUID].mp4                             | 1.0      | [timestamp]
```

**Key Checks:**
- ✅ `status = 'complete'` (not 'error')
- ✅ `video_path` ends with `.mp4` (not `.mov`)
- ✅ `progress = 1.0` (100%)
- ✅ No `error_message`

### Test 3: Verify Analysis Report 📊

```bash
npx supabase db execute "SELECT session_id, confidence_score, impression_tags, feedback, gaze_eye_contact_pct FROM analysis_reports ORDER BY created_at DESC LIMIT 1"
```

**Expected Output:**
```
session_id | confidence_score | impression_tags                              | feedback                                 | gaze_eye_contact_pct
-----------|------------------|----------------------------------------------|------------------------------------------|---------------------
[UUID]     | 75               | ["confident","engaging","friendly",...] | [Detailed AI feedback...]                | 0.65
```

**Key Checks:**
- ✅ `confidence_score` between 0-100
- ✅ `impression_tags` has 3-5 tags
- ✅ `feedback` has actionable advice
- ✅ `gaze_eye_contact_pct` between 0-1

### Test 4: Check Edge Function Logs 📜

```bash
npx supabase functions logs analyze-video --limit 10
```

**Expected Output (for successful run):**
```
Analyzing session: [UUID]
Downloading video: [UUID].mp4
Video downloaded: [SIZE] bytes
Video file size: [X.XX] MB
Calling Whisper API for audio transcription...
Transcript (XXX chars): [preview]...
Filler words detected: {...}
Calling GPT-4o Vision API for video analysis...
GPT-4o response received
Analysis parsed successfully
Saving analysis report...
Cleaning up video file...
Analysis complete for session: [UUID]
```

**Red Flags to Watch For:**
- ❌ "Invalid file format" - Old version still cached
- ❌ "File too large" - Video exceeds 25MB
- ❌ "Whisper API failed" - OpenAI issue
- ❌ "Insufficient quota" - No OpenAI credits

## Troubleshooting

### Issue 1: Still Getting "Invalid file format"

**Cause**: Old function version cached or video not converted

**Fix**:
1. Wait 2-3 minutes for cache to clear
2. Record a **brand new** video (don't re-upload old ones)
3. Check that `init-session` v5 is being called:
   ```bash
   npx supabase functions logs init-session --limit 1
   ```
4. Verify video path has `.mp4` extension in database

### Issue 2: Video Too Large (>25MB)

**Cause**: Recording too long at high quality

**Fix**:
- Keep recordings under **30 seconds**
- iPhone records at ~3-5MB per 10 seconds
- 60 seconds ≈ 18-30MB (may exceed limit)

### Issue 3: Black Camera Screen

**Cause**: AVFoundation session not starting

**Fix**:
1. Close app completely (swipe up)
2. Go to Settings → Privacy → Camera → MirrorMate → Toggle OFF then ON
3. Relaunch app
4. Check logs in Xcode console for errors

### Issue 4: Stuck at 20% Progress

**Cause**: Whisper API failing

**Fix**:
1. Check Supabase logs:
   ```bash
   npx supabase functions logs analyze-video
   ```
2. Look for exact Whisper error message
3. Verify OpenAI key is correct and has credits
4. Check if video file exists in storage:
   ```bash
   npx supabase storage list videos
   ```

### Issue 5: No Analysis Results

**Cause**: GPT-4o parsing failed

**Fix**:
1. Check logs for "Failed to parse GPT response"
2. Response might have markdown formatting
3. Our code handles this with regex extraction
4. If persists, check OpenAI status: https://status.openai.com

## Performance Benchmarks

| Stage | Expected Time | What's Happening |
|-------|--------------|------------------|
| Upload | 2-5 sec | Uploading to Supabase Storage |
| Whisper | 3-8 sec | Audio transcription |
| GPT-4o | 8-15 sec | Video + audio analysis |
| Save | 1-2 sec | Writing to database |
| **Total** | **15-30 sec** | Full pipeline |

## Cost Analysis

| Component | Cost | Per Video |
|-----------|------|-----------|
| Whisper | $0.006/min | ~$0.001-0.002 (5-10 sec) |
| GPT-4o Vision | $0.01-0.03 | ~$0.02-0.04 |
| Supabase | Free tier | $0 (first 1GB) |
| **Total** | - | **~$0.03-0.05** |

**With $20 in OpenAI credits = 400-600 analyses**

## Success Criteria Checklist

After running Test 1, you should have:

- [ ] Video recorded without black screen
- [ ] Upload button appeared after stopping
- [ ] Upload completed without errors
- [ ] Navigated to ProcessingView automatically
- [ ] Progress bar updated smoothly (20% → 100%)
- [ ] Navigated to ResultsView automatically
- [ ] Confidence score displayed (0-100)
- [ ] 5 impression tags shown
- [ ] Emotion breakdown chart visible
- [ ] Tone timeline graph displayed
- [ ] AI feedback text present (2-3 sentences)
- [ ] Eye contact percentage shown
- [ ] Database shows `status = 'complete'`
- [ ] No error messages in logs

## Next Steps After Successful Test

1. **Test Edge Cases**
   - Very short video (2-3 seconds)
   - Longer video (30-40 seconds)
   - Silent video (no speaking)
   - Poor lighting conditions

2. **Stress Test**
   - Multiple videos in quick succession
   - Check quota system works (3 free per day)
   - Verify paywall appears after quota exceeded

3. **History View**
   - Check past analyses appear in history
   - Verify progress chart shows trends
   - Test filtering by date

4. **Subscription Flow**
   - Test paywall presentation
   - Verify StoreKit products load
   - Check premium features unlock

## Support

If tests fail, provide:
1. Exact error message from logs
2. Session ID from database
3. Screenshot of the error state
4. Device info (iOS version, device model)

## Ready to Test! 🚀

All systems are deployed and ready. Start with **Test 1** and work through the checklist!

