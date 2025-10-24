# 🎨 Stripe Payment Flow - Visual Guide

## 🔄 Complete Payment Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER JOURNEY                             │
└─────────────────────────────────────────────────────────────────┘

1️⃣ USER OPENS APP
   ┌──────────────┐
   │  MirrorMate  │  ← User signed in
   │     App      │
   └──────┬───────┘
          │
          v
   Profile Screen
   Shows: "Upgrade to Premium"


2️⃣ USER CLICKS "START PREMIUM"
   ┌──────────────┐
   │  PaywallView │  ← User taps button
   │   $9.99/mo   │
   └──────┬───────┘
          │
          v
   StripeManager.startCheckout()
          │
          v
   ┌──────────────────────────────────┐
   │ create-checkout-session Function │  ← Supabase Edge Function
   │   (Supabase Backend)             │
   └──────┬───────────────────────────┘
          │
          v
   Stripe API creates session
          │
          v
   Returns checkout URL


3️⃣ SAFARI OPENS WITH STRIPE
   ┌──────────────┐
   │    Safari    │  ← Opens automatically
   │   Browser    │
   └──────┬───────┘
          │
          v
   ┌─────────────────────────┐
   │  Stripe Checkout Page   │
   │  ┌───────────────────┐  │
   │  │ Card: ████ ████   │  │  ← User enters card
   │  │ Exp:  12/25       │  │
   │  │ CVC:  123         │  │
   │  └───────────────────┘  │
   │  [Pay $9.99]           │  ← User clicks
   └─────────┬───────────────┘
             │
             v


4️⃣ STRIPE PROCESSES PAYMENT
   ┌──────────────┐
   │    Stripe    │  ← Charges card
   │   Servers    │
   └──────┬───────┘
          │
          ├──────────────────────┐
          │                      │
          v                      v
   Payment Success         Webhook Event
          │                      │
          │                      v
          │               ┌──────────────────┐
          │               │ stripe-webhook   │  ← Supabase Function
          │               │  Edge Function   │
          │               └──────┬───────────┘
          │                      │
          │                      v
          │               ┌──────────────────┐
          │               │   Database:      │
          │               │ ✅ stripe_customers
          │               │ ✅ subscriptions │
          │               └──────────────────┘
          │
          v
   Redirect to: mirrormate://payment-success


5️⃣ BACK TO APP
   ┌──────────────┐
   │  MirrorMate  │  ← Safari redirects
   │     App      │
   └──────┬───────┘
          │
          v
   MirrorMateApp.onOpenURL()
          │
          v
   StripeManager.handleDeepLink()
          │
          v
   Check: is_user_premium()
          │
          v
   ✅ User is Premium!
          │
          v
   ┌──────────────┐
   │  Crown Badge │  ← Shows in profile
   │    Appears   │
   └──────────────┘


6️⃣ UNLIMITED ACCESS
   ┌──────────────┐
   │   Record     │  ← No quota limit!
   │   Videos     │
   └──────────────┘
```

---

## 📊 Database Changes

```
BEFORE PAYMENT:
┌─────────────┐
│   users     │
├─────────────┤
│ id: abc-123 │
│ email: ...  │
└─────────────┘

┌─────────────┐
│ user_quotas │
├─────────────┤
│ free: 3/day │  ← Limited
└─────────────┘


AFTER PAYMENT:
┌─────────────────────────┐
│   stripe_customers      │
├─────────────────────────┤
│ id: abc-123             │
│ stripe_customer_id:     │
│   cus_ABC123xyz         │  ← Stripe ID
└─────────────────────────┘

┌─────────────────────────┐
│   subscriptions         │
├─────────────────────────┤
│ user_id: abc-123        │
│ stripe_subscription_id: │
│   sub_XYZ789abc         │
│ status: active          │  ← Premium!
│ current_period_end:     │
│   2025-11-19            │
└─────────────────────────┘

┌─────────────┐
│ user_quotas │
├─────────────┤
│ unlimited   │  ← No limit!
└─────────────┘
```

---

## 🔐 Webhook Security

```
STRIPE WEBHOOK DELIVERY:

