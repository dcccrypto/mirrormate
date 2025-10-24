-- Add rate limiting table for API protection
CREATE TABLE IF NOT EXISTS rate_limits (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  action TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for efficient queries
CREATE INDEX idx_rate_limits_user_action_time 
ON rate_limits(user_id, action, created_at DESC);

-- Enable RLS
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see their own rate limit records
CREATE POLICY "Users can view their own rate limits" ON rate_limits
  FOR SELECT USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own rate limit records
CREATE POLICY "Users can insert their own rate limits" ON rate_limits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Cleanup function for old entries (keep last 24 hours)
CREATE OR REPLACE FUNCTION cleanup_rate_limits()
RETURNS void AS $$
BEGIN
  DELETE FROM rate_limits
  WHERE created_at < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup every hour (if pg_cron extension is available)
-- Note: This requires pg_cron extension to be enabled in Supabase
-- If not available, you can run this manually or via a scheduled job
SELECT cron.schedule(
  'cleanup-rate-limits',
  '0 * * * *',
  'SELECT cleanup_rate_limits()'
) ON CONFLICT (jobname) DO NOTHING;
