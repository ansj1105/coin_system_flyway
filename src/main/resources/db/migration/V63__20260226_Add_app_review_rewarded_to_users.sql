ALTER TABLE users
    ADD COLUMN IF NOT EXISTS app_review_rewarded BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN users.app_review_rewarded IS '앱 리뷰 보상 지급 완료 여부 (false=미완료, true=완료)';
