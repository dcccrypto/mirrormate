# 🏗️ MirrorMate Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS App (SwiftUI)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Onboarding   │  │   HomeView   │  │  RecordView  │          │
│  │    View      │─▶│ (Main Hub)   │─▶│   (Camera)   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                  │                  │                  │
│         ▼                  ▼                  ▼                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  SignUp/In   │  │ ProfileView  │  │ Processing   │          │
│  │    Views     │  │  (Settings)  │  │     View     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                  │                  │                  │
│         │                  │                  ▼                  │
│         │                  │          ┌──────────────┐          │
│         │                  │          │ ResultsView  │          │
│         │                  │          │  (Analysis)  │          │
│         │                  │          └──────────────┘          │
│         │                  │                  │                  │
└─────────┼──────────────────┼──────────────────┼──────────────────┘
          │                  │                  │
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Service Layer                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ AuthService  │  │ QuotaService │  │  ApiClient   │          │
│  │ (@MainActor) │  │ (@MainActor) │  │   (async)    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                  │
│         │                  │                  │                  │
│  ┌──────┴────────┐  ┌──────┴───────┐  ┌──────┴───────┐         │
│  │UploadService  │  │SessionStore  │  │StoreKitMgr   │         │
│  │   (async)     │  │ (CoreData)   │  │ (Premium)    │         │
│  └───────────────┘  └──────────────┘  └──────────────┘         │
│                                                                   │
└───────────────────────────┬───────────────────────────────────────┘
                           │
                           │ HTTPS/JWT
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Supabase Backend                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Supabase Auth                           │  │
│  │  • JWT Token Generation                                    │  │
│  │  • Session Management                                      │  │
│  │  • Password Hashing                                        │  │
│  │  • Email Verification (optional)                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                           │                                       │
│                           ▼                                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  PostgreSQL Database                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │  │
│  │  │   auth.     │  │  sessions   │  │ analysis_   │       │  │
│  │  │   users     │◀─│  table      │◀─│  reports    │       │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │  │
│  │         ▲                                                   │  │
│  │         │                                                   │  │
│  │         │          ┌─────────────┐                         │  │
│  │         └──────────│user_quotas  │                         │  │
│  │                    │   table     │                         │  │
│  │                    └─────────────┘                         │  │
│  │  • Row Level Security (RLS)                                │  │
│  │  • Foreign Key Constraints                                 │  │
│  │  • Indexes on user_id                                      │  │
│  └───────────────────────────────────────────────────────────┘  │
│                           │                                       │
│                           ▼                                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  Storage (Videos Bucket)                   │  │
│  │  • Signed Upload URLs                                      │  │
│  │  • Video files (.mov)                                      │  │
│  │  • Private access only                                     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                           │                                       │
│                           ▼                                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              Edge Functions (Deno/TypeScript)              │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │  │
│  │  │init-session │  │finalize-    │  │analyze-     │       │  │
│  │  │             │─▶│session      │─▶│video        │       │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │  │
│  │  • Extract user_id from JWT                                │  │
│  │  • Create session records                                  │  │
│  │  • Trigger AI analysis                                     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────┬───────────────────────────────────────┘
                           │
                           │ API Calls
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      OpenAI APIs                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Whisper    │  │  GPT-4       │  │   GPT-4      │          │
│  │   (Audio)    │  │  Vision      │  │  (Analysis)  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                  │                  │                  │
│         ▼                  ▼                  ▼                  │
│  Speech-to-Text    Frame Analysis    Feedback Generation        │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Authentication Flow

```
┌──────────┐                                                         
│   User   │                                                         
└────┬─────┘                                                         
     │                                                               
     │ 1. Sign Up/In                                                
     ▼                                                               
┌──────────────┐                                                    
│ AuthService  │                                                    
└────┬─────────┘                                                    
     │                                                               
     │ 2. Credentials                                               
     ▼                                                               
┌──────────────────┐                                                
│  Supabase Auth   │                                                
└────┬─────────────┘                                                
     │                                                               
     │ 3. JWT Token                                                 
     ▼                                                               
┌──────────────────┐                                                
│    iOS App       │                                                
│  (Token Stored)  │                                                
└────┬─────────────┘                                                
     │                                                               
     │ 4. All requests include                                      
     │    Authorization: Bearer <token>                             
     ▼                                                               
┌──────────────────┐                                                
│ Supabase Backend │                                                
│  (Validates JWT) │                                                
└──────────────────┘                                                
```

## Quota Check Flow

