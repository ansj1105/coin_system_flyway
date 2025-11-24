-- Create indexes for better query performance

-- User table indexes
CREATE INDEX idx_유저_lgn_id ON "유저"(lgn_id);
CREATE INDEX idx_유저_referral_code ON "유저"(referral_code);
CREATE INDEX idx_유저_status ON "유저"(status);
CREATE INDEX idx_유저_deleted_at ON "유저"(deleted_at);

-- User Wallet table indexes
CREATE INDEX idx_유저_지갑_user_id ON "유저 지갑"(user_id);
CREATE INDEX idx_유저_지갑_currency_id ON "유저 지갑"(currency_id);
CREATE INDEX idx_유저_지갑_address ON "유저 지갑"(address);
CREATE INDEX idx_유저_지갑_user_currency ON "유저 지갑"(user_id, currency_id);
CREATE INDEX idx_유저_지갑_deleted_at ON "유저 지갑"(deleted_at);

-- Referral Info table indexes
CREATE INDEX idx_레퍼럴_정보_user_id ON "레퍼럴 정보 테이블"(user_id);
CREATE INDEX idx_레퍼럴_정보_referral_code ON "레퍼럴 정보 테이블"(referral_code);
CREATE INDEX idx_레퍼럴_정보_referral_grade ON "레퍼럴 정보 테이블"(referral_grade);
CREATE INDEX idx_레퍼럴_정보_deleted_at ON "레퍼럴 정보 테이블"(deleted_at);

-- Referral Relation table indexes
CREATE INDEX idx_레퍼럴_관계_referred_id ON "레퍼럴 관계 테이블"(referred_id);
CREATE INDEX idx_레퍼럴_관계_referral_id ON "레퍼럴 관계 테이블"(referral_id);
CREATE INDEX idx_레퍼럴_관계_status ON "레퍼럴 관계 테이블"(status);
CREATE INDEX idx_레퍼럴_관계_referred_referral ON "레퍼럴 관계 테이블"(referred_id, referral_id);
CREATE INDEX idx_레퍼럴_관계_deleted_at ON "레퍼럴 관계 테이블"(deleted_at);

-- Transaction Log table indexes
CREATE INDEX idx_트랜잭션_기록_currency ON "트랜잭션 기록"(currency);
CREATE INDEX idx_트랜잭션_기록_wallet_id ON "트랜잭션 기록"(wallet_id);
CREATE INDEX idx_트랜잭션_기록_user_id ON "트랜잭션 기록"(user_id);
CREATE INDEX idx_트랜잭션_기록_tx_hash ON "트랜잭션 기록"(tx_hash);
CREATE INDEX idx_트랜잭션_기록_tx_type ON "트랜잭션 기록"(tx_type);
CREATE INDEX idx_트랜잭션_기록_status ON "트랜잭션 기록"(status);
CREATE INDEX idx_트랜잭션_기록_created_at ON "트랜잭션 기록"(created_at);
CREATE INDEX idx_트랜잭션_기록_user_created ON "트랜잭션 기록"(user_id, created_at DESC);
CREATE INDEX idx_트랜잭션_기록_wallet_created ON "트랜잭션 기록"(wallet_id, created_at DESC);

-- Transaction Status Log table indexes
CREATE INDEX idx_트랜잭션_상태_기록_tx_hash ON "트랜잭션 상태 기록"(tx_hash);
CREATE INDEX idx_트랜잭션_상태_기록_tx_type ON "트랜잭션 상태 기록"(tx_type);
CREATE INDEX idx_트랜잭션_상태_기록_status ON "트랜잭션 상태 기록"(status);
CREATE INDEX idx_트랜잭션_상태_기록_created_at ON "트랜잭션 상태 기록"(created_at);

-- Currency table indexes
CREATE INDEX idx_통화종류_currency ON "통화종류"(currency);

