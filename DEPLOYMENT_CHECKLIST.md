# 🚀 MirrorMate Deployment Checklist

## Pre-Deployment Steps

### ✅ 1. Supabase Configuration

- [ ] **Create Supabase Project** (if not already done)
  ```
  Go to: https://supabase.com/dashboard
  Create new project
  Note: Project URL and API keys
  ```

- [ ] **Update SupabaseConfig.swift**
  ```swift
  static let url = "https://YOUR_PROJECT.supabase.co"
  static let anonKey = "YOUR_ANON_KEY"
  static let serviceRoleKey = "YOUR_SERVICE_ROLE_KEY"
  ```

- [ ] **Enable Email Authentication**
  ```
  Supabase Dashboard → Authentication → Providers → Email
  ✓ Enable Email provider
  ✓ Configure email templates (optional)
  ✓ Set site URL for redirects
  ```

### ✅ 2. Database Setup

- [ ] **Apply Migrations**
  ```bash
  cd /Users/khubairnasirm/Desktop/MirrorMate
  supabase db push
  ```

- [ ] **Verify Tables Created**
  - [ ] `sessions` table exists
  - [ ] `analysis_reports` table exists
  - [ ] `user_quotas` table exists
  - [ ] All foreign keys to `auth.users` are set

- [ ] **Verify RLS Policies**
  ```sql
  -- Check policies exist
  SELECT * FROM pg_policies WHERE schemaname = 'public';
  ```
  - [ ] `sessions` policies (insert, update, select)
  - [ ] `analysis_reports` policies (select)
  - [ ] `user_quotas` policies (insert, update, select)

### ✅ 3. Storage Setup

- [ ] **Create Storage Bucket**
  ```
  Supabase Dashboard → Storage → New Bucket
  Name: "videos"
  Public: No
  ```

- [ ] **Set Storage Policies**
  ```sql
  -- Allow authenticated users to upload
  CREATE POLICY "Users can upload videos"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'videos');
  
  -- Allow authenticated users to read own videos
  CREATE POLICY "Users can read own videos"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'videos');
  ```

### ✅ 4. Edge Functions Deployment

- [ ] **Deploy init-session**
  ```bash
  supabase functions deploy init-session
  ```

- [ ] **Deploy finalize-session**
  ```bash
  supabase functions deploy finalize-session
  ```

- [ ] **Deploy analyze-video**
  ```bash
  supabase functions deploy analyze-video
  ```

- [ ] **Set Environment Variables**
  ```bash
  supabase secrets set OPENAI_API_KEY=your_openai_key
  supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
  ```

- [ ] **Test Edge Functions**
  ```bash
  # Test init-session
  curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/init-session \
    -H "Authorization: Bearer YOUR_ANON_KEY" \
    -H "Content-Type: application/json" \
    -d '{"maxDurationSec": 60, "deviceId": "test"}'
  ```

### ✅ 5. OpenAI Setup

- [ ] **Obtain OpenAI API Key**
  ```
  Go to: https://platform.openai.com/api-keys
  Create new secret key
  ```

- [ ] **Configure API Access**
  - [ ] Enable GPT-4 Vision API
  - [ ] Enable Whisper API
  - [ ] Enable GPT-4 API
  - [ ] Set usage limits (optional)
  - [ ] Add billing information

### ✅ 6. iOS App Configuration

- [ ] **Update Info.plist**
  - [x] Camera usage description
  - [x] Microphone usage description

- [ ] **Configure App Capabilities**
  - [ ] Network permissions
  - [ ] Background modes (if needed)
  - [ ] Push notifications (future)

- [ ] **Bundle ID & Signing**
  ```
  Xcode → Target → Signing & Capabilities
  - Set Team
  - Set Bundle Identifier: com.yourcompany.MirrorMate
  - Enable Automatic Signing
  ```

### ✅ 7. StoreKit Setup

- [ ] **Create App in App Store Connect**
  ```
  https://appstoreconnect.apple.com
  My Apps → + → New App
  ```

- [ ] **Create In-App Purchase Product**
  ```
  App → Features → In-App Purchases → +
  Type: Auto-Renewable Subscription
  Product ID: mirrormate_premium_monthly
  Reference Name: MirrorMate Premium Monthly
  Price: $9.99/month (or your choice)
  ```

- [ ] **Update StoreKitManager.swift**
  ```swift
  private let monthlyProductID = "mirrormate_premium_monthly"
  private let yearlyProductID = "mirrormate_premium_yearly"
  ```

- [ ] **Test StoreKit**
  - [ ] Add StoreKit Configuration File (for testing)
  - [ ] Create Sandbox Test Account
  - [ ] Test purchase flow

### ✅ 8. Build & Test

- [ ] **Clean Build**
  ```bash
  cd /Users/khubairnasirm/Desktop/MirrorMate
  xcodebuild clean -project MirrorMate.xcodeproj -scheme MirrorMate
  ```

- [ ] **Build for Device**
  ```bash
  xcodebuild -project MirrorMate.xcodeproj \
    -scheme MirrorMate \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    build
  ```

- [ ] **Test on Physical Device**
  - [ ] Install on iPhone
  - [ ] Test sign up flow
  - [ ] Test sign in flow
  - [ ] Test video recording
  - [ ] Test video upload
  - [ ] Test AI analysis
  - [ ] Test quota enforcement
  - [ ] Test premium upgrade (sandbox)
  - [ ] Test sign out

### ✅ 9. Security Checklist

- [ ] **API Keys**
  - [x] Supabase anon key in code (public - OK)
  - [ ] OpenAI key in environment variables ONLY
  - [ ] Service role key in environment variables ONLY
  - [ ] Never commit .env files

