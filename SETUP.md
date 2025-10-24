# MirrorMate Setup Guide

## Prerequisites
- Xcode 16+ with iOS 18.5 SDK
- Supabase account (free tier works)
- OpenAI API key

## Backend Setup (Supabase)

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click "New project"
3. Fill in project name, database password, region
4. Wait for provisioning (~2 minutes)

### 2. Get Your Credentials
1. Go to Project Settings > API
2. Copy your **Project URL** (looks like `https://xxx.supabase.co`)
3. Copy your **anon public** key
4. Copy your **service_role** secret key (for Edge Functions only, never expose in iOS app)

### 3. Run Database Migrations
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Navigate to project directory
cd /Users/khubairnasirm/Desktop/MirrorMate

# Link to your Supabase project
supabase link --project-ref YOUR_PROJECT_REF

# Push migrations
supabase db push
```

### 4. Create Storage Bucket
1. In Supabase Dashboard, go to **Storage**
2. Click "New bucket"
3. Name it `videos`
4. Set **Public bucket**: OFF (private)
5. Click "Save"
6. Go to bucket settings > Lifecycle rules
7. Add rule: Delete objects older than **1 day**

### 5. Deploy Edge Functions
```bash
# Set OpenAI API key as secret
supabase secrets set OPENAI_API_KEY=sk-your-openai-key-here

# Deploy functions
supabase functions deploy init-session
supabase functions deploy finalize-session
supabase functions deploy analyze-video
```

Verify deployment:
```bash
supabase functions list
```

## iOS App Setup

### 1. Update Supabase Config
Open `MirrorMate/Services/SupabaseConfig.swift` and replace:

```swift
static let url = "https://YOUR_PROJECT_REF.supabase.co"
static let anonKey = "YOUR_ANON_KEY_HERE"
```

### 2. Build and Run
1. Open `MirrorMate.xcodeproj` in Xcode
2. Select a physical iOS device (camera won't work in simulator)
3. Product > Build (⌘B)
4. Product > Run (⌘R)

### 3. Grant Permissions
On first launch, accept:
- Camera access
- Microphone access

## Testing the Flow

### End-to-End Test
1. Tap "Record" button on home screen
2. Record a 10-15 second video talking naturally
3. Tap record button again to stop
4. Video uploads to Supabase Storage
5. Processing screen shows progress
6. AI analysis runs (Whisper + GPT-4)
7. Results screen displays confidence score, tags, feedback

### Verify in Supabase Dashboard
- Go to **Database** > `sessions` table → see your session
- Go to **Storage** > `videos` → see uploaded file (will auto-delete after 24h)
- After analysis completes:
  - **Database** > `analysis_reports` → see your report
  - Storage video should be deleted

## Troubleshooting

### Camera not showing
- Test on a physical device (not simulator)
- Ensure permissions were granted
- Delete and reinstall app to re-trigger permission prompts

### Upload fails
- Check your internet connection
- Verify Supabase URL and anon key in `SupabaseConfig.swift`
- Check Supabase project isn't paused (free tier pauses after 7 days inactivity)

### Analysis stuck at "processing"
- Check Edge Functions logs in Supabase Dashboard
- Verify OpenAI API key is set: `supabase secrets list`
- Check OpenAI account has credits
- Look for errors in function logs: `supabase functions logs analyze-video`

### Build errors
- Clean build folder: Product > Clean Build Folder
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Restart Xcode

## Cost Monitoring

### Supabase Free Tier Limits
- 500MB database
- 1GB file storage
- 2GB bandwidth/month
- 500K Edge Function invocations

### OpenAI Costs (per 60s video)
- Whisper transcription: ~$0.01
- GPT-4 text analysis: ~$0.03
- **Total**: ~$0.04 per analysis

For 100 analyses/month: ~$4

## Next Steps
- Test on multiple devices
- Add user authentication (optional)
- Customize AI prompts in `analyze-video/index.ts`
- Add more premium features
- Submit to App Store

## Support
- Supabase docs: https://supabase.com/docs
- OpenAI API docs: https://platform.openai.com/docs
- Check `supabase/README.md` for API endpoints

