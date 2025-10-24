-- Add duration_sec column to analysis_reports table
ALTER TABLE analysis_reports
ADD COLUMN IF NOT EXISTS duration_sec INTEGER DEFAULT 0;

-- Add comment
COMMENT ON COLUMN analysis_reports.duration_sec IS 'Actual video duration in seconds detected by AI';

