-- 테스트용 초기 데이터 삽입
-- 이 파일은 테스트 환경에서만 실행되어야 합니다.

-- Currency 데이터 삽입
INSERT INTO currency (code, name, chain, is_active) VALUES 
('KRW', 'South Korean Won', 'INTERNAL', true),
('USDT', 'Tether', 'ETH', true),
('BTC', 'Bitcoin', 'BTC', true),
('ETH', 'Ethereum', 'ETH', true)
ON CONFLICT (code, chain) DO NOTHING;

-- Users 데이터 삽입
INSERT INTO users (login_id, password_hash, referral_code, status) VALUES 
('test_user_1', 'hash1234', 'REF001', 'ACTIVE'),
('test_user_2', 'hash5678', 'REF002', 'ACTIVE'),
('admin_user', 'adminhash', NULL, 'ACTIVE')
ON CONFLICT (login_id) DO NOTHING;

-- User Wallets 데이터 삽입
INSERT INTO user_wallets (user_id, currency_id, address, balance, status) 
SELECT u.id, c.id, '0x1234567890abcdef', 100.00000000, 'ACTIVE'
FROM users u, currency c
WHERE u.login_id = 'test_user_1' AND c.code = 'USDT'
ON CONFLICT (user_id, currency_id) DO NOTHING;

INSERT INTO user_wallets (user_id, currency_id, address, balance, status) 
SELECT u.id, c.id, 'btc_address_1', 0.50000000, 'ACTIVE'
FROM users u, currency c
WHERE u.login_id = 'test_user_1' AND c.code = 'BTC'
ON CONFLICT (user_id, currency_id) DO NOTHING;

