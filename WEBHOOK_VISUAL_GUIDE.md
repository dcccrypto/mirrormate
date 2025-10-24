# 🎯 Visual Guide: Set Up Stripe Webhook

## ❌ Current Situation

```
┌──────────┐                    ┌──────────────┐
│  Stripe  │ ????????????????? │  Your App    │
│          │                    │              │
│ Payment  │                    │ stripe-      │
│ Success! │ No connection!     │ webhook      │
│          │                    │ function     │
│ 💰 $9.99 │                    │ (waiting...) │
└──────────┘                    └──────────────┘
     ❌                               ❌
  No endpoint                  Never receives
  configured                    webhook events
```

**Result:** Payment completes, but subscription never saves!

---

## ✅ What You Need to Do

### Open This URL:
**https://dashboard.stripe.com/test/webhooks**

### You'll See This Page:

```
┌─────────────────────────────────────────────────────┐
│  Stripe Dashboard - Webhooks                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Endpoints receiving events from your account       │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │                                              │  │
│  │  [+] Add endpoint                            │  ← CLICK THIS!
│  │                                              │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  (Empty - no endpoints configured yet)              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 📝 Step-by-Step

### 1. Click "[+] Add endpoint"

### 2. Fill in the Form:

```
┌─────────────────────────────────────────────────────┐
│  Add endpoint                                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Endpoint URL *                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ https://lchudacxfedkylmjbdsz.supabase.co/    │ │ ← COPY THIS!
│  │ functions/v1/stripe-webhook                   │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  Description (optional)                             │
│  ┌───────────────────────────────────────────────┐ │
│  │ MirrorMate subscription webhooks              │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  Events to send                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ [Select events...]                            │ │ ← CLICK THIS!
│  └───────────────────────────────────────────────┘ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 3. Select These 5 Events:

```
┌─────────────────────────────────────────────────────┐
│  Select events to send                              │
├─────────────────────────────────────────────────────┤
│  Search events: [checkout.session.completed]        │
│                                                     │
│  ✅ checkout.session.completed                      │  ← CHECK THIS
│     Occurs when a Checkout Session succeeds         │
│                                                     │
│  ✅ customer.subscription.created                   │  ← CHECK THIS
│     Occurs when a subscription is created           │
│                                                     │
│  ✅ customer.subscription.updated                   │  ← CHECK THIS
│     Occurs when a subscription is updated           │
│                                                     │
│  ✅ customer.subscription.deleted                   │  ← CHECK THIS
│     Occurs when a subscription is canceled          │
│                                                     │
│  ✅ invoice.payment_failed                          │  ← CHECK THIS
│     Occurs when a payment fails                     │
│                                                     │
│  [Add events]                                       │  ← CLICK WHEN DONE
└─────────────────────────────────────────────────────┘
```

### 4. Add Endpoint

Click the **"Add endpoint"** button at the bottom

---

## ✅ After Adding

You'll see your new endpoint:

```
┌─────────────────────────────────────────────────────┐
│  Endpoints                                          │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ✅ https://lchudacxfedkylmjbdsz.supabase.co/...   │
│     MirrorMate subscription webhooks                │
│     5 events • Enabled                              │
│                                                     │
│     Signing secret                                  │
│     whsec_••••••••••••••••  [Reveal]  [Roll]       │
│                                        ↑            │
│                                    ALREADY SET!     │
│                                    (you did this)   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## ✅ After Configuration

```
┌──────────┐    Webhook Event     ┌──────────────┐
│  Stripe  │ ──────────────────→  │  Your App    │
│          │                      │              │
│ Payment  │  POST /stripe-webhook│ stripe-      │
│ Success! │  + signature         │ webhook      │
│          │  + event data        │ function     │
│ 💰 $9.99 │                      │              │
└──────────┘                      └──────┬───────┘
     ✅                                  │
  Webhook sent                           ↓
                              ┌──────────────────┐
                              │  Database        │
                              │  ✅ Subscription │
                              │     saved!       │
                              └──────────────────┘
```

**Result:** Payment completes AND subscription saves!

---

## 🧪 Test It

### In Stripe Webhook Page:

```
┌─────────────────────────────────────────────────────┐
│  [Send test webhook]                                │  ← CLICK THIS
└─────────────────────────────────────────────────────┘
```

Select: **`checkout.session.completed`**

Expected response:
```
✅ 200 OK
Response in 234ms
```

---

## 🎯 The Exact URL to Copy

```
https://lchudacxfedkylmjbdsz.supabase.co/functions/v1/stripe-webhook
```

**Make sure:**
- ✅ No spaces
- ✅ `https://` (not `http://`)
- ✅ Ends with `/stripe-webhook`
- ✅ No trailing slash

---

## 🔍 How to Know It's Working

### After You Pay:

**In Stripe Dashboard:**
```
Webhooks → Your endpoint → Events

Should show:
✅ checkout.session.completed    200 OK    Just now
✅ customer.subscription.created 200 OK    Just now
```

**In Your App Logs:**
```
[Time] ℹ️  INFO [Network] Payment succeeded, checking premium status...
[Time] ℹ️  INFO [Network] ✅ Premium status: true (found 1 active subscriptions)
                                          ↑
                                       THIS!
```

**In Your App:**
```
Profile Screen:
┌─────────────────────┐
│  Your Name          │
│  email@example.com  │
│  👑 Premium         │  ← THIS APPEARS!
└─────────────────────┘
```

---

## ⏱️ How Long Does This Take?

```
Step 1: Open Stripe webhooks          → 10 seconds
Step 2: Click "Add endpoint"           → 5 seconds
Step 3: Paste URL                      → 10 seconds
Step 4: Select 5 events                → 30 seconds
Step 5: Add endpoint                   → 5 seconds
Step 6: Test webhook                   → 10 seconds
─────────────────────────────────────────────────────
Total:                                   70 seconds
```

**LESS THAN 2 MINUTES!**

---

## 🚀 Do This Now

1. Open: **https://dashboard.stripe.com/test/webhooks**
2. Click: **"+ Add endpoint"**
3. Paste URL
4. Select 5 events
5. Click: **"Add endpoint"**
6. Test it
7. Try payment in your app
8. Watch it work! 🎉

---

**This is the LAST thing you need to do!**

Your code is perfect. Your functions are deployed. Your secrets are set.

You just need to tell Stripe where to send the webhooks!

**2 minutes. That's all it takes.** ⏱️

