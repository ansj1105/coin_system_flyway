-- foxya_coin_service와 DB 공유 시 호환: internal_transfers
-- foxya는 it.deleted_at IS NULL 조건 및 REFERRAL_REWARD 시 sender_id NULL 사용

ALTER TABLE internal_transfers ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL;
COMMENT ON COLUMN internal_transfers.deleted_at IS '소프트 삭제 시각 (NULL이면 활성)';
CREATE INDEX IF NOT EXISTS idx_internal_transfers_deleted_at ON internal_transfers(deleted_at);

-- REFERRAL_REWARD/ADMIN_GRANT 시 sender_id NULL 허용 (foxya V21 호환)
ALTER TABLE internal_transfers ALTER COLUMN sender_id DROP NOT NULL;
ALTER TABLE internal_transfers ALTER COLUMN sender_wallet_id DROP NOT NULL;
