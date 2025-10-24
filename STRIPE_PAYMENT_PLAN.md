# 💳 Stripe Checkout Integration - $9.99/month

**Date:** October 19, 2025  
**Payment Method:** Stripe Checkout (Web-based, no Apple restrictions)  
**Plan:** Single tier at $9.99/month with 7-day free trial

---

## 🎯 Why Stripe Checkout?

### ✅ **Advantages:**
1. **No Apple Developer account needed** - Start immediately!
2. **No Apple's 30% cut** - You keep 97% (Stripe takes 2.9% + $0.30)
3. **More flexibility** - Custom pricing, trials, coupons
4. **Web-based** - Apple can't reject it
5. **Works everywhere** - Not just iOS
6. **Faster setup** - No App Store approval needed

### ⚠️ **Considerations:**
1. Leaves app temporarily (opens Safari)
2. Requires backend server (we'll use Supabase Edge Functions!)
3. Need to handle webhooks for subscription updates

**Bottom Line:** Perfect for getting started quickly and keeping more revenue!

---

## 📋 Implementation Plan

### Architecture:
```
iOS App → Supabase Edge Function → Stripe API → Stripe Checkout (Safari)
         ↓
User completes payment
         ↓
Stripe Webhook → Supabase Edge Function → Update Database
         ↓
iOS App checks premium status → Unlocks features
```

---

## 1. Stripe Account Setup (15 minutes)

### Step 1.1: Create Stripe Account
1. Go to [https://stripe.com](https://stripe.com)
2. Click **Sign Up**
3. Fill in:
   - Email
   - Business name: "MirrorMate"
   - Country
4. Verify email

### Step 1.2: Get API Keys
1. Go to [Dashboard > Developers > API Keys](https://dashboard.stripe.com/apikeys)
2. Copy:
   - **Publishable key** (starts with `pk_test_`)
   - **Secret key** (starts with `sk_test_`)
3. Save these securely!

### Step 1.3: Create Subscription Product
1. Go to [Dashboard > Products](https://dashboard.stripe.com/products)
2. Click **+ Add product**
3. Fill in:
   ```
   Name: MirrorMate Premium
   Description: Unlimited analyses, detailed insights, progress tracking
   Pricing model: Recurring
   Price: $9.99 USD
   Billing period: Monthly
   ```
4. Click **Add free trial**:
   ```
   Trial period: 7 days
   ```
5. Click **Save product**
6. Copy the **Price ID** (starts with `price_`)

### Step 1.4: Set Up Webhook
1. Go to [Dashboard > Developers > Webhooks](https://dashboard.stripe.com/webhooks)
2. Click **+ Add endpoint**
3. Endpoint URL: `https://YOUR_PROJECT_ID.supabase.co/functions/v1/stripe-webhook`
   - We'll create this function next!
4. Select events to listen to:
   ```
   ✅ checkout.session.completed
   ✅ customer.subscription.created
   ✅ customer.subscription.updated
   ✅ customer.subscription.deleted
   ✅ invoice.payment_failed
   ```
5. Copy the **Webhook signing secret** (starts with `whsec_`)

---

## 2. Supabase Edge Functions (2 hours)

We'll create 2 Edge Functions:
1. `create-checkout-session` - Creates Stripe Checkout session
2. `stripe-webhook` - Handles subscription updates

### Step 2.1: Set Stripe Environment Variables

```bash
# Set your Stripe keys in Supabase
npx supabase secrets set STRIPE_SECRET_KEY=sk_test_YOUR_KEY
npx supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_YOUR_SECRET
npx supabase secrets set STRIPE_PRICE_ID=price_YOUR_PRICE_ID
```

### Step 2.2: Create Checkout Session Function

Create file: `supabase/functions/create-checkout-session/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14.11.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Get authenticated user
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      throw new Error("User not authenticated");
    }

    // Initialize Stripe
    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
      httpClient: Stripe.createFetchHttpClient(),
    });

    // Check if customer already exists
    const { data: existingCustomer } = await supabase
      .from("stripe_customers")
      .select("stripe_customer_id")
      .eq("user_id", user.id)
      .single();

    let customerId = existingCustomer?.stripe_customer_id;

    // Create Stripe customer if doesn't exist
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        metadata: {
          supabase_user_id: user.id,
        },
      });
      customerId = customer.id;

      // Store customer ID in database
      await supabase.from("stripe_customers").insert({
        user_id: user.id,
        stripe_customer_id: customerId,
      });
    }

    // Create Checkout Session
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      line_items: [
        {
          price: Deno.env.get("STRIPE_PRICE_ID"),
          quantity: 1,
        },
      ],
      mode: "subscription",
      success_url: `mirrormate://payment-success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `mirrormate://payment-cancel`,
      subscription_data: {
        trial_period_days: 7,
        metadata: {
          supabase_user_id: user.id,
        },
      },
      metadata: {
        supabase_user_id: user.id,
      },
    });

    return new Response(
      JSON.stringify({
        sessionId: session.id,
        url: session.url,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Error creating checkout session:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
```

### Step 2.3: Create Webhook Handler Function

Create file: `supabase/functions/stripe-webhook/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14.11.0?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";

serve(async (req) => {
  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return new Response("No signature", { status: 400 });
  }

  try {
    const body = await req.text();
    const event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      webhookSecret,
      undefined,
      Stripe.createSubtleCryptoProvider()
    );

    console.log(`Received event: ${event.type}`);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId = session.metadata?.supabase_user_id;
        
        if (!userId) break;

        // Get subscription details
        const subscription = await stripe.subscriptions.retrieve(
          session.subscription as string
        );

        await supabase.from("subscriptions").insert({
          user_id: userId,
          stripe_subscription_id: subscription.id,
          stripe_customer_id: subscription.customer as string,
          status: subscription.status,
          price_id: subscription.items.data[0].price.id,
          quantity: subscription.items.data[0].quantity,
          current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
          current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
          trial_end: subscription.trial_end ? new Date(subscription.trial_end * 1000).toISOString() : null,
          cancel_at_period_end: subscription.cancel_at_period_end,
        });

        console.log(`Subscription created for user ${userId}`);
        break;
      }

      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription;
        const userId = subscription.metadata?.supabase_user_id;

        if (!userId) break;

        await supabase
          .from("subscriptions")
          .update({
            status: subscription.status,
            current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
            current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
            trial_end: subscription.trial_end ? new Date(subscription.trial_end * 1000).toISOString() : null,
            cancel_at_period_end: subscription.cancel_at_period_end,
            canceled_at: subscription.canceled_at ? new Date(subscription.canceled_at * 1000).toISOString() : null,
          })
          .eq("stripe_subscription_id", subscription.id);

        console.log(`Subscription updated for user ${userId}`);
        break;
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;

        await supabase
          .from("subscriptions")
          .update({
            status: "canceled",
            canceled_at: new Date().toISOString(),
          })
          .eq("stripe_subscription_id", subscription.id);

        console.log(`Subscription deleted: ${subscription.id}`);
        break;
      }

      case "invoice.payment_failed": {
        const invoice = event.data.object as Stripe.Invoice;
        const subscriptionId = invoice.subscription as string;

        await supabase
          .from("subscriptions")
          .update({
            status: "past_due",
          })
          .eq("stripe_subscription_id", subscriptionId);

        console.log(`Payment failed for subscription: ${subscriptionId}`);
        break;
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Webhook error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400 }
    );
  }
});
```

### Step 2.4: Deploy Functions

```bash
# Deploy both functions
npx supabase functions deploy create-checkout-session
npx supabase functions deploy stripe-webhook --no-verify-jwt
```

---

## 3. Database Schema Updates

Add Stripe-specific tables:

```sql
-- Create stripe_customers table
CREATE TABLE IF NOT EXISTS stripe_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    stripe_customer_id TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Update subscriptions table for Stripe
ALTER TABLE subscriptions
ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT,
ADD COLUMN IF NOT EXISTS price_id TEXT,
ADD COLUMN IF NOT EXISTS quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS current_period_start TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS current_period_end TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS trial_end TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS cancel_at_period_end BOOLEAN DEFAULT false;

-- Update status check to use Stripe fields
DROP FUNCTION IF EXISTS is_user_premium(UUID);
CREATE OR REPLACE FUNCTION is_user_premium(check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM subscriptions
        WHERE user_id = check_user_id
        AND status IN ('active', 'trialing')
        AND (current_period_end > NOW() OR current_period_end IS NULL)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE stripe_customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own stripe customer"
    ON stripe_customers FOR SELECT
    USING (auth.uid() = user_id);
```

---

## 4. iOS Implementation (3 hours)

### Step 4.1: Add URL Scheme to Info.plist

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>mirrormate</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.mirrormate.app</string>
    </dict>
</array>
```

### Step 4.2: Create StripeManager

Create file: `MirrorMate/Services/StripeManager.swift`

```swift
import Foundation
import Supabase

@MainActor
final class StripeManager: ObservableObject {
    static let shared = StripeManager()
    
    @Published var isPremium: Bool = false
    @Published var subscriptionInfo: StripeSubscriptionInfo?
    @Published var isLoading: Bool = false
    
    private let client = SupabaseService.shared.client
    
    private init() {
        Task { await checkPremiumStatus() }
    }
    
    // MARK: - Check Premium Status
    
    func checkPremiumStatus() async {
        guard let userId = AuthService.shared.userId else {
            isPremium = false
            return
        }
        
        do {
            struct PremiumCheck: Codable {
                let is_premium: Bool
            }
            
            // Call Supabase function
            let result: [PremiumCheck] = try await client.rpc(
                "is_user_premium",
                params: ["check_user_id": userId.uuidString]
            ).execute().value
            
            isPremium = result.first?.is_premium ?? false
            
            // Fetch subscription details
            await fetchSubscriptionInfo()
            
            AppLog.info("Premium status: \(isPremium)", category: .general)
        } catch {
            AppLog.error("Error checking premium: \(error)", category: .general)
            isPremium = false
        }
    }
    
    private func fetchSubscriptionInfo() async {
        guard let userId = AuthService.shared.userId else { return }
        
        do {
            struct SubscriptionResponse: Codable {
                let status: String
                let current_period_end: String?
                let trial_end: String?
                let cancel_at_period_end: Bool
            }
            
            let response: [SubscriptionResponse] = try await client
                .from("subscriptions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            if let sub = response.first {
                let dateFormatter = ISO8601DateFormatter()
                
                subscriptionInfo = StripeSubscriptionInfo(
                    status: sub.status,
                    currentPeriodEnd: sub.current_period_end.flatMap { dateFormatter.date(from: $0) },
                    trialEnd: sub.trial_end.flatMap { dateFormatter.date(from: $0) },
                    cancelAtPeriodEnd: sub.cancel_at_period_end
                )
            }
        } catch {
            AppLog.error("Error fetching subscription info: \(error)", category: .general)
        }
    }
    
    // MARK: - Create Checkout Session
    
    func startCheckout() async throws -> URL {
        isLoading = true
        defer { isLoading = false }
        
        struct CheckoutResponse: Codable {
            let sessionId: String
            let url: String
        }
        
        do {
            let response: CheckoutResponse = try await client.functions
                .invoke("create-checkout-session")
                .execute()
                .value
            
            guard let url = URL(string: response.url) else {
                throw StripeError.invalidURL
            }
            
            AppLog.info("Checkout session created: \(response.sessionId)", category: .general)
            return url
        } catch {
            AppLog.error("Checkout error: \(error)", category: .general)
            throw StripeError.checkoutFailed
        }
    }
    
    // MARK: - Manage Subscription
    
    func openCustomerPortal() async throws -> URL {
        // We'll create this Edge Function next
        struct PortalResponse: Codable {
            let url: String
        }
        
        let response: PortalResponse = try await client.functions
            .invoke("create-portal-session")
            .execute()
            .value
        
        guard let url = URL(string: response.url) else {
            throw StripeError.invalidURL
        }
        
        return url
    }
}

// MARK: - Models

struct StripeSubscriptionInfo {
    let status: String
    let currentPeriodEnd: Date?
    let trialEnd: Date?
    let cancelAtPeriodEnd: Bool
    
    var isInTrial: Bool {
        guard let trialEnd = trialEnd else { return false }
        return trialEnd > Date()
    }
    
    var daysRemaining: Int? {
        guard let endDate = currentPeriodEnd else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day
        return max(0, days ?? 0)
    }
    
    var formattedEndDate: String {
        guard let endDate = currentPeriodEnd else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: endDate)
    }
}

enum StripeError: LocalizedError {
    case invalidURL
    case checkoutFailed
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid checkout URL"
        case .checkoutFailed:
            return "Failed to create checkout session"
        case .notAuthenticated:
            return "Please sign in to subscribe"
        }
    }
}
```

### Step 4.3: Update PaywallView for Stripe

```swift
// MirrorMate/Views/PaywallView.swift

import SwiftUI
import SafariServices

struct PaywallView: View {
    @StateObject private var stripeManager = StripeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingSafari = false
    @State private var checkoutURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.accentGradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: AppTheme.Colors.accent.opacity(0.4), radius: 20)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .padding(.top, AppTheme.Spacing.xl)
                        
                        Text("MirrorMate Premium")
                            .font(AppTheme.Fonts.largeTitle())
                            .foregroundColor(AppTheme.Colors.contrast)
                        
                        Text("Unlock unlimited analyses and advanced insights")
                            .font(AppTheme.Fonts.body())
                            .foregroundColor(AppTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                    
                    // Features List
                    VStack(spacing: AppTheme.Spacing.md) {
                        PaywallFeatureRow(
                            icon: "infinity",
                            title: "Unlimited Analyses",
                            description: "Record and analyze as many videos as you want"
                        )
                        
                        PaywallFeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Advanced Analytics",
                            description: "15+ detailed metrics on vocal & body language"
                        )
                        
                        PaywallFeatureRow(
                            icon: "lightbulb.fill",
                            title: "Practice Exercises",
                            description: "Get 3 actionable exercises after each analysis"
                        )
                        
                        PaywallFeatureRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Progress Tracking",
                            description: "Watch your confidence grow over time"
                        )
                        
                        PaywallFeatureRow(
                            icon: "doc.text.fill",
                            title: "Export Reports",
                            description: "Download professional PDF reports"
                        )
                        
                        PaywallFeatureRow(
                            icon: "sparkles",
                            title: "Priority Support",
                            description: "Get help when you need it most"
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    
                    // Pricing
                    VStack(spacing: AppTheme.Spacing.lg) {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Text("$9.99")
                                .font(AppTheme.Fonts.title())
                                .foregroundColor(AppTheme.Colors.contrast)
                            
                            Text("per month")
                                .font(AppTheme.Fonts.subheadline())
                                .foregroundColor(AppTheme.Colors.secondaryText)
                            
                            Text("7-day free trial • Cancel anytime")
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                        .padding(.vertical, AppTheme.Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.secondaryBackground)
                        .cornerRadius(AppTheme.CornerRadius.lg)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        
                        // Subscribe Button
                        Button(action: {
                            Task { await handleCheckout() }
                        }) {
                            HStack {
                                if stripeManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "crown.fill")
                                    Text("Start Free Trial")
                                }
                            }
                        }
                        .primaryButtonStyle(isLoading: stripeManager.isLoading)
                        .disabled(stripeManager.isLoading)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        
                        // Fine Print
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("• No charge during 7-day trial")
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.tertiaryText)
                            
                            Text("• Cancel anytime from Stripe Customer Portal")
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.tertiaryText)
                            
                            Text("• Subscription auto-renews at $9.99/month")
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.tertiaryText)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.bottom, AppTheme.Spacing.xxl)
                    }
                }
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                        HapticFeedback.light.trigger()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.Colors.contrast)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingSafari) {
                if let url = checkoutURL {
                    SafariView(url: url)
                }
            }
        }
    }
    
    private func handleCheckout() async {
        do {
            let url = try await stripeManager.startCheckout()
            checkoutURL = url
            showingSafari = true
            HapticFeedback.success.trigger()
        } catch {
            HapticFeedback.error.trigger()
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// SafariView wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}
```

### Step 4.4: Handle Payment Callbacks

Add to `MirrorMateApp.swift`:

```swift
import SwiftUI

@main
struct MirrorMateApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var sessionStore = SessionStore.shared
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
                    .environmentObject(sessionStore)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
            } else {
                OnboardingView()
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "mirrormate" else { return }
        
        switch url.host {
        case "payment-success":
            // Refresh premium status
            Task {
                await StripeManager.shared.checkPremiumStatus()
            }
            AppLog.info("Payment successful", category: .general)
            
        case "payment-cancel":
            AppLog.info("Payment cancelled", category: .general)
            
        default:
            break
        }
    }
}
```

---

## 5. Deploy & Test (1 hour)

### Step 5.1: Deploy Functions
```bash
npx supabase functions deploy create-checkout-session
npx supabase functions deploy stripe-webhook --no-verify-jwt
```

### Step 5.2: Update Stripe Webhook URL
1. Go to [Stripe Dashboard > Webhooks](https://dashboard.stripe.com/webhooks)
2. Update endpoint URL to: `https://YOUR_PROJECT_ID.supabase.co/functions/v1/stripe-webhook`
3. Test webhook with "Send test webhook" button

### Step 5.3: Test Flow
1. Build and run app
2. Navigate to paywall
3. Click "Start Free Trial"
4. Complete Stripe Checkout in Safari
5. Return to app
6. Verify premium features unlock

---

## 6. Customer Portal (Manage Subscription)

Create `supabase/functions/create-portal-session/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14.11.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) throw new Error("Not authenticated");

    // Get customer ID
    const { data: customer } = await supabase
      .from("stripe_customers")
      .select("stripe_customer_id")
      .eq("user_id", user.id)
      .single();

    if (!customer) throw new Error("No subscription found");

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
      httpClient: Stripe.createFetchHttpClient(),
    });

    // Create portal session
    const session = await stripe.billingPortal.sessions.create({
      customer: customer.stripe_customer_id,
      return_url: "mirrormate://settings",
    });

    return new Response(
      JSON.stringify({ url: session.url }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
```

Deploy:
```bash
npx supabase functions deploy create-portal-session
```

---

## 7. Revenue Comparison: Stripe vs Apple

### Apple In-App Purchase:
```
User pays: $9.99
Apple takes: $2.99 (30%)
You receive: $6.99 (70%)
```

### Stripe:
```
User pays: $9.99
Stripe takes: $0.59 (2.9% + $0.30)
You receive: $9.40 (94%)
```

**You make 34% more per subscriber with Stripe!** 🎉

---

## ✅ Complete Checklist

### Today (2 hours):
- [ ] Create Stripe account
- [ ] Get API keys
- [ ] Create $9.99 subscription product
- [ ] Set up webhook
- [ ] Create Edge Functions
- [ ] Deploy functions
- [ ] Apply database migration

### Tomorrow (3 hours):
- [ ] Update iOS code with StripeManager
- [ ] Update PaywallView
- [ ] Add URL scheme handling
- [ ] Test checkout flow
- [ ] Test webhook delivery

### Day 3 (2 hours):
- [ ] Polish paywall UI
- [ ] Add customer portal
- [ ] Test edge cases
- [ ] Fix any bugs

**Total: ~7 hours to complete implementation**

---

## 📊 Summary

### What You Get:
- ✅ **No Apple restrictions** - Start immediately
- ✅ **Keep 94% of revenue** (vs 70% with Apple)
- ✅ **7-day free trial** - Included
- ✅ **Customer portal** - Users can manage subscription
- ✅ **Webhooks** - Real-time updates
- ✅ **Works everywhere** - Not just iOS
- ✅ **No App Store approval** needed

### Next Steps:
1. Create Stripe account NOW
2. Copy the 3 Edge Functions I provided
3. Deploy to Supabase
4. Update iOS code
5. Test!

**Ready to implement? Start with Stripe account setup!** 🚀💰

