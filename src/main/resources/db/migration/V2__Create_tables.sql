-- Create Currency Type Table (통화종류)
CREATE TABLE "통화종류" (
    id SERIAL NOT NULL,
    currency currency_type_enum NULL,
    name VARCHAR(50) NULL,
    symbol VARCHAR(10) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_통화종류 PRIMARY KEY (id)
);

COMMENT ON TABLE "통화종류" IS '통화 종류 테이블';
COMMENT ON COLUMN "통화종류".id IS 'sequence ID(인조키)';
COMMENT ON COLUMN "통화종류".currency IS '통화 종류 (KRW,USDT 등등)';
COMMENT ON COLUMN "통화종류".name IS '통화 이름';
COMMENT ON COLUMN "통화종류".symbol IS '통화 심볼';

-- Create User Table (유저)
CREATE TABLE "유저" (
    id BIGSERIAL NOT NULL,
    referral_code VARCHAR(10) NOT NULL,
    lgn_id VARCHAR(50) NOT NULL,
    lgn_pwd VARCHAR(255) NOT NULL,
    wallet_id BIGINT NULL,
    email VARCHAR(255) NULL,
    phone VARCHAR(20) NULL,
    status VARCHAR(20) DEFAULT 'active' NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    CONSTRAINT PK_유저 PRIMARY KEY (id),
    CONSTRAINT UK_유저_lgn_id UNIQUE (lgn_id),
    CONSTRAINT UK_유저_referral_code UNIQUE (referral_code)
);

COMMENT ON TABLE "유저" IS '유저 테이블';
COMMENT ON COLUMN "유저".id IS 'user_id';
COMMENT ON COLUMN "유저".referral_code IS '레퍼럴 코드';
COMMENT ON COLUMN "유저".lgn_id IS '로그인아이디';
COMMENT ON COLUMN "유저".lgn_pwd IS '로그인 비밀번호';
COMMENT ON COLUMN "유저".wallet_id IS '지갑id';

-- Create User Wallet Table (유저 지갑)
CREATE TABLE "유저 지갑" (
    id BIGSERIAL NOT NULL,
    user_id BIGINT NOT NULL,
    currency_id INT NOT NULL,
    address VARCHAR(255) NOT NULL,
    private_key VARCHAR(255) NOT NULL,
    balance DECIMAL(18, 8) DEFAULT 0.00000000 NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    CONSTRAINT PK_유저_지갑 PRIMARY KEY (id),
    CONSTRAINT FK_유저_TO_유저_지갑_1 FOREIGN KEY (user_id) REFERENCES "유저"(id) ON DELETE CASCADE,
    CONSTRAINT FK_통화종류_TO_유저_지갑_1 FOREIGN KEY (currency_id) REFERENCES "통화종류"(id) ON DELETE RESTRICT
);

COMMENT ON TABLE "유저 지갑" IS '유저 지갑 테이블';
COMMENT ON COLUMN "유저 지갑".id IS 'Sequence ID (인조키)';
COMMENT ON COLUMN "유저 지갑".user_id IS 'user_id';
COMMENT ON COLUMN "유저 지갑".currency_id IS '통화 종류 (KRW,USDT 등등)';
COMMENT ON COLUMN "유저 지갑".address IS '지갑주소';
COMMENT ON COLUMN "유저 지갑".private_key IS '개인 키 주소';
COMMENT ON COLUMN "유저 지갑".balance IS '지갑잔액';
COMMENT ON COLUMN "유저 지갑".created_at IS '생성 일자';
COMMENT ON COLUMN "유저 지갑".updated_at IS '수정 일자';
COMMENT ON COLUMN "유저 지갑".deleted_at IS '삭제 일자';

-- Create Referral Info Table (레퍼럴 정보 테이블)
CREATE TABLE "레퍼럴 정보 테이블" (
    id BIGSERIAL NOT NULL,
    user_id INT NOT NULL,
    referral_code VARCHAR(10) NOT NULL,
    referral_grade INT DEFAULT 0 NOT NULL,
    referral_counts INT DEFAULT 0 NULL,
    total_reward DECIMAL(18, 8) DEFAULT 0.00000000 NULL,
    created_at DATE DEFAULT CURRENT_DATE NOT NULL,
    deleted_at DATE NULL,
    updated_at DATE DEFAULT CURRENT_DATE NOT NULL,
    CONSTRAINT PK_레퍼럴_정보_테이블 PRIMARY KEY (id),
    CONSTRAINT FK_유저_TO_레퍼럴_정보 FOREIGN KEY (user_id) REFERENCES "유저"(id) ON DELETE CASCADE,
    CONSTRAINT UK_레퍼럴_정보_user_id UNIQUE (user_id)
);

COMMENT ON TABLE "레퍼럴 정보 테이블" IS '레퍼럴 정보 테이블';
COMMENT ON COLUMN "레퍼럴 정보 테이블".user_id IS '유저 ID';
COMMENT ON COLUMN "레퍼럴 정보 테이블".referral_code IS '레퍼럴 코드';
COMMENT ON COLUMN "레퍼럴 정보 테이블".referral_grade IS '레퍼럴 등급';
COMMENT ON COLUMN "레퍼럴 정보 테이블".referral_counts IS '레퍼럴 수';
COMMENT ON COLUMN "레퍼럴 정보 테이블".total_reward IS '총 리워드';

