-- 문의: 관리자 읽음 여부
ALTER TABLE inquiries ADD COLUMN IF NOT EXISTS is_read BOOLEAN NOT NULL DEFAULT false;
COMMENT ON COLUMN inquiries.is_read IS '관리자 읽음 여부';
