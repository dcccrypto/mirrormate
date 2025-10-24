import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export interface RateLimitConfig {
  limit: number
  windowMinutes: number
  action: string
}

export async function checkRateLimit(
  supabase: any,
  userId: string,
  action: string,
  limit: number,
  windowMinutes: number
): Promise<boolean> {
  const windowStart = new Date(Date.now() - windowMinutes * 60 * 1000);
  
  try {
    const { count, error } = await supabase
      .from('rate_limits')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('action', action)
      .gte('created_at', windowStart.toISOString());
    
    if (error) {
      console.error('Rate limit check error:', error);
      return true; // Fail open (allow request if check fails)
    }
    
    const currentCount = count || 0;
    console.log(`Rate limit check: ${currentCount}/${limit} for action ${action}`);
    
    return currentCount < limit;
  } catch (error) {
    console.error('Rate limit check failed:', error);
    return true; // Fail open
  }
}

export async function recordRateLimit(
  supabase: any,
  userId: string,
  action: string
): Promise<void> {
  try {
    await supabase
      .from('rate_limits')
      .insert({
        user_id: userId,
        action: action,
        created_at: new Date().toISOString()
      });
    
    console.log(`Rate limit recorded for user ${userId}, action ${action}`);
  } catch (error) {
    console.error('Failed to record rate limit:', error);
    // Don't throw - this is not critical
  }
}

export async function checkAndRecordRateLimit(
  supabase: any,
  userId: string,
  config: RateLimitConfig
): Promise<{ allowed: boolean; remaining: number }> {
  const canProceed = await checkRateLimit(
    supabase,
    userId,
    config.action,
    config.limit,
    config.windowMinutes
  );
  
  if (canProceed) {
    await recordRateLimit(supabase, userId, config.action);
  }
  
  // Get current count for remaining calculation
  const windowStart = new Date(Date.now() - config.windowMinutes * 60 * 1000);
  const { count } = await supabase
    .from('rate_limits')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('action', config.action)
    .gte('created_at', windowStart.toISOString());
  
  const currentCount = count || 0;
  const remaining = Math.max(0, config.limit - currentCount);
  
  return {
    allowed: canProceed,
    remaining
  };
}

// Predefined rate limit configurations
export const RATE_LIMITS = {
  INIT_SESSION: { limit: 10, windowMinutes: 60, action: 'init_session' },
  UPLOAD_VIDEO: { limit: 5, windowMinutes: 60, action: 'upload_video' },
  ANALYSIS: { limit: 3, windowMinutes: 60, action: 'analysis' },
  CHECKOUT: { limit: 5, windowMinutes: 60, action: 'checkout' },
  CUSTOMER_PORTAL: { limit: 3, windowMinutes: 60, action: 'customer_portal' }
} as const;