- [ ] **RLS Policies**
  - [ ] All tables have RLS enabled
  - [ ] Users can only access own data
  - [ ] Anonymous users have limited access
  - [ ] Test with different user accounts

- [ ] **Authentication**
  - [ ] Password requirements enforced
  - [ ] JWT tokens validated
  - [ ] Session expiry handled
  - [ ] Logout clears all data

### ✅ 10. Performance & Monitoring

- [ ] **Supabase Monitoring**
  ```
  Dashboard → Logs → Edge Functions
  Monitor: init-session, finalize-session, analyze-video
  ```

- [ ] **Database Indexing**
  ```sql
  -- Check indexes exist for foreign keys
  CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
  CREATE INDEX IF NOT EXISTS idx_user_quotas_user_id ON user_quotas(user_id);
  CREATE INDEX IF NOT EXISTS idx_analysis_reports_session_id ON analysis_reports(session_id);
  ```

- [ ] **Set Up Alerts**
  - [ ] Edge Function errors
  - [ ] Database connection issues
  - [ ] Storage quota warnings
  - [ ] API rate limits

### ✅ 11. App Store Submission

- [ ] **Prepare Assets**
  - [ ] App Icon (1024x1024)
  - [ ] Screenshots (all required sizes)
  - [ ] App Preview video (optional)
  - [ ] Privacy Policy URL
  - [ ] Support URL

- [ ] **App Store Metadata**
  - [ ] App Name: MirrorMate
  - [ ] Subtitle
  - [ ] Description
  - [ ] Keywords
  - [ ] Category: Productivity / Self-Improvement
  - [ ] Age Rating

- [ ] **Privacy Details**
  - [ ] Data Collection disclosure
  - [ ] Camera usage explanation
  - [ ] Microphone usage explanation
  - [ ] User authentication explanation

- [ ] **Archive & Upload**
  ```
  Xcode → Product → Archive
  Organizer → Distribute App → App Store Connect
  ```

## Post-Deployment Monitoring

### Week 1
- [ ] Monitor sign-up rates
- [ ] Check for crash reports
- [ ] Review edge function logs
- [ ] Monitor OpenAI API usage/costs
- [ ] Check user feedback

### Week 2-4
- [ ] Analyze user retention
- [ ] Review quota usage patterns
- [ ] Optimize AI analysis costs
- [ ] Monitor premium conversion rates
- [ ] Plan feature updates

## Environment Variables Reference

### Supabase Edge Functions (.env)
```bash
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
OPENAI_API_KEY=your_openai_key
```

### iOS App (SupabaseConfig.swift)
```swift
static let url = "https://YOUR_PROJECT.supabase.co"
static let anonKey = "YOUR_ANON_KEY"
static let serviceRoleKey = "YOUR_SERVICE_ROLE_KEY" // Only for testing
```

## Testing Checklist

### Authentication
- [ ] ✅ Sign up with valid email
- [ ] ✅ Sign up with invalid email (should fail)
- [ ] ✅ Sign up with weak password (should warn)
- [ ] ✅ Sign in with correct credentials
- [ ] ✅ Sign in with wrong password (should fail)
- [ ] ✅ Sign out
- [ ] ✅ Password reset email sent
- [ ] ✅ Session persists across app restarts

### Recording & Analysis
- [ ] ✅ Camera permission requested
- [ ] ✅ Microphone permission requested
- [ ] ✅ Record video (10-30 seconds)
- [ ] ✅ Stop recording
- [ ] ✅ Upload video to Supabase
- [ ] ✅ AI analysis completes
- [ ] ✅ Results displayed correctly
- [ ] ✅ Results saved to history

### Quota Management
- [ ] ✅ Free user: 1 analysis/day allowed
- [ ] ✅ Free user: 2nd analysis shows paywall
- [ ] ✅ Quota resets at midnight
- [ ] ✅ Premium user: unlimited analyses
- [ ] ✅ Anonymous user: device-based quota works
- [ ] ✅ Database quota records created
- [ ] ✅ Quota check logs visible

### Premium Features
- [ ] Premium purchase flow works (sandbox)
- [ ] Premium status syncs across devices
- [ ] Premium badge shows in profile
- [ ] Unlimited recordings for premium users
- [ ] Receipt validation works

### UI/UX
- [ ] ✅ Onboarding screen displays correctly
- [ ] ✅ Animations are smooth
- [ ] ✅ Dark mode works properly
- [ ] ✅ Light mode works properly
- [ ] ✅ Haptic feedback on interactions
- [ ] ✅ Error messages are clear
- [ ] ✅ Loading states shown
- [ ] ✅ Success confirmations displayed

## Common Issues & Solutions

### Issue: "User not found" in Edge Functions
**Solution**: Check Authorization header format
```typescript
const authHeader = req.headers.get("Authorization");
// Should be: "Bearer <jwt_token>"
```

### Issue: Quota not updating
**Solution**: Check user_id is being passed correctly
```swift
// In ApiClient.swift
if let session = try? await SupabaseService.shared.client.auth.session {
    authToken = session.accessToken
}
```

### Issue: Video upload fails
**Solution**: Check storage bucket permissions and signed URL generation

### Issue: App crashes on launch
**Solution**: Check Supabase configuration is correct and network is available

## Support Resources

- **Supabase Docs**: https://supabase.com/docs
- **OpenAI API Docs**: https://platform.openai.com/docs
- **SwiftUI Docs**: https://developer.apple.com/documentation/swiftui
- **StoreKit Docs**: https://developer.apple.com/documentation/storekit

---

## 🎉 Ready to Deploy!

Once all items are checked, your app is ready for production deployment!

**Last Updated**: October 17, 2025