-- Create Referral Relation Table (레퍼럴 관계 테이블)
CREATE TABLE "레퍼럴 관계 테이블" (
    id BIGSERIAL NOT NULL,
    referred_id INT NOT NULL,
    referral_id INT NOT NULL,
    status referral_status_enum DEFAULT 'active' NOT NULL,
    reward_rate DECIMAL(5, 2) DEFAULT 0.00 NULL,
    created_at DATE DEFAULT CURRENT_DATE NOT NULL,
    deleted_at DATE NULL,
    updated_at DATE DEFAULT CURRENT_DATE NOT NULL,
    CONSTRAINT PK_레퍼럴_관계_테이블 PRIMARY KEY (id),
    CONSTRAINT FK_레퍼럴_관계_referred FOREIGN KEY (referred_id) REFERENCES "유저"(id) ON DELETE CASCADE,
    CONSTRAINT FK_레퍼럴_관계_referral FOREIGN KEY (referral_id) REFERENCES "유저"(id) ON DELETE CASCADE
);

COMMENT ON TABLE "레퍼럴 관계 테이블" IS '레퍼럴 관계 테이블';
COMMENT ON COLUMN "레퍼럴 관계 테이블".id IS 'referral_id';
COMMENT ON COLUMN "레퍼럴 관계 테이블".referred_id IS '추천받은 유저 ID';
COMMENT ON COLUMN "레퍼럴 관계 테이블".referral_id IS '추천한 유저 ID';
COMMENT ON COLUMN "레퍼럴 관계 테이블".status IS 'active, deactive';
COMMENT ON COLUMN "레퍼럴 관계 테이블".reward_rate IS '리워드 비율';

-- Create Transaction Status Log Table (트랜잭션 상태 기록)
CREATE TABLE "트랜잭션 상태 기록" (
    id VARCHAR(255) NOT NULL,
    tx_hash VARCHAR(255) NULL,
    tx_type VARCHAR(255) NULL,
    status VARCHAR(255) NULL,
    description VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_트랜잭션_상태_기록 PRIMARY KEY (id)
);

COMMENT ON TABLE "트랜잭션 상태 기록" IS '트랜잭션 상태 기록 테이블';
COMMENT ON COLUMN "트랜잭션 상태 기록".tx_hash IS '트랜잭션 해시';
COMMENT ON COLUMN "트랜잭션 상태 기록".tx_type IS '트랜잭션 타입';
COMMENT ON COLUMN "트랜잭션 상태 기록".status IS '트랜잭션 상태';
COMMENT ON COLUMN "트랜잭션 상태 기록".description IS '설명';

-- Create Transaction Log Table (트랜잭션 기록)
CREATE TABLE "트랜잭션 기록" (
    id BIGSERIAL NOT NULL,
    currency INT NOT NULL,
    wallet_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    tx_hash VARCHAR(255) NOT NULL,
    tx_type tx_type_enum NOT NULL,
    amount DECIMAL(18, 8) NOT NULL,
    status tx_status_enum NOT NULL,
    fee DECIMAL(18, 8) DEFAULT 0.00000000 NULL,
    block_number BIGINT NULL,
    confirmations INT DEFAULT 0 NULL,
    from_address VARCHAR(255) NULL,
    to_address VARCHAR(255) NULL,
    memo VARCHAR(500) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PK_트랜잭션_기록 PRIMARY KEY (id),
    CONSTRAINT FK_통화종류_TO_트랜잭션_기록_1 FOREIGN KEY (currency) REFERENCES "통화종류"(id) ON DELETE RESTRICT,
    CONSTRAINT FK_유저_지갑_TO_트랜잭션_기록_1 FOREIGN KEY (wallet_id) REFERENCES "유저 지갑"(id) ON DELETE RESTRICT,
    CONSTRAINT FK_유저_TO_트랜잭션_기록_1 FOREIGN KEY (user_id) REFERENCES "유저"(id) ON DELETE CASCADE
);

COMMENT ON TABLE "트랜잭션 기록" IS '트랜잭션 기록 테이블';
COMMENT ON COLUMN "트랜잭션 기록".id IS '트랜잭션 ID';
COMMENT ON COLUMN "트랜잭션 기록".currency IS '코인 ID';
COMMENT ON COLUMN "트랜잭션 기록".wallet_id IS 'wallet_id';
COMMENT ON COLUMN "트랜잭션 기록".user_id IS 'user_id';
COMMENT ON COLUMN "트랜잭션 기록".tx_hash IS '트랜잭션 hash기록';
COMMENT ON COLUMN "트랜잭션 기록".tx_type IS '트랜잭션 타입(입금,출금)';
COMMENT ON COLUMN "트랜잭션 기록".amount IS '트랜잭션 양';
COMMENT ON COLUMN "트랜잭션 기록".status IS '트랜잭션 상태';
COMMENT ON COLUMN "트랜잭션 기록".fee IS '수수료';
COMMENT ON COLUMN "트랜잭션 기록".block_number IS '블록 번호';
COMMENT ON COLUMN "트랜잭션 기록".confirmations IS '확인 횟수';
COMMENT ON COLUMN "트랜잭션 기록".from_address IS '발신 주소';
COMMENT ON COLUMN "트랜잭션 기록".to_address IS '수신 주소';
COMMENT ON COLUMN "트랜잭션 기록".memo IS '메모';
COMMENT ON COLUMN "트랜잭션 기록".created_at IS '생성 시간';
COMMENT ON COLUMN "트랜잭션 기록".updated_at IS '업데이트 시간';

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_유저_updated_at BEFORE UPDATE ON "유저"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_유저_지갑_updated_at BEFORE UPDATE ON "유저 지갑"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_트랜잭션_기록_updated_at BEFORE UPDATE ON "트랜잭션 기록"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_트랜잭션_상태_기록_updated_at BEFORE UPDATE ON "트랜잭션 상태 기록"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