```
User Taps Record
       │
       ▼
┌──────────────────────────────────────┐
│     RecordView.toggleRecording()     │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│  QuotaService.canAnalyzeToday()      │
└───────────────┬──────────────────────┘
                │
                ├─────────────┬──────────────┬──────────────┐
                │             │              │              │
                ▼             ▼              ▼              ▼
         ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
         │ Premium? │  │  Auth'd  │  │Database  │  │Anonymous │
         │   YES    │  │   User   │  │  Check   │  │ Fallback │
         └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘
              │             │              │              │
              ▼             ▼              ▼              ▼
         ┌────────┐    ┌─────────┐   ┌─────────┐   ┌─────────┐
         │ ALLOW  │    │ Query   │   │ Check   │   │  Check  │
         │Unlimited│   │user_    │   │daily_   │   │UserDe-  │
         └────────┘    │quotas   │   │count    │   │faults   │
                       └────┬────┘   └────┬────┘   └────┬────┘
                            │              │              │
                            ▼              ▼              ▼
                       ┌─────────────────────────────────────┐
                       │  < dailyFreeLimit (1)?              │
                       │  YES → ALLOW    NO → SHOW PAYWALL   │
                       └─────────────────────────────────────┘
```

## Video Analysis Flow

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. User Records Video                                             │
│    ├─ AVCaptureSession captures video                            │
│    ├─ Saved to temp file (.mov)                                  │
│    └─ User taps "Upload & Analyze"                               │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 2. ApiClient.initSession()                                        │
│    ├─ POST /functions/v1/init-session                            │
│    ├─ Headers: Authorization: Bearer <jwt_token>                 │
│    ├─ Body: {maxDurationSec, deviceId}                           │
│    └─ Returns: {sessionId, uploadUrl, uploadPath, uploadToken}   │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 3. UploadService.uploadFileSigned()                               │
│    ├─ Uses signed URL from step 2                                │
│    ├─ Uploads .mov file to Supabase Storage                      │
│    ├─ Path: videos/<sessionId>.mov                               │
│    └─ Token expires in 15 minutes                                │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 4. ApiClient.finalize(sessionId)                                  │
│    ├─ POST /functions/v1/finalize-session                        │
│    ├─ Body: {sessionId}                                          │
│    ├─ Triggers analyze-video Edge Function                       │
│    └─ Updates session status to "processing"                     │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 5. QuotaService.markUsedToday()                                   │
│    ├─ Updates user_quotas.daily_count += 1                       │
│    └─ Updates user_quotas.last_analysis_date = today             │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 6. Navigate to ProcessingView                                     │
│    └─ Shows AI pulse animation                                   │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 7. ProcessingView polls ApiClient.status(sessionId)               │
│    ├─ GET /rest/v1/sessions?id=eq.<sessionId>                    │
│    ├─ Checks session.status and session.progress                 │
│    ├─ Polls every 1 second                                       │
│    └─ Until status = "complete"                                  │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 8. Meanwhile: analyze-video Edge Function                         │
│    ├─ Downloads video from Storage                               │
│    ├─ Extracts audio → Whisper API (speech-to-text)             │
│    ├─ Extracts frames → GPT-4 Vision API (visual analysis)       │
│    ├─ Analyzes transcript + visuals → GPT-4 (feedback)          │
│    ├─ Generates confidence score, tags, metrics                  │
│    ├─ Inserts into analysis_reports table                        │
│    └─ Updates session.status = "complete"                        │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 9. ApiClient.report(sessionId)                                    │
│    ├─ GET /rest/v1/analysis_reports?session_id=eq.<sessionId>    │
│    └─ Returns AnalysisReport                                     │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 10. SessionStore.saveReport()                                     │
│     ├─ Saves to CoreData (local cache)                           │
│     └─ Triggers reload of sessions list                          │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 11. Navigate to ResultsView                                       │
│     ├─ Shows confidence score with animation                     │
│     ├─ Displays impression tags                                  │
│     ├─ Shows tone timeline chart                                 │
│     ├─ Renders AI feedback                                       │
│     └─ Adds to History                                           │
└──────────────────────────────────────────────────────────────────┘
```

## Data Models

### Swift (iOS)
```swift
// User Authentication
struct User {
    let id: UUID
    let email: String
    let metadata: [String: Any]
}

// Quota Management
struct UserQuotaRecord {
    let id: UUID
    let user_id: UUID
    let last_analysis_date: String
    let daily_count: Int
}

