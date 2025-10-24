# OpenAI API Key Setup for MirrorMate

## Issue
The `analyze-video` Edge Function is failing with 500 errors because the `OPENAI_API_KEY` environment variable is not configured in Supabase.

## Solution

### Step 1: Get Your OpenAI API Key
1. Go to https://platform.openai.com/api-keys
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the key (it starts with `sk-`)

### Step 2: Add the Key to Supabase

#### Option A: Via Supabase Dashboard (Recommended)
1. Go to your Supabase dashboard: https://supabase.com/dashboard/project/lchudacxfedkylmjbdsz
2. Click on **Settings** (gear icon) in the left sidebar
3. Click on **Edge Functions**
4. Scroll to **Environment Variables**
5. Click **Add Secret**
6. Enter:
   - Name: `OPENAI_API_KEY`
   - Value: Your OpenAI API key (starts with `sk-`)
7. Click **Save**

#### Option B: Via Supabase CLI
```bash
cd /Users/khubairnasirm/Desktop/MirrorMate
supabase secrets set OPENAI_API_KEY=sk-your-actual-key-here
```

### Step 3: Verify It Works
After setting the key, test the analyze function by:
1. Recording a video in the app
2. Uploading it
3. Check the logs:
```bash
supabase functions logs analyze-video --follow
```

You should see the AI analysis complete successfully instead of 500 errors.

## Cost Estimate
- Whisper API (audio transcription): ~$0.006 per minute of audio
- GPT-4 API (analysis): ~$0.03 per video (depending on transcript length)
- Total: ~$0.04 per video analysis

For 100 videos per month: ~$4.00

## Troubleshooting
If you still see errors after setting the key:
1. Wait 1-2 minutes for the change to propagate
2. Redeploy the edge function:
   ```bash
   cd supabase
   supabase functions deploy analyze-video
   ```
3. Check the logs for more detailed error messages

