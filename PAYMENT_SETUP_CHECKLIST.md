# 💳 Payment Setup Checklist - Quick Start

## 🎯 Goal: Implement $9.99/month Premium in 3 Days

---

## Day 1: App Store Connect Setup (2-3 hours)

### ✅ Step 1: Banking & Legal (MUST DO FIRST!)
- [ ] Go to [App Store Connect](https://appstoreconnect.apple.com/)
- [ ] Navigate to **Agreements, Tax, and Banking**
- [ ] Complete **Paid Apps Agreement**
- [ ] Add bank account (for receiving payments)
- [ ] Submit tax forms (W-8 or W-9)
- [ ] ⏳ **Wait 24-48h for approval**

### ✅ Step 2: Create Subscription
- [ ] Go to your app > **Subscriptions**
- [ ] Create Subscription Group: **"MirrorMate Premium"**
- [ ] Add subscription:
  ```
  Product ID: com.mirrormate.premium.monthly
  Price: $9.99 USD
  Duration: 1 month
  ```
- [ ] Add **7-day free trial**:
  ```
  Type: Free Trial
  Duration: 7 days
  Eligible: New subscribers only
  ```
- [ ] Fill in description and promotional images
- [ ] Submit for review
- [ ] ⏳ **Wait 24-48h for approval**

---

## Day 2: Database Setup (2 hours)

### ✅ Step 1: Apply Migration
```bash
# From your project directory
npx supabase migration up
```

OR use Supabase MCP:
```
The migration file is already created at:
supabase/migrations/20250119000006_add_subscriptions.sql
```

### ✅ Step 2: Verify Tables
Run this query in Supabase SQL Editor:
```sql
SELECT * FROM subscriptions LIMIT 1;
SELECT is_user_premium('YOUR_USER_ID');
```

Should work without errors (even if empty).

---

## Day 3: iOS Implementation (5 hours)

### ✅ Step 1: Update Product ID (5 min)
In `StoreKitManager.swift`, line 36:
```swift
// OLD
private let premiumProductId = "mm_plus_monthly"

// NEW (use your real product ID from App Store Connect)
private let premiumProductId = "com.mirrormate.premium.monthly"
```

### ✅ Step 2: Implement Supabase Sync (Already Done!)
The `syncSubscriptionToSupabase()` method is already in the updated code.

### ✅ Step 3: Test on Simulator (30 min)
1. Create `MirrorMate.storekit` file in Xcode
2. Add your subscription product
3. Run app and test purchase flow
4. Verify premium features unlock

### ✅ Step 4: Sandbox Testing (1 hour)
1. Create sandbox tester in App Store Connect
2. Test on real device with sandbox account
3. Verify:
   - [ ] Purchase works
   - [ ] 7-day trial starts
   - [ ] Premium features unlock
   - [ ] Data syncs to Supabase
   - [ ] Restore purchases works

---

## Premium Features to Implement

### Easy Wins (Already Have Data!)

#### 1. Lock Detailed Insights (30 min)
```swift
// In ResultsView.swift, wrap premium sections:
if StoreKitManager.shared.isPremium {
    // Show vocal analysis
    // Show body language
    // Show practice exercises
} else {
    PremiumLockedCard(
        title: "Vocal Analysis",
        description: "Get detailed insights on pace, clarity, and more"
    )
}
```

#### 2. Unlimited Analyses (Already Done!)
`QuotaService` already checks `isPremium`.

#### 3. Progress Tracking (1 hour)
```swift
// Add to HistoryView
if StoreKitManager.shared.isPremium {
    ProgressChartsView(sessions: sessionStore.sessions)
} else {
    PremiumUpsellCard()
}
```

---

## Testing Checklist

### Before Launch:
- [ ] Sandbox purchase works
- [ ] Free trial starts correctly
- [ ] Premium features unlock immediately
- [ ] Data syncs to Supabase
- [ ] Restore purchases works
- [ ] Subscription info shows in Profile
- [ ] Handles payment failure gracefully
- [ ] Works offline (checks local premium status)

### Edge Cases:
- [ ] App killed during purchase
- [ ] Poor network during purchase
- [ ] Multiple devices, same subscription
- [ ] Subscription expires while app is open

---

## Launch Day Checklist

### Morning:
- [ ] Verify subscription is approved in App Store Connect
- [ ] Deploy updated iOS app
- [ ] Test production purchase immediately
- [ ] Monitor Supabase logs for sync errors

### During Day:
- [ ] Watch crash reports (especially payment-related)
- [ ] Monitor conversion rate
- [ ] Respond to user questions quickly
- [ ] Check revenue in App Store Connect

### Evening:
- [ ] Review analytics
- [ ] Check for any payment errors
- [ ] Plan optimizations for tomorrow

---

## Quick Commands

### Apply Database Migration:
```bash
cd /Users/khubairnasirm/Desktop/MirrorMate
npx supabase migration up
```

### Test Build:
```bash
xcodebuild build -scheme MirrorMate -destination 'generic/platform=iOS'
```

### Check Subscription Status (SQL):
```sql
SELECT 
    user_id,
    status,
    expires_at,
    is_trial,
    EXTRACT(DAY FROM expires_at - NOW()) as days_remaining
FROM subscriptions
WHERE status = 'active';
```

---

## Revenue Tracking

### Week 1 Goals:
- 10 premium subscribers
- $69.90 MRR (Monthly Recurring Revenue)
- 5% conversion rate

### Month 1 Goals:
- 50 premium subscribers
- $349.50 MRR
- 7% conversion rate

### Month 3 Goals:
- 200 premium subscribers
- $1,398 MRR
- 10% conversion rate

---

## Support Quick Answers

**Q: How do I cancel?**
Settings > [Your Name] > Subscriptions > MirrorMate Premium > Cancel

**Q: Do I get charged during trial?**
No, cancel anytime in first 7 days.

**Q: Multiple devices?**
Yes, works on all devices with same Apple ID.

**Q: Refund?**
Contact Apple Support within 14 days.

---

## Next Steps

1. **TODAY**: Set up App Store Connect (banking + subscription)
2. **TOMORROW**: Apply database migration, test locally
3. **DAY 3**: Update iOS code, test in sandbox
4. **DAY 4**: Polish paywall UI, test thoroughly
5. **DAY 5**: Submit to App Store
6. **NEXT WEEK**: Launch! 🚀

---

## 📄 Full Documentation

See `PAYMENT_INTEGRATION_PLAN.md` for complete details.

---

**Estimated Total Time:** 20 hours of work + App Store approvals

**Ready to start? Begin with App Store Connect banking setup!** 💰

