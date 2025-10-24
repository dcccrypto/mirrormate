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

    console.log(`✅ Received Stripe webhook: ${event.type}`);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId = session.metadata?.supabase_user_id;
        
        if (!userId) {
          console.error("No user ID in session metadata");
          break;
        }

        console.log(`Processing checkout completion for user: ${userId}`);

        // Get subscription details
        const subscription = await stripe.subscriptions.retrieve(
          session.subscription as string
        );

        const now = new Date().toISOString();
        const currentPeriodEnd = new Date(subscription.current_period_end * 1000).toISOString();

        const { data, error } = await supabase.from("subscriptions").insert({
          user_id: userId,
          stripe_subscription_id: subscription.id,
          stripe_customer_id: subscription.customer as string,
          transaction_id: session.id, // Use session ID as transaction ID
          product_id: subscription.items.data[0].price.product as string,
          status: subscription.status,
          price_id: subscription.items.data[0].price.id,
          quantity: subscription.items.data[0].quantity || 1,
          current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
          current_period_end: currentPeriodEnd,
          expires_at: currentPeriodEnd, // Use current period end as expiry
          purchased_at: now,
          trial_end: subscription.trial_end ? new Date(subscription.trial_end * 1000).toISOString() : null,
          trial_ends_at: subscription.trial_end ? new Date(subscription.trial_end * 1000).toISOString() : null,
          is_trial: !!subscription.trial_end,
          cancel_at_period_end: subscription.cancel_at_period_end,
          auto_renew_enabled: !subscription.cancel_at_period_end,
        });

        if (error) {
          console.error(`❌ Failed to create subscription: ${error.message}`);
          throw error;
        }

        console.log(`✓ Subscription created for user ${userId}: ${subscription.id}`);
        break;
      }

      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription;
        const userId = subscription.metadata?.supabase_user_id;

        console.log(`Updating subscription: ${subscription.id}`);

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

        console.log(`✓ Subscription updated: ${subscription.id}`);
        break;
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;

        console.log(`Deleting subscription: ${subscription.id}`);

        await supabase
          .from("subscriptions")
          .update({
            status: "canceled",
            canceled_at: new Date().toISOString(),
          })
          .eq("stripe_subscription_id", subscription.id);

        console.log(`✓ Subscription canceled: ${subscription.id}`);
        break;
      }

      case "invoice.payment_failed": {
        const invoice = event.data.object as Stripe.Invoice;
        const subscriptionId = invoice.subscription as string;

        console.log(`Payment failed for subscription: ${subscriptionId}`);

        await supabase
          .from("subscriptions")
          .update({
            status: "past_due",
          })
          .eq("stripe_subscription_id", subscriptionId);

        console.log(`✓ Subscription marked as past_due: ${subscriptionId}`);
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("❌ Webhook error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400 }
    );
  }
});

