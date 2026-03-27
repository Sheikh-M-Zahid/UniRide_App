-- Improve performance for user queries
CREATE INDEX IF NOT EXISTS idx_reports_user_id
ON reports(user_id);

-- For sorting by latest requests
CREATE INDEX IF NOT EXISTS idx_reports_created_at
ON reports(created_at DESC);

-- Optional: filter by status
CREATE INDEX IF NOT EXISTS idx_reports_status
ON reports(status);

-- Quickly find unsolved issues
CREATE INDEX IF NOT EXISTS idx_reports_unsolved
ON reports(status)
WHERE status = 'unsolved';