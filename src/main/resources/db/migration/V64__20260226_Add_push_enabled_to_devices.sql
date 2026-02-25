ALTER TABLE devices
    ADD COLUMN IF NOT EXISTS push_enabled BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN devices.push_enabled IS '디바이스별 푸시 수신 동의 여부 (true=수신, false=차단)';

CREATE INDEX IF NOT EXISTS idx_devices_push_enabled
    ON devices(push_enabled)
    WHERE deleted_at IS NULL;
