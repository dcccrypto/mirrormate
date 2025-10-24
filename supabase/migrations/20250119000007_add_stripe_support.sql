-- Add Stripe support to existing subscriptions table

-- Create stripe_customers table
CREATE TABLE IF NOT EXISTS stripe_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    stripe_customer_id TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add Stripe-specific columns to subscriptions table
ALTER TABLE subscriptions
ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT,
ADD COLUMN IF NOT EXISTS price_id TEXT,
ADD COLUMN IF NOT EXISTS quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS current_period_start TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS current_period_end TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS trial_end TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS cancel_at_period_end BOOLEAN DEFAULT false;

-- Update indexes
CREATE INDEX IF NOT EXISTS idx_stripe_customers_user ON stripe_customers(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_sub ON subscriptions(stripe_subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_customer ON subscriptions(stripe_customer_id);

-- Enable RLS
ALTER TABLE stripe_customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own stripe customer"
    ON stripe_customers FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage stripe customers"
    ON stripe_customers FOR ALL
    USING (auth.role() = 'service_role');

-- Update premium check function to support Stripe statuses
DROP FUNCTION IF EXISTS is_user_premium(UUID);
CREATE OR REPLACE FUNCTION is_user_premium(check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM subscriptions
        WHERE user_id = check_user_id
        AND status IN ('active', 'trialing')  -- Stripe statuses
        AND (
            current_period_end > NOW()  -- Stripe field
            OR expires_at > NOW()        -- StoreKit field (backwards compat)
            OR current_period_end IS NULL  -- For active subscriptions without end date
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update get subscription function for Stripe
DROP FUNCTION IF EXISTS get_user_subscription(UUID);
CREATE OR REPLACE FUNCTION get_user_subscription(check_user_id UUID)
RETURNS TABLE (
    is_premium BOOLEAN,
    status TEXT,
    expires_at TIMESTAMPTZ,
    is_trial BOOLEAN,
    days_remaining INTEGER,
    auto_renew BOOLEAN,
    provider TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (s.status IN ('active', 'trialing') AND 
         (s.current_period_end > NOW() OR s.expires_at > NOW())) as is_premium,
        s.status,
        COALESCE(s.current_period_end, s.expires_at) as expires_at,
        COALESCE(s.is_trial, (s.status = 'trialing')) as is_trial,
        GREATEST(0, EXTRACT(DAY FROM COALESCE(s.current_period_end, s.expires_at) - NOW())::INTEGER) as days_remaining,
        COALESCE(NOT s.cancel_at_period_end, s.auto_renew_enabled, true) as auto_renew,
        CASE 
            WHEN s.stripe_subscription_id IS NOT NULL THEN 'stripe'
            WHEN s.transaction_id IS NOT NULL THEN 'apple'
            ELSE 'unknown'
        END as provider
    FROM subscriptions s
    WHERE s.user_id = check_user_id
    ORDER BY COALESCE(s.current_period_end, s.expires_at) DESC NULLS LAST
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments
COMMENT ON TABLE stripe_customers IS 'Maps Supabase users to Stripe customer IDs';
COMMENT ON COLUMN subscriptions.stripe_subscription_id IS 'Stripe subscription ID (if payment via Stripe)';
COMMENT ON COLUMN subscriptions.stripe_customer_id IS 'Stripe customer ID (if payment via Stripe)';
COMMENT ON COLUMN subscriptions.price_id IS 'Stripe price ID';
COMMENT ON COLUMN subscriptions.current_period_start IS 'Stripe: Current billing period start';
COMMENT ON COLUMN subscriptions.current_period_end IS 'Stripe: Current billing period end (used for premium check)';
COMMENT ON COLUMN subscriptions.trial_end IS 'Stripe: When trial period ends';
COMMENT ON COLUMN subscriptions.cancel_at_period_end IS 'Stripe: Whether subscription cancels at period end';

