import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14.11.0?target=deno";
import { checkAndRecordRateLimit, RATE_LIMITS } from "../_shared/rateLimiter.ts";

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

    console.log(`Creating checkout session for user: ${user.id}`);

    // Check rate limiting
    const rateLimitResult = await checkAndRecordRateLimit(
      supabase,
      user.id,
      RATE_LIMITS.CHECKOUT
    );
    
    if (!rateLimitResult.allowed) {
      console.log(`Rate limit exceeded for user ${user.id}, action: checkout`);
      return new Response(
        JSON.stringify({ 
          error: 'Rate limit exceeded. Please try again in a few minutes.',
          remaining: rateLimitResult.remaining
        }),
        { 
          status: 429, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
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
      console.log("Creating new Stripe customer");
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
      
      console.log(`Stripe customer created: ${customerId}`);
    }

    // Create Checkout Session
    console.log("Creating Stripe Checkout session");
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

    console.log(`Checkout session created: ${session.id}`);

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

