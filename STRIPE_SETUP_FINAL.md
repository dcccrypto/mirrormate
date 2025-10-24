# ✅ Stripe Functions Deployed - Final Setup Steps

## 🎉 What's Done:

- ✅ `create-checkout-session` deployed
- ✅ `stripe-webhook` deployed  
- ✅ `create-portal-session` deployed
- ✅ `STRIPE_SECRET_KEY` set

## ⚠️ IMPORTANT: Fix Price ID

You set the **Product ID** (`prod_...`) but we need the **Price ID** (`price_...`).

### Get the Correct Price ID:

1. Go to your Stripe product: [https://dashboard.stripe.com/products/prod_TGNKCJCA5YI3Hm](https://dashboard.stripe.com/products/prod_TGNKCJCA5YI3Hm)

2. Look for the **Pricing** section - you'll see something like:
   ```
   $9.99 / month
   ID: price_1ABC...def    ← THIS is what you need!
   ```

3. Copy that **Price ID** (starts with `price_`)

4. Set it correctly:
```bash
cd /Users/khubairnasirm/Desktop/MirrorMate
npx supabase secrets set STRIPE_PRICE_ID=price_YOUR_ACTUAL_PRICE_ID
```

---

## 📡 Set Up Webhook (CRITICAL!)

Without this, subscriptions won't save to your database!

### Step 1: Add Webhook Endpoint

1. Go to: [https://dashboard.stripe.com/webhooks](https://dashboard.stripe.com/webhooks)

2. Click **"+ Add endpoint"**

3. **Endpoint URL:**
   ```
   https://lchudacxfedkylmjbdsz.supabase.co/functions/v1/stripe-webhook
   ```

4. **Description:** `MirrorMate subscription updates`

5. **Events to send** - Select these 5:
   ```
   ✅ checkout.session.completed
   ✅ customer.subscription.created
   ✅ customer.subscription.updated
   ✅ customer.subscription.deleted
   ✅ invoice.payment_failed
   ```

6. Click **"Add endpoint"**

### Step 2: Get Webhook Secret

1. After creating the endpoint, you'll see:
   ```
   Signing secret: whsec_ABC...xyz
   ```

2. Click **"Reveal"** and copy it

3. Set it in Supabase:
```bash
npx supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_YOUR_WEBHOOK_SECRET
```

### Step 3: Test Webhook

1. In Stripe webhook page, click **"Send test webhook"**
2. Select `checkout.session.completed`
3. Click **"Send test webhook"**
4. You should see: ✅ **200 OK**

If you see an error, check Supabase function logs.

---

## 🧪 Test Your Setup

### Use Stripe Test Mode

Make sure you're in **Test mode** (toggle in top right of Stripe Dashboard).

### Test Card:
```
Card Number: 4242 4242 4242 4242
Expiry: Any future date (e.g., 12/25)
CVC: Any 3 digits (e.g., 123)
ZIP: Any 5 digits (e.g., 12345)
```

### Full Test Flow:

1. **Build iOS app** (we'll add the code next)
2. **Sign in** to your app
3. **Tap "Go Premium"**
4. **Safari opens** with Stripe Checkout
5. **Enter test card:** 4242 4242 4242 4242
6. **Complete payment**
7. **Check Supabase database:**
   ```sql
   SELECT * FROM stripe_customers;
   SELECT * FROM subscriptions;
   SELECT is_user_premium('YOUR_USER_ID');
   ```

---

## 🔍 Verify Everything Works

### Check 1: Supabase Functions
Go to: [https://supabase.com/dashboard/project/lchudacxfedkylmjbdsz/functions](https://supabase.com/dashboard/project/lchudacxfedkylmjbdsz/functions)

You should see:
- ✅ create-checkout-session
- ✅ stripe-webhook  
- ✅ create-portal-session

### Check 2: Secrets Are Set
```bash
cd /Users/khubairnasirm/Desktop/MirrorMate
npx supabase secrets list
```

Should show:
- ✅ STRIPE_SECRET_KEY
- ✅ STRIPE_PRICE_ID (needs to be fixed to price_...)
- ⏳ STRIPE_WEBHOOK_SECRET (needs to be added)

### Check 3: Database
```sql
-- Check tables exist
SELECT * FROM stripe_customers LIMIT 1;
SELECT * FROM subscriptions LIMIT 1;

-- Check functions work
SELECT is_user_premium('00000000-0000-0000-0000-000000000000');
-- Should return: false (no subscriptions yet)
```

---

## 📱 Next: iOS Implementation

Once webhook is set up, I'll provide the complete iOS code:

1. **StripeManager.swift** - Handles checkout
2. **Updated PaywallView.swift** - Beautiful UI with Stripe
3. **URL scheme handling** - Returns user to app after payment

---

## ⚠️ Common Issues & Fixes

### Issue: "Product not found" error
**Fix:** Make sure `STRIPE_PRICE_ID` is set to `price_...` not `prod_...`

### Issue: Payment works but subscription doesn't save
**Fix:** 
1. Check webhook is set up correctly
2. Verify webhook secret is set
3. Look at webhook delivery attempts in Stripe Dashboard

### Issue: "User not authenticated" error
**Fix:** Make sure user is signed in to your app before opening checkout

---

## 📋 Current Status Checklist

- ✅ Stripe account created
- ✅ $9.99 product created
- ✅ Supabase functions deployed
- ✅ STRIPE_SECRET_KEY set
- ⚠️ STRIPE_PRICE_ID needs to be fixed (use `price_` not `prod_`)
- ⏳ STRIPE_WEBHOOK_SECRET needs to be set
- ⏳ Webhook endpoint needs to be added
- ⏳ iOS code needs to be added

---

## 🚀 Quick Command Reference

```bash
# Change to correct directory
cd /Users/khubairnasirm/Desktop/MirrorMate

# Fix price ID (get from Stripe Dashboard first!)
npx supabase secrets set STRIPE_PRICE_ID=price_YOUR_PRICE_ID

# Set webhook secret (get from Stripe webhook page!)
npx supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_YOUR_SECRET

# Check secrets
npx supabase secrets list

# Redeploy if needed
npx supabase functions deploy create-checkout-session
```

---

## 🎯 Immediate Next Steps:

1. **RIGHT NOW:** Get the correct Price ID from your Stripe product
2. **Set it:** `npx supabase secrets set STRIPE_PRICE_ID=price_...`
3. **Add webhook** endpoint in Stripe Dashboard
4. **Set webhook secret:** `npx supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...`
5. **Test webhook** in Stripe Dashboard
6. **Then:** I'll provide iOS code!

---

**Once webhook is set up, you're 90% done! iOS code is just 30 minutes away!** 🎉

