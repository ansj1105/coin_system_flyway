-- Create indexes for better query performance

-- Users table indexes
CREATE INDEX idx_users_login_id ON users(login_id);
CREATE INDEX idx_users_referral_code ON users(referral_code);
CREATE INDEX idx_users_status ON users(status);

-- Currency table indexes
CREATE INDEX idx_currency_code ON currency(code);
CREATE INDEX idx_currency_is_active ON currency(is_active);

-- User Wallet table indexes
CREATE INDEX idx_user_wallet_user_id ON user_wallet(user_id);
CREATE INDEX idx_user_wallet_currency_id ON user_wallet(currency_id);
CREATE INDEX idx_user_wallet_address ON user_wallet(address);
CREATE INDEX idx_user_wallet_user_currency ON user_wallet(user_id, currency_id);
CREATE INDEX idx_user_wallet_status ON user_wallet(status);

-- Wallet Transaction table indexes
CREATE INDEX idx_tx_user ON wallet_transaction(user_id, id);
CREATE INDEX idx_tx_wallet ON wallet_transaction(wallet_id, id);
CREATE INDEX idx_tx_hash ON wallet_transaction(tx_hash);
CREATE INDEX idx_tx_status ON wallet_transaction(status);
CREATE INDEX idx_tx_currency ON wallet_transaction(currency_id);
CREATE INDEX idx_tx_type ON wallet_transaction(tx_type);
CREATE INDEX idx_tx_created_at ON wallet_transaction(created_at);
CREATE INDEX idx_tx_user_created ON wallet_transaction(user_id, created_at DESC);
CREATE INDEX idx_tx_wallet_created ON wallet_transaction(wallet_id, created_at DESC);

-- Wallet Transaction Status Log table indexes
CREATE INDEX idx_tx_status_tx ON wallet_transaction_status_log(tx_id);
CREATE INDEX idx_tx_status_created_at ON wallet_transaction_status_log(created_at);

-- Referral Relation table indexes
CREATE INDEX idx_referral_relation_referrer_id ON referral_relation(referrer_id);
CREATE INDEX idx_referral_relation_referred_id ON referral_relation(referred_id);
CREATE INDEX idx_referral_relation_status ON referral_relation(status);
CREATE INDEX idx_referral_relation_referrer_referred ON referral_relation(referrer_id, referred_id);
CREATE INDEX idx_referral_relation_deleted_at ON referral_relation(deleted_at);

-- Referral Stats table indexes
CREATE INDEX idx_referral_stats_user_id ON referral_stats(user_id);