1. Payment completes
   ↓
2. Stripe signs event with secret
   ↓
3. Sends to: https://lchudacxfedkylmjbdsz.supabase.co/functions/v1/stripe-webhook
   ↓
4. stripe-webhook Function verifies signature
   ↓
5. If valid, saves to database
   ↓
6. Returns 200 OK to Stripe


WEBHOOK PAYLOAD:
{
  "type": "checkout.session.completed",
  "data": {
    "customer": "cus_ABC123",
    "subscription": "sub_XYZ789",
    "metadata": {
      "user_id": "abc-123-..."
    }
  }
}


VERIFICATION:
┌──────────────────┐
│  Stripe Sends:   │
│  - Event data    │
│  - Signature     │
└────────┬─────────┘
         │
         v
┌──────────────────┐
│ Your Function:   │
│ - Verify sig     │  ← Uses STRIPE_WEBHOOK_SECRET
│ - Check user_id  │
│ - Save to DB     │
└──────────────────┘
```

---

## 📱 iOS Deep Links

```
DEEP LINK FLOW:

Safari                          iOS App
  │                               │
  │  mirrormate://payment-success │
  ├───────────────────────────────>
  │                               │
  │                          onOpenURL()
  │                               │
  │                          StripeManager
  │                          .handleDeepLink()
  │                               │
  │                          Wait 2 seconds
  │                          (for webhook)
  │                               │
  │                          checkPremiumStatus()
  │                               │
  │                          Database query
  │                               │
  │                          isPremium = true
  │                               │
  │                          HapticFeedback
  │                               │
  │                          UI updates ✅


REGISTERED URL SCHEMES (Info.plist):
┌─────────────────────────────┐
│ CFBundleURLSchemes          │
│  - mirrormate                │  ← App receives these URLs
└─────────────────────────────┘

STRIPE REDIRECT URLS (in create-checkout-session):
┌─────────────────────────────┐
│ success_url:                │
│   mirrormate://payment-success
│                             │
│ cancel_url:                 │
│   mirrormate://payment-cancel
└─────────────────────────────┘
```

---

## 🎯 Key Integration Points

```
┌────────────────────────────────────────────────────────┐
│                    STRIPE MANAGER                      │
│                                                        │
│  checkPremiumStatus()                                 │
│    ↓                                                   │
│  Calls: is_user_premium(user_id) RPC function        │
│    ↓                                                   │
│  Returns: true/false                                  │
│    ↓                                                   │
│  Updates: @Published isPremium                        │
│                                                        │
│  startCheckout()                                      │
│    ↓                                                   │
│  Calls: create-checkout-session Edge Function         │
│    ↓                                                   │
│  Gets: Stripe Checkout URL                            │
│    ↓                                                   │
│  Opens: Safari with URL                               │
│                                                        │
│  openCustomerPortal()                                 │
│    ↓                                                   │
│  Calls: create-portal-session Edge Function           │
│    ↓                                                   │
│  Gets: Stripe Portal URL                              │
│    ↓                                                   │
│  Opens: Safari with URL                               │
│                                                        │
│  handleDeepLink(url)                                  │
│    ↓                                                   │
│  If: payment-success → checkPremiumStatus()          │
│  If: payment-cancel → Log cancellation                │
└────────────────────────────────────────────────────────┘
```

---

## 🔄 Subscription Lifecycle

```
NEW USER
   │
   v
┌─────────────┐
│   Sign Up   │
└──────┬──────┘
       │
       v
┌─────────────┐
│  Free User  │  ← 3 analyses/day
└──────┬──────┘
       │
       │ Clicks "Start Premium"
       v
┌─────────────┐
│   Paywall   │
└──────┬──────┘
       │
       │ Enters card & pays
       v
┌─────────────┐
│   Premium   │  ← Unlimited analyses
└──────┬──────┘
       │
       ├── After 30 days ──┐
       │                   │
       v                   v
  Auto-renew         Cancel anytime
       │                   │
       v                   v
  Stays premium    ┌─────────────┐
                   │ Ends at EOB │  ← End of billing
                   └──────┬──────┘
                          │
                          v
                   ┌─────────────┐
                   │  Free User  │  ← Back to 3/day
                   └─────────────┘


