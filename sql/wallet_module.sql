-- Helpful indexes for wallet module

CREATE INDEX IF NOT EXISTS idx_users_due_balance
ON users(due_balance);

CREATE INDEX IF NOT EXISTS idx_offers_active_dates
ON offers(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id
ON transactions(user_id);

-- Prevent duplicate transaction IDs globally
CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_reference_id_unique
ON transactions(reference_id);