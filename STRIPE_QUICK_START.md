# 🚀 Stripe Checkout - Quick Start Guide

## ✅ What's Already Done:

1. ✅ **Database migration applied** - `stripe_customers` table created
2. ✅ **3 Edge Functions created**:
   - `create-checkout-session`
   - `stripe-webhook`
   - `create-portal-session`
3. ✅ **Premium check functions** updated for Stripe

---

## 📝 YOUR TODO LIST (2 hours total)

### Step 1: Create Stripe Account (10 min)

1. Go to [https://stripe.com/register](https://stripe.com/register)
2. Sign up with email
3. Verify email
4. Fill in business details

### Step 2: Get Stripe Keys (5 min)

1. Go to [Dashboard > API Keys](https://dashboard.stripe.com/apikeys)
2. Copy these 3 things:
   ```
   Publishable Key: pk_test_...
   Secret Key: sk_test_...
   ```

### Step 3: Create $9.99 Product (5 min)

1. Go to [Dashboard > Products](https://dashboard.stripe.com/products)
2. Click "+ Add product"
3. Fill in:
   ```
   Name: MirrorMate Premium
   Price: $9.99 USD
   Billing: Recurring - Monthly
   ```
4. Click "Add pricing options"
5. Under "Free trial":
   ```
   ✅ Enable 7-day free trial
   ```
6. Click "Save product"
7. **COPY THE PRICE ID** (starts with `price_`)

### Step 4: Set Supabase Secrets (3 min)

```bash
cd /Users/khubairnasirm/Desktop/MirrorMate

# Set Stripe keys
npx supabase secrets set STRIPE_SECRET_KEY=sk_test_YOUR_SECRET_KEY
npx supabase secrets set STRIPE_PRICE_ID=price_YOUR_PRICE_ID
```

### Step 5: Deploy Functions (5 min)

```bash
npx supabase functions deploy create-checkout-session
npx supabase functions deploy stripe-webhook --no-verify-jwt
npx supabase functions deploy create-portal-session
```

### Step 6: Set Up Webhook (5 min)

1. Go to [Dashboard > Webhooks](https://dashboard.stripe.com/webhooks)
2. Click "+ Add endpoint"
3. Endpoint URL:
   ```
   https://lchudacxfedkylmjbdsz.supabase.co/functions/v1/stripe-webhook
   ```
4. Select events:
   ```
   ✅ checkout.session.completed
   ✅ customer.subscription.created
   ✅ customer.subscription.updated
   ✅ customer.subscription.deleted
   ✅ invoice.payment_failed
   ```
5. Click "Add endpoint"
6. Copy "Signing secret" (starts with `whsec_`)
7. Set it:
   ```bash
   npx supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_YOUR_SECRET
   ```

### Step 7: Update iOS Code (30 min)

I'll provide the complete iOS code in the next files...

### Step 8: Test (30 min)

1. Build app
2. Tap "Go Premium"
3. Safari opens with Stripe Checkout
4. Use test card: `4242 4242 4242 4242`
5. Any future expiry, any CVC
6. Complete payment
7. Return to app
8. Premium features unlock!

---

## 💳 Test Card Numbers

```
Success: 4242 4242 4242 4242
Decline: 4000 0000 0000 0002
Requires Auth: 4000 0027 6000 3184
```

**Use any:**
- Future expiry date
- Any 3-digit CVC
- Any ZIP code

---

## 🔍 Verify It Works

### Check Supabase:
```sql
-- Check if customer was created
SELECT * FROM stripe_customers;

-- Check if subscription was created
SELECT * FROM subscriptions WHERE status = 'trialing';

-- Check premium status
SELECT is_user_premium('YOUR_USER_ID');
```

### Check Stripe Dashboard:
1. [Customers](https://dashboard.stripe.com/customers) - Should see new customer
2. [Subscriptions](https://dashboard.stripe.com/subscriptions) - Should see active trial
3. [Webhooks](https://dashboard.stripe.com/webhooks) - Should see successful deliveries

---

## 💰 Revenue Comparison

### With Stripe:
```
User pays: $9.99
Stripe fee: $0.59 (2.9% + $0.30)
You get: $9.40 (94%)
```

### If you used Apple:
```
User pays: $9.99
Apple fee: $2.99 (30%)
You get: $6.99 (70%)
```

**You make $2.41 more per user with Stripe!** 🎉

---

## ⚠️ Important Notes

1. **Test Mode**: You're in test mode. No real charges!
2. **Go Live**: When ready, switch to live keys in Stripe Dashboard
3. **Taxes**: Stripe can handle sales tax automatically
4. **Disputes**: Stripe has built-in dispute handling

---

## 🐛 Troubleshooting

### "No signature" error:
- Make sure webhook secret is set correctly
- Redeploy `stripe-webhook` function

### "Product not found":
- Verify `STRIPE_PRICE_ID` is set correctly
- Check price ID in Stripe Dashboard

### Payment doesn't create subscription:
- Check webhook deliveries in Stripe Dashboard
- Look for errors in Supabase Functions logs
- Verify `user_id` is in session metadata

### Premium status not updating:
- Refresh app
- Check `subscriptions` table in Supabase
- Verify `is_user_premium()` function works

---

## 📊 Next Steps

1. ✅ Complete Stripe setup (Steps 1-6 above)
2. Update iOS code (I'll provide this next)
3. Test with test cards
4. Polish paywall UI
5. Go live when ready!

---

**Ready? Start with Step 1: Create your Stripe account!** 🚀

Full documentation: `STRIPE_PAYMENT_PLAN.md`