SUBSCRIPTION STATUSES:
┌────────────────────────────────────────┐
│ active        → User has access        │
│ past_due      → Payment failed         │
│ canceled      → Cancelled, runs to end │
│ unpaid        → No payment method      │
│ incomplete    → Payment pending        │
└────────────────────────────────────────┘
```

---

## 🧪 Testing Flow

```
TEST ENVIRONMENT:

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Stripe     │     │   Supabase   │     │  iOS App     │
│ Test Mode    │ ←───│   Staging    │ ←───│  Simulator   │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                     │
       │                    │                     │
Test Cards           Real Functions         Real Code
4242 4242...         Real Database          Real UI


PRODUCTION:

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Stripe     │     │   Supabase   │     │  iOS App     │
│  Live Mode   │ ←───│  Production  │ ←───│  App Store   │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                     │
       │                    │                     │
Real Cards           Real Functions         Real Code
1234 5678...         Real Database          Real UI
```

---

## 📈 Revenue Flow

```
PAYMENT DAY 1:
User pays $9.99
    ↓
Stripe fee: -$0.59 (2.9% + $0.30)
    ↓
Your balance: $9.40
    ↓
Payout in 2 days


DAY 3:
┌──────────────────┐
│  Your Bank       │  ← $9.40 arrives
│  Account         │
└──────────────────┘


EVERY MONTH:
$9.99 charge
-$0.59 fee
-------
$9.40 profit per user


1,000 SUBSCRIBERS:
$9.99 × 1,000 = $9,990/month
-$0.59 × 1,000 = -$590 fees
─────────────────────────────
$9,400/month net
$112,800/year net


VS APPLE (30% CUT):
$9.99 × 70% × 1,000 = $6,993/month
$83,916/year net

STRIPE ADVANTAGE: +$28,884/year 🎉
```

---

## ⚡ Quick Reference

```
TEST CARD:
┌─────────────────────┐
│ 4242 4242 4242 4242 │  ← Always succeeds
│ 12/25               │
│ 123                 │
└─────────────────────┘


IMPORTANT URLS:
┌─────────────────────────────────────────────────────┐
│ Stripe Dashboard:                                   │
│  https://dashboard.stripe.com                       │
│                                                     │
│ Webhooks:                                           │
│  https://dashboard.stripe.com/webhooks              │
│                                                     │
│ Supabase Functions:                                 │
│  https://supabase.com/dashboard/project/            │
│  lchudacxfedkylmjbdsz/functions                    │
│                                                     │
│ Webhook Endpoint:                                   │
│  https://lchudacxfedkylmjbdsz.supabase.co/         │
│  functions/v1/stripe-webhook                        │
└─────────────────────────────────────────────────────┘


SECRETS TO SET:
┌─────────────────────────────────────────────────────┐
│ ✅ STRIPE_SECRET_KEY       (already set)            │
│ ⚠️  STRIPE_PRICE_ID         (needs fixing)          │
│ ⏳ STRIPE_WEBHOOK_SECRET   (needs adding)          │
└─────────────────────────────────────────────────────┘
```

---

## 🎯 Success Checklist

```
[ ] Get Price ID from Stripe (starts with price_)
[ ] Set STRIPE_PRICE_ID in Supabase
[ ] Add webhook in Stripe Dashboard
[ ] Set STRIPE_WEBHOOK_SECRET in Supabase
[ ] Test webhook sends 200 OK
[ ] Run iOS app
[ ] Click "Start Premium"
[ ] Safari opens
[ ] Enter test card: 4242 4242 4242 4242
[ ] Complete payment
[ ] Return to app
[ ] See premium badge
[ ] Try recording (no quota)
[ ] Check database has subscription
[ ] 🎉 WORKING!
```

---

This visual guide shows exactly how your payment system works!
Each component talks to the next in a secure, tested flow.

**Ready to accept real payments in 10 minutes!** 🚀

