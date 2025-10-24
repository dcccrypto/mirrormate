-- Add subscription tracking table for premium users
-- This enables server-side verification of App Store subscriptions

CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- StoreKit fields
    transaction_id TEXT UNIQUE NOT NULL,  -- Original transaction ID from StoreKit
    product_id TEXT NOT NULL,             -- com.mirrormate.premium.monthly
    
    -- Status fields
    status TEXT NOT NULL CHECK (status IN ('active', 'expired', 'cancelled', 'grace_period')),
    expires_at TIMESTAMPTZ NOT NULL,      -- When subscription ends
    auto_renew_enabled BOOLEAN DEFAULT true,
    
    -- Trial fields
    is_trial BOOLEAN DEFAULT false,
    trial_ends_at TIMESTAMPTZ,
    
    -- Metadata
    purchased_at TIMESTAMPTZ NOT NULL,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id, product_id)
);

-- Index for fast premium status checks
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON subscriptions(user_id, status, expires_at);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expires ON subscriptions(expires_at) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_subscriptions_transaction ON subscriptions(transaction_id);

-- Enable Row Level Security
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see their own subscriptions
CREATE POLICY "Users can view own subscriptions"
    ON subscriptions FOR SELECT
    USING (auth.uid() = user_id);

-- RLS Policy: Service role can manage all subscriptions (for sync from iOS app)
CREATE POLICY "Service role can manage subscriptions"
    ON subscriptions FOR ALL
    USING (auth.role() = 'service_role');

-- Function to check if user is premium
CREATE OR REPLACE FUNCTION is_user_premium(check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM subscriptions
        WHERE user_id = check_user_id
        AND status = 'active'
        AND expires_at > NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get subscription details
CREATE OR REPLACE FUNCTION get_user_subscription(check_user_id UUID)
RETURNS TABLE (
    is_premium BOOLEAN,
    status TEXT,
    expires_at TIMESTAMPTZ,
    is_trial BOOLEAN,
    days_remaining INTEGER,
    auto_renew BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (s.status = 'active' AND s.expires_at > NOW()) as is_premium,
        s.status,
        s.expires_at,
        s.is_trial,
        GREATEST(0, EXTRACT(DAY FROM s.expires_at - NOW())::INTEGER) as days_remaining,
        s.auto_renew_enabled as auto_renew
    FROM subscriptions s
    WHERE s.user_id = check_user_id
    ORDER BY s.expires_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE subscriptions IS 'Stores iOS App Store subscription information synced from StoreKit';
COMMENT ON COLUMN subscriptions.transaction_id IS 'Original transaction ID from StoreKit - unique identifier';
COMMENT ON COLUMN subscriptions.product_id IS 'Product identifier from App Store Connect (e.g., com.mirrormate.premium.monthly)';
COMMENT ON COLUMN subscriptions.status IS 'Subscription status: active, expired, cancelled, grace_period';
COMMENT ON COLUMN subscriptions.expires_at IS 'When the subscription period ends (used for premium checks)';
COMMENT ON COLUMN subscriptions.is_trial IS 'Whether user is in free trial period';
COMMENT ON FUNCTION is_user_premium(UUID) IS 'Quick check if user has active premium subscription';
COMMENT ON FUNCTION get_user_subscription(UUID) IS 'Get detailed subscription information for a user';

