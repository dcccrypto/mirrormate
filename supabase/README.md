# MirrorMate Supabase Backend

## Setup Instructions

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note your project URL and anon key from Settings > API
3. Note your service role key (keep this secret!)

### 2. Run Migrations
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Run migrations
supabase db push
```

### 3. Create Storage Bucket
1. Go to Storage in Supabase dashboard
2. Create new bucket named `videos`
3. Set to **private** (public: false)
4. Set file size limit to 100MB
5. Add lifecycle policy to auto-delete files after 24 hours:
   - Go to bucket settings > Lifecycle rules
   - Add rule: Delete objects older than 1 day

### 4. Deploy Edge Functions
```bash
# Set secrets
supabase secrets set OPENAI_API_KEY=your_openai_api_key

# Deploy functions
supabase functions deploy init-session
supabase functions deploy finalize-session
supabase functions deploy analyze-video
```

### 5. Update iOS App
Add these to your iOS app's configuration:
- `SUPABASE_URL`: Your project URL
- `SUPABASE_ANON_KEY`: Your anon key

## API Endpoints

### POST /functions/v1/init-session
Creates a new session and returns signed upload URL.

Request:
```json
{
  "maxDurationSec": 60,
  "deviceId": "device-uuid",
  "userId": "user-uuid" // optional
}
```

Response:
```json
{
  "sessionId": "uuid",
  "uploadUrl": "signed-url",
  "expiresAt": "2025-01-15T12:00:00Z"
}
```

### POST /functions/v1/finalize-session
Triggers video analysis after upload completes.

Request:
```json
{
  "sessionId": "uuid"
}
```

Response:
```json
{
  "status": "queued"
}
```

### GET /rest/v1/sessions?id=eq.{sessionId}
Poll session status.

Response:
```json
{
  "id": "uuid",
  "status": "processing",
  "progress": 0.5
}
```

### GET /rest/v1/analysis_reports?session_id=eq.{sessionId}
Fetch completed analysis report.

Response:
```json
{
  "sessionId": "uuid",
  "confidenceScore": 78,
  "impressionTags": ["confident", "friendly"],
  "fillerWords": {"uh": 3, "like": 2},
  "toneTimeline": [{"t": 0, "energy": 0.5}],
  "emotionBreakdown": {"joy": 0.4, "neutral": 0.6},
  "gazeEyeContactPct": 0.75,
  "feedback": "You sounded confident...",
  "createdAt": "2025-01-15T12:00:00Z"
}
```

## Cost Estimates
- Supabase: Free tier (500MB DB, 1GB storage, 2GB bandwidth)
- OpenAI per 60s video: ~$0.35 (Whisper $0.01 + GPT-4 $0.34)
- Upgrade to Supabase Pro ($25/mo) if needed

## Testing
Test Edge Functions locally:
```bash
supabase functions serve
```

Then call:
```bash
curl -i --location --request POST 'http://localhost:54321/functions/v1/init-session' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"maxDurationSec":60,"deviceId":"test"}'
```

