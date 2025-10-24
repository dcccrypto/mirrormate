-- Add enhanced analysis fields to analysis_reports table
-- This migration adds detailed vocal analysis, body language metrics, 
-- strengths, improvements, practice exercises, and key moments

ALTER TABLE analysis_reports
ADD COLUMN IF NOT EXISTS vocal_analysis jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS body_language_analysis jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS strengths text[] DEFAULT ARRAY[]::text[],
ADD COLUMN IF NOT EXISTS areas_for_improvement text[] DEFAULT ARRAY[]::text[],
ADD COLUMN IF NOT EXISTS practice_exercises text[] DEFAULT ARRAY[]::text[],
ADD COLUMN IF NOT EXISTS key_moments jsonb DEFAULT '[]'::jsonb;

-- Add comments for documentation
COMMENT ON COLUMN analysis_reports.vocal_analysis IS 'Detailed vocal metrics: paceWordsPerMin, volumeConsistency, tonalVariety, clarity, pauseEffectiveness';
COMMENT ON COLUMN analysis_reports.body_language_analysis IS 'Body language metrics: postureScore, gestureNaturalness, facialExpressiveness, eyeContactPct, movementPurpose';
COMMENT ON COLUMN analysis_reports.strengths IS 'Array of 3 specific strengths with evidence';
COMMENT ON COLUMN analysis_reports.areas_for_improvement IS 'Array of 3 specific areas for improvement with actionable advice';
COMMENT ON COLUMN analysis_reports.practice_exercises IS 'Array of 3 specific exercises the user can practice';
COMMENT ON COLUMN analysis_reports.key_moments IS 'Array of notable moments with timestamp, type (strength/improvement), and description';

-- Update tone_timeline to include confidence metric (stored as jsonb, so no schema change needed)
-- Format: [{"t": 0, "energy": 0.5, "confidence": 0.7}, ...]

-- Add index for faster queries on strengths and improvements
CREATE INDEX IF NOT EXISTS idx_analysis_reports_strengths ON analysis_reports USING GIN (strengths);
CREATE INDEX IF NOT EXISTS idx_analysis_reports_improvements ON analysis_reports USING GIN (areas_for_improvement);

