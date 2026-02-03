-- 채굴 관리: 레퍼럴 보너스/랭킹 리워드 설정 테이블 (AdminMiningRepository 사용)

-- 레퍼럴 보너스 설정 (단일 행)
CREATE TABLE IF NOT EXISTS referral_bonus_settings (
    id SERIAL NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    distribution_rate INT NOT NULL DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PK_referral_bonus_settings PRIMARY KEY (id)
);
INSERT INTO referral_bonus_settings (id, is_enabled, distribution_rate, updated_at)
VALUES (1, true, 5, NOW())
ON CONFLICT (id) DO NOTHING;

-- 랭킹 리워드 설정 (REGIONAL / NATIONAL 타입)
CREATE TABLE IF NOT EXISTS ranking_reward_settings (
    type VARCHAR(50) NOT NULL,
    rank1 DECIMAL(36, 18) NOT NULL DEFAULT 10,
    rank2 DECIMAL(36, 18) NOT NULL DEFAULT 5,
    rank3 DECIMAL(36, 18) NOT NULL DEFAULT 2.5,
    rank4to10 DECIMAL(36, 18) NOT NULL DEFAULT 0.8,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PK_ranking_reward_settings PRIMARY KEY (type)
);
INSERT INTO ranking_reward_settings (type, rank1, rank2, rank3, rank4to10, updated_at)
VALUES ('REGIONAL', 10, 5, 2.5, 0.8, NOW()), ('NATIONAL', 10, 5, 2.5, 0.8, NOW())
ON CONFLICT (type) DO NOTHING;