// Session
struct InitSessionResponse {
    let sessionId: String
    let uploadUrl: String
    let uploadPath: String
    let uploadToken: String
    let expiresAt: String
}

// Analysis Results
struct AnalysisReport {
    let sessionId: String
    let durationSec: Int
    let confidenceScore: Int
    let impressionTags: [String]
    let fillerWords: [String: Int]
    let toneTimeline: [TonePoint]
    let emotionBreakdown: [String: Double]
    let gaze: Gaze
    let feedback: String
    let createdAt: Date
}
```

### Database (PostgreSQL)
```sql
-- Authentication
auth.users (
    id UUID PRIMARY KEY,
    email TEXT UNIQUE,
    encrypted_password TEXT,
    email_confirmed_at TIMESTAMPTZ,
    raw_user_meta_data JSONB
)

-- Quotas
user_quotas (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users,
    last_analysis_date DATE,
    daily_count INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)

-- Sessions
sessions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users,
    device_id TEXT,
    video_path TEXT,
    status TEXT CHECK (status IN ('queued','processing','complete','error')),
    progress FLOAT,
    created_at TIMESTAMPTZ
)

-- Reports
analysis_reports (
    id UUID PRIMARY KEY,
    session_id UUID REFERENCES sessions,
    confidence_score INTEGER CHECK (confidence_score BETWEEN 0 AND 100),
    impression_tags JSONB,
    filler_words JSONB,
    tone_timeline JSONB,
    emotion_breakdown JSONB,
    gaze_eye_contact_pct FLOAT CHECK (gaze_eye_contact_pct BETWEEN 0 AND 1),
    feedback TEXT,
    created_at TIMESTAMPTZ
)
```

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Security Layers                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Layer 1: Transport Security                                     │
│  ├─ HTTPS/TLS encryption for all requests                       │
│  ├─ Certificate pinning (optional)                              │
│  └─ Secure WebSocket connections                                │
│                                                                   │
│  Layer 2: Authentication                                         │
│  ├─ JWT token-based authentication                              │
│  ├─ Token refresh mechanism                                     │
│  ├─ Secure password hashing (bcrypt)                            │
│  └─ Session expiry (configurable)                               │
│                                                                   │
│  Layer 3: Authorization (RLS)                                    │
│  ├─ Row Level Security policies                                 │
│  ├─ Users can only access own data                              │
│  ├─ auth.uid() validation in policies                           │
│  └─ Anonymous users have limited access                         │
│                                                                   │
│  Layer 4: Data Validation                                        │
│  ├─ Input sanitization                                           │
│  ├─ Type checking                                                │
│  ├─ CHECK constraints in database                               │
│  └─ Foreign key constraints                                      │
│                                                                   │
│  Layer 5: API Keys                                               │
│  ├─ Anon key (public, rate-limited)                             │
│  ├─ Service role key (private, backend only)                    │
│  ├─ OpenAI key (backend only)                                   │
│  └─ Never exposed in client code                                │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Production Stack                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  App Store                                                       │
│  └─ MirrorMate iOS App (SwiftUI)                                │
│     └─ Download & Install on iPhone                             │
│                                                                   │
│  Supabase Cloud                                                  │
│  ├─ PostgreSQL Database (hosted)                                │
│  ├─ Storage (S3-compatible)                                     │
│  ├─ Edge Functions (Deno runtime)                               │
│  └─ Auth Service (managed)                                      │
│                                                                   │
│  OpenAI Platform                                                 │
│  ├─ Whisper API (speech-to-text)                                │
│  ├─ GPT-4 Vision API (image analysis)                           │
│  └─ GPT-4 API (text generation)                                 │
│                                                                   │
│  App Store Connect                                               │
│  └─ StoreKit (in-app purchases)                                 │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Takeaways

### 🔐 Authentication
- JWT-based, industry-standard
- Supabase handles security
- Persistent sessions
- Multi-device ready

### 📊 Quota System
- Database-backed tracking
- Fair usage enforcement
- Premium tier ready
- Graceful degradation

### 🎨 User Experience
- Seamless sign up/in
- Clear feedback
- Beautiful animations
- Error handling

### 🏗️ Architecture
- Clean separation of concerns
- @MainActor for UI isolation
- Async/await throughout
- Proper error propagation

### 🚀 Scalability
- RLS for data isolation
- Indexed foreign keys
- Edge functions for compute
- Storage for large files

---

**Last Updated**: October 17, 2025  
**Version**: 1.0.0

