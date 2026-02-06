-- mining_boosters 테이블이 없을 때만 생성 (V15 미적용/실패 환경 대응)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'mining_boosters'
  ) THEN
    CREATE TABLE mining_boosters (
      id SERIAL NOT NULL,
      type VARCHAR(50) NOT NULL,
      name VARCHAR(255) NOT NULL,
      is_enabled BOOLEAN NOT NULL DEFAULT true,
      efficiency INT NULL,
      max_count INT NULL,
      per_unit_efficiency INT NULL,
      note TEXT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
      CONSTRAINT PK_mining_boosters PRIMARY KEY (id),
      CONSTRAINT UK_mining_boosters_type UNIQUE (type)
    );

    COMMENT ON TABLE mining_boosters IS '채굴 부스터 테이블';
    COMMENT ON COLUMN mining_boosters.id IS 'Sequence ID';
    COMMENT ON COLUMN mining_boosters.type IS '부스터 타입 (UNIQUE)';
    COMMENT ON COLUMN mining_boosters.name IS '부스터 이름';
    COMMENT ON COLUMN mining_boosters.is_enabled IS '활성화 여부';
    COMMENT ON COLUMN mining_boosters.efficiency IS '채굴 효율 (%)';
    COMMENT ON COLUMN mining_boosters.max_count IS '최대 횟수 (NULL이면 단순 효율)';
    COMMENT ON COLUMN mining_boosters.per_unit_efficiency IS '단위당 효율 (max_count와 함께 사용)';
    COMMENT ON COLUMN mining_boosters.note IS '설명/노트';

    CREATE INDEX IDX_mining_boosters_enabled ON mining_boosters(is_enabled);

    CREATE TRIGGER update_mining_boosters_updated_at BEFORE UPDATE ON mining_boosters
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

    -- 기본 부스터 시드 (AdminMiningRepository.createDefaultBoosters()와 동일)
    INSERT INTO mining_boosters (type, name, is_enabled, efficiency, max_count, per_unit_efficiency, note) VALUES
      ('SOCIAL_LINK', '카카오/구글/이메일/네이버 연동시', true, 5, NULL, NULL, NULL),
      ('PHONE_VERIFICATION', '본인인증(휴대폰) 등록시', true, 5, NULL, NULL, NULL),
      ('REVIEW', '리뷰 작성시', true, 10, NULL, NULL, NULL),
      ('AGENCY', '에이전시 가입시', true, 80, NULL, NULL, NULL),
      ('PREMIUM', '프리미엄 패키지 구독시', true, 40, NULL, NULL, NULL),
      ('AD_VIEW', '광고시청 보너스', true, 25, 5, 5, '시청횟수: 계정당 하루 최대 채굴효율(%): 1회당 +% 채굴효율 ex) 5회 x 5% = +25%'),
      ('REFERRER_REGISTRATION', '추천인 등록시', true, 5, NULL, NULL, NULL),
      ('INVITATION_REWARD', '초대보상 보너스', true, 50, 5, 10, '초대인원: 최대 몇명 채굴효율(%): 1명당 +% 채굴효율 ex) 5명 x 10% = +50%');
  END IF;
END $$;
