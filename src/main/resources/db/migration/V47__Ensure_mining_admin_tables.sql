-- 체굴조건 API( GET /admin/mining/conditions ) 호환: 테이블 없을 때 생성
CREATE TABLE IF NOT EXISTS mining_settings (
    id SERIAL NOT NULL,
    setting_type VARCHAR(50) NOT NULL,
    setting_key VARCHAR(50) NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    base_time_enabled BOOLEAN NULL,
    base_time_minutes INT NULL,
    time_per_hour INT NULL,
    coins_per_hour DECIMAL(36, 18) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PK_mining_settings PRIMARY KEY (id),
    CONSTRAINT UK_mining_settings_type_key UNIQUE (setting_type, setting_key)
);

CREATE TABLE IF NOT EXISTS mining_missions (
    id SERIAL NOT NULL,
    type VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    required_count INT NOT NULL DEFAULT 1,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    has_input BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PK_mining_missions PRIMARY KEY (id),
    CONSTRAINT UK_mining_missions_type UNIQUE (type)
);

CREATE TABLE IF NOT EXISTS mining_level_limits (
    id SERIAL NOT NULL,
    level INT NOT NULL,
    daily_limit DECIMAL(36, 18) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PK_mining_level_limits PRIMARY KEY (id),
    CONSTRAINT UK_mining_level_limits_level UNIQUE (level)
);


-- mining_history.deleted_at 없을 수 있는 환경 호환 (체굴 내역 API 쿼리 안정화)
ALTER TABLE mining_history ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL;
COMMENT ON COLUMN mining_history.deleted_at IS '소프트 삭제 시각 (NULL이면 활성)';
CREATE INDEX IF NOT EXISTS IDX_mining_history_deleted_at ON mining_history(deleted_at);
