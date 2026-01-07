-- 테스트 데이터 삽입: user_id 25 (testyk)
-- 모든 테이블에 상태별 테스트 데이터 삽입

-- 1. Users 테이블 - user_id 25가 testyk인지 확인하고 없으면 생성
-- user_id 26도 internal_transfers를 위해 생성
-- testyk가 이미 존재하는 경우를 안전하게 처리 (UPDATE만 사용)
DO $$
BEGIN
    -- 시퀀스 조정 (id가 25보다 작으면 26으로 설정)
    IF (SELECT COALESCE(last_value, 0) FROM users_id_seq) < 26 THEN
        PERFORM setval('users_id_seq', 26, false);
    END IF;
    
    -- login_id='testyk'인 레코드가 id=25가 아니면, login_id를 변경하여 충돌 방지
    UPDATE users 
    SET login_id = 'old_testyk_' || id || '_' || EXTRACT(EPOCH FROM NOW())::BIGINT
    WHERE login_id = 'testyk' AND id != 25;
END $$;

-- id=25인 레코드가 있으면 업데이트, 없으면 생성
INSERT INTO users (id, login_id, password_hash, referral_code, status, country_code, level, exp, role)
VALUES (25, 'testyk', '$2a$10$testhash', 'TESTYK25', 'ACTIVE', 'KR', 5, 5000.0, 1)
ON CONFLICT (id) DO UPDATE
SET login_id = 'testyk',
    referral_code = 'TESTYK25',
    status = 'ACTIVE',
    country_code = 'KR',
    level = 5,
    exp = 5000.0,
    role = 1;

-- user_id 26 생성 (test_receiver)
DO $$
BEGIN
    -- login_id='test_receiver'인 레코드가 id=26가 아니면, login_id를 변경하여 충돌 방지
    UPDATE users 
    SET login_id = 'old_test_receiver_' || id || '_' || EXTRACT(EPOCH FROM NOW())::BIGINT
    WHERE login_id = 'test_receiver' AND id != 26;
END $$;

INSERT INTO users (id, login_id, password_hash, referral_code, status, country_code, level, exp, role)
VALUES (26, 'test_receiver', '$2a$10$testhash2', 'TEST26', 'ACTIVE', 'KR', 1, 0.0, 1)
ON CONFLICT (id) DO UPDATE
SET login_id = 'test_receiver',
    referral_code = 'TEST26',
    status = 'ACTIVE',
    country_code = 'KR',
    level = 1,
    exp = 0.0,
    role = 1;

-- 2. User Wallets - 여러 통화에 대한 지갑 생성
INSERT INTO user_wallets (user_id, currency_id, address, private_key, balance, locked_balance, status, last_sync_height)
SELECT 
    25,
    c.id,
    CASE 
        WHEN c.code = 'TRX' THEN 'TTestAddress1234567890abcdef'
        WHEN c.code = 'USDT' AND c.chain = 'TRON' THEN 'TUSDTAddress1234567890abcdef'
        WHEN c.code = 'KORI' THEN 'TKORIAddress1234567890abcdef'
        WHEN c.code = 'ETH' THEN '0xEthAddress1234567890abcdef'
        WHEN c.code = 'BTC' THEN '1BTCAddress1234567890abcdef'
        ELSE '0xDefaultAddress1234567890abcdef'
    END,
    'test_private_key_' || c.code || '_' || c.chain,
    10000.0,
    500.0,
    'ACTIVE',
    1000000
FROM currency c
WHERE c.is_active = true
ON CONFLICT (user_id, currency_id) DO UPDATE
SET balance = 10000.0,
    locked_balance = 500.0,
    status = 'ACTIVE';

-- 3. Wallet Transactions - 모든 상태별 데이터
WITH wallet_tx_data AS (
    SELECT 
        uw.id as wallet_id,
        uw.currency_id,
        status_val,
        tx_type_val,
        direction_val,
        ROW_NUMBER() OVER (PARTITION BY uw.id ORDER BY status_val, tx_type_val, direction_val) as rn
    FROM user_wallets uw
    CROSS JOIN (VALUES ('PENDING'), ('CONFIRMED'), ('FAILED'), ('CANCELED')) AS statuses(status_val)
    CROSS JOIN (VALUES ('DEPOSIT'), ('WITHDRAW'), ('TRANSFER')) AS tx_types(tx_type_val)
    CROSS JOIN (VALUES ('IN'), ('OUT')) AS directions(direction_val)
    WHERE uw.user_id = 25
    LIMIT 100
)
INSERT INTO wallet_transactions (user_id, wallet_id, currency_id, tx_hash, tx_type, direction, amount, fee, status, requested_at, confirmed_at, failed_at, request_ip, request_source, description)
SELECT 
    25,
    wallet_id,
    currency_id,
    'tx_hash_' || status_val || '_' || tx_type_val || '_' || wallet_id || '_' || rn,
    tx_type_val,
    direction_val,
    100.0 + rn * 10,
    1.0,
    status_val,
    CURRENT_TIMESTAMP - INTERVAL '10 days' + rn * INTERVAL '1 day',
    CASE WHEN status_val = 'CONFIRMED' THEN CURRENT_TIMESTAMP - INTERVAL '9 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN CURRENT_TIMESTAMP - INTERVAL '8 days' + rn * INTERVAL '1 day' ELSE NULL END,
    '192.168.1.100',
    'WEB',
    'Test transaction ' || status_val || ' ' || tx_type_val
FROM wallet_tx_data;

-- 4. Wallet Transaction Status Logs
INSERT INTO wallet_transaction_status_logs (tx_id, old_status, new_status, description, created_by)
SELECT 
    wt.id,
    CASE 
        WHEN wt.status = 'CONFIRMED' THEN 'PENDING'
        WHEN wt.status = 'FAILED' THEN 'PENDING'
        WHEN wt.status = 'CANCELED' THEN 'PENDING'
        ELSE NULL
    END,
    wt.status,
    'Status changed to ' || wt.status,
    'SYSTEM'
FROM wallet_transactions wt
WHERE wt.user_id = 25
AND wt.status IN ('CONFIRMED', 'FAILED', 'CANCELED');

-- 5. Referral Relations
INSERT INTO referral_relations (referrer_id, referred_id, level, status, created_at)
VALUES 
    (24, 25, 1, 'ACTIVE', CURRENT_TIMESTAMP - INTERVAL '30 days'),
    (23, 25, 2, 'ACTIVE', CURRENT_TIMESTAMP - INTERVAL '30 days')
ON CONFLICT (referred_id, level) DO NOTHING;

-- 6. Referral Stats Logs
INSERT INTO referral_stats_logs (user_id, direct_count, team_count, total_reward, today_reward, today_signup_count, total_signup_count)
VALUES (25, 3, 10, 5000.0, 100.0, 1, 3)
ON CONFLICT (user_id) DO UPDATE
SET direct_count = 3,
    team_count = 10,
    total_reward = 5000.0,
    today_reward = 100.0,
    today_signup_count = 1,
    total_signup_count = 3;

-- 7. Internal Transfers - 모든 상태별 데이터
-- user_id 26의 지갑도 생성
INSERT INTO user_wallets (user_id, currency_id, address, private_key, balance, locked_balance, status, last_sync_height)
SELECT 
    26,
    c.id,
    'Receiver_' || c.code || '_' || c.chain,
    'receiver_private_key_' || c.code || '_' || c.chain,
    5000.0,
    0.0,
    'ACTIVE',
    1000000
FROM currency c
WHERE c.is_active = true
ON CONFLICT (user_id, currency_id) DO NOTHING;

WITH internal_transfer_data AS (
    SELECT 
        uw1.id as sender_wallet_id,
        uw2.id as receiver_wallet_id,
        uw1.currency_id,
        status_val,
        ROW_NUMBER() OVER (PARTITION BY uw1.id ORDER BY status_val) as rn
    FROM user_wallets uw1
    CROSS JOIN (VALUES ('PENDING'), ('COMPLETED'), ('FAILED'), ('CANCELLED')) AS statuses(status_val)
    CROSS JOIN user_wallets uw2
    WHERE uw1.user_id = 25
    AND uw2.user_id = 26
    AND uw1.currency_id = uw2.currency_id
    LIMIT 20
)
INSERT INTO internal_transfers (transfer_id, sender_id, sender_wallet_id, receiver_id, receiver_wallet_id, currency_id, amount, fee, status, transfer_type, memo, order_number, transaction_type, request_ip, created_at, completed_at, failed_at)
SELECT 
    gen_random_uuid()::text,
    25,
    sender_wallet_id,
    26,
    receiver_wallet_id,
    currency_id,
    50.0 + rn * 10,
    0.5,
    status_val,
    CASE 
        WHEN status_val = 'COMPLETED' THEN 'REFERRAL_REWARD'
        ELSE 'INTERNAL'
    END,
    'Test memo ' || status_val,
    'ORDER_' || status_val || '_' || sender_wallet_id || '_' || rn,
    'WITHDRAW',
    '192.168.1.100',
    CURRENT_TIMESTAMP - INTERVAL '5 days' + rn * INTERVAL '1 day',
    CASE WHEN status_val = 'COMPLETED' THEN CURRENT_TIMESTAMP - INTERVAL '4 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN CURRENT_TIMESTAMP - INTERVAL '3 days' + rn * INTERVAL '1 day' ELSE NULL END
FROM internal_transfer_data;

-- 8. External Transfers - 모든 상태별 데이터
WITH external_transfer_data AS (
    SELECT 
        uw.id as wallet_id,
        uw.currency_id,
        status_val,
        ROW_NUMBER() OVER (PARTITION BY uw.id ORDER BY status_val) as rn
    FROM user_wallets uw
    CROSS JOIN (VALUES ('PENDING'), ('PROCESSING'), ('SUBMITTED'), ('CONFIRMED'), ('FAILED'), ('CANCELLED')) AS statuses(status_val)
    WHERE uw.user_id = 25
    LIMIT 30
)
INSERT INTO external_transfers (transfer_id, user_id, wallet_id, currency_id, to_address, amount, fee, network_fee, status, tx_hash, chain, confirmations, required_confirmations, memo, order_number, transaction_type, request_ip, created_at, submitted_at, confirmed_at, failed_at, retry_count)
SELECT 
    gen_random_uuid()::text,
    25,
    wallet_id,
    currency_id,
    'ExternalAddress_' || status_val || '_' || wallet_id || '_' || rn,
    100.0 + rn * 10,
    1.0,
    0.5,
    status_val,
    CASE WHEN status_val IN ('SUBMITTED', 'CONFIRMED') THEN 'tx_hash_' || status_val || '_' || wallet_id || '_' || rn ELSE NULL END,
    (SELECT chain FROM currency WHERE id = currency_id LIMIT 1),
    CASE WHEN status_val = 'CONFIRMED' THEN 6 ELSE 0 END,
    6,
    'Test withdrawal ' || status_val,
    'WITHDRAW_' || status_val || '_' || wallet_id || '_' || rn,
    'WITHDRAW',
    '192.168.1.100',
    CURRENT_TIMESTAMP - INTERVAL '7 days' + rn * INTERVAL '1 day',
    CASE WHEN status_val IN ('PROCESSING', 'SUBMITTED', 'CONFIRMED') THEN CURRENT_TIMESTAMP - INTERVAL '6 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'CONFIRMED' THEN CURRENT_TIMESTAMP - INTERVAL '5 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN CURRENT_TIMESTAMP - INTERVAL '4 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN 2 ELSE 0 END
FROM external_transfer_data;

-- 9. Swaps - 모든 상태별 데이터
WITH swap_data AS (
    SELECT 
        c1.id as from_currency_id,
        c2.id as to_currency_id,
        status_val,
        ROW_NUMBER() OVER (PARTITION BY status_val ORDER BY c1.id, c2.id) as rn
    FROM currency c1
    CROSS JOIN currency c2
    CROSS JOIN (VALUES ('PENDING'), ('COMPLETED'), ('FAILED')) AS statuses(status_val)
    WHERE c1.id != c2.id
    AND c1.is_active = true
    AND c2.is_active = true
    LIMIT 15
)
INSERT INTO swaps (swap_id, user_id, order_number, from_currency_id, to_currency_id, from_amount, to_amount, network, status, created_at, completed_at, failed_at, error_message)
SELECT 
    gen_random_uuid()::text,
    25,
    'SWAP_' || status_val || '_' || from_currency_id || '_' || to_currency_id || '_' || rn,
    from_currency_id,
    to_currency_id,
    100.0,
    95.0,
    'TRON',
    status_val,
    CURRENT_TIMESTAMP - INTERVAL '6 days' + rn * INTERVAL '1 day',
    CASE WHEN status_val = 'COMPLETED' THEN CURRENT_TIMESTAMP - INTERVAL '5 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN CURRENT_TIMESTAMP - INTERVAL '4 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN 'Test error message' ELSE NULL END
FROM swap_data;

-- 10. Exchanges - 모든 상태별 데이터
WITH exchange_data AS (
    SELECT 
        c1.id as from_currency_id,
        c2.id as to_currency_id,
        status_val,
        ROW_NUMBER() OVER (PARTITION BY status_val ORDER BY c1.id, c2.id) as rn
    FROM currency c1
    CROSS JOIN currency c2
    CROSS JOIN (VALUES ('PENDING'), ('COMPLETED'), ('FAILED')) AS statuses(status_val)
    WHERE c1.id != c2.id
    AND c1.is_active = true
    AND c2.is_active = true
    LIMIT 12
)
INSERT INTO exchanges (exchange_id, user_id, order_number, from_currency_id, to_currency_id, from_amount, to_amount, status, created_at, completed_at, failed_at, error_message)
SELECT 
    gen_random_uuid()::text,
    25,
    'EXCHANGE_' || status_val || '_' || from_currency_id || '_' || to_currency_id || '_' || rn,
    from_currency_id,
    to_currency_id,
    1000.0,
    950.0,
    status_val,
    CURRENT_TIMESTAMP - INTERVAL '5 days' + rn * INTERVAL '1 day',
    CASE WHEN status_val = 'COMPLETED' THEN CURRENT_TIMESTAMP - INTERVAL '4 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN CURRENT_TIMESTAMP - INTERVAL '3 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN 'Test error message' ELSE NULL END
FROM exchange_data;

-- 11. Payment Deposits - 모든 상태별 데이터
WITH payment_deposit_data AS (
    SELECT 
        c.id as currency_id,
        status_val,
        method_val,
        ROW_NUMBER() OVER (PARTITION BY status_val, method_val ORDER BY c.id) as rn
    FROM currency c
    CROSS JOIN (VALUES ('PENDING'), ('COMPLETED'), ('FAILED')) AS statuses(status_val)
    CROSS JOIN (VALUES ('CARD'), ('BANK_TRANSFER'), ('PAY')) AS methods(method_val)
    WHERE c.is_active = true
    LIMIT 18
)
INSERT INTO payment_deposits (deposit_id, user_id, order_number, currency_id, amount, deposit_method, payment_amount, status, created_at, completed_at, failed_at, error_message)
SELECT 
    gen_random_uuid()::text,
    25,
    'PAYMENT_' || status_val || '_' || method_val || '_' || currency_id || '_' || rn,
    currency_id,
    10000.0,
    method_val,
    10000.0,
    status_val,
    CURRENT_TIMESTAMP - INTERVAL '4 days' + rn * INTERVAL '1 day',
    CASE WHEN status_val = 'COMPLETED' THEN CURRENT_TIMESTAMP - INTERVAL '3 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN CURRENT_TIMESTAMP - INTERVAL '2 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN 'Test error message' ELSE NULL END
FROM payment_deposit_data;

-- 12. Token Deposits - 모든 상태별 데이터
WITH token_deposit_data AS (
    SELECT 
        c.id as currency_id,
        COALESCE(c.chain, 'TRON') as network,
        status_val,
        ROW_NUMBER() OVER (PARTITION BY status_val ORDER BY c.id) as rn
    FROM currency c
    CROSS JOIN (VALUES ('PENDING'), ('COMPLETED'), ('FAILED')) AS statuses(status_val)
    WHERE c.is_active = true
    LIMIT 12
)
INSERT INTO token_deposits (deposit_id, user_id, order_number, currency_id, amount, network, sender_address, tx_hash, status, created_at, confirmed_at, failed_at, error_message)
SELECT 
    gen_random_uuid()::text,
    25,
    'TOKEN_DEPOSIT_' || status_val || '_' || currency_id || '_' || rn,
    currency_id,
    500.0,
    network,
    'SenderAddress_' || status_val || '_' || currency_id || '_' || rn,
    CASE WHEN status_val = 'COMPLETED' THEN 'tx_hash_' || status_val || '_' || currency_id || '_' || rn ELSE NULL END,
    status_val,
    CURRENT_TIMESTAMP - INTERVAL '3 days' + rn * INTERVAL '1 day',
    CASE WHEN status_val = 'COMPLETED' THEN CURRENT_TIMESTAMP - INTERVAL '2 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN CURRENT_TIMESTAMP - INTERVAL '1 days' + rn * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN status_val = 'FAILED' THEN 'Test error message' ELSE NULL END
FROM token_deposit_data;

-- 13. Airdrop Phases - 모든 상태별 데이터
INSERT INTO airdrop_phases (user_id, phase, status, amount, unlock_date, days_remaining)
VALUES 
    (25, 1, 'RELEASED', 1000.0, CURRENT_TIMESTAMP - INTERVAL '10 days', 0),
    (25, 2, 'PROCESSING', 2000.0, CURRENT_TIMESTAMP + INTERVAL '10 days', 10),
    (25, 3, 'PROCESSING', 3000.0, CURRENT_TIMESTAMP + INTERVAL '20 days', 20),
    (25, 4, 'PROCESSING', 4000.0, CURRENT_TIMESTAMP + INTERVAL '30 days', 30),
    (25, 5, 'PROCESSING', 5000.0, CURRENT_TIMESTAMP + INTERVAL '40 days', 40)
ON CONFLICT (user_id, phase) DO NOTHING;

-- 14. Airdrop Transfers - 모든 상태별 데이터
WITH airdrop_transfer_data AS (
    SELECT 
        uw.id as wallet_id,
        uw.currency_id,
        status_val,
        ROW_NUMBER() OVER (PARTITION BY uw.id ORDER BY status_val) as rn
    FROM user_wallets uw
    CROSS JOIN (VALUES ('PENDING'), ('COMPLETED'), ('FAILED'), ('CANCELLED')) AS statuses(status_val)
    WHERE uw.user_id = 25
    LIMIT 16
)
INSERT INTO airdrop_transfers (transfer_id, user_id, wallet_id, currency_id, amount, status, order_number)
SELECT 
    gen_random_uuid()::text,
    25,
    wallet_id,
    currency_id,
    100.0 + rn * 10,
    status_val,
    'AIRDROP_' || status_val || '_' || wallet_id || '_' || rn
FROM airdrop_transfer_data;

-- 15. User Bonuses
INSERT INTO user_bonuses (user_id, bonus_type, is_active, expires_at, current_count, max_count, metadata)
VALUES 
    (25, 'SOCIAL_LINK', true, NULL, 0, NULL, '{"provider": "KAKAO"}'::jsonb),
    (25, 'PHONE_VERIFICATION', true, NULL, 0, NULL, NULL),
    (25, 'AD_WATCH', true, CURRENT_TIMESTAMP + INTERVAL '30 days', 5, 10, NULL),
    (25, 'REFERRAL', true, NULL, 0, NULL, NULL),
    (25, 'PREMIUM_SUBSCRIPTION', true, CURRENT_TIMESTAMP + INTERVAL '90 days', 0, NULL, NULL),
    (25, 'REVIEW', true, NULL, 0, NULL, '{"platform": "GOOGLE_PLAY"}'::jsonb),
    (25, 'AGENCY', true, NULL, 0, NULL, '{"agency_id": "AGENCY001"}'::jsonb),
    (25, 'REFERRAL_CODE_INPUT', true, NULL, 0, NULL, NULL)
ON CONFLICT (user_id, bonus_type) DO NOTHING;

-- 16. Daily Mining
INSERT INTO daily_mining (user_id, mining_date, mining_amount, reset_at)
VALUES 
    (25, CURRENT_DATE - INTERVAL '5 days', 5000.0, (CURRENT_DATE - INTERVAL '4 days')::timestamp),
    (25, CURRENT_DATE - INTERVAL '4 days', 6000.0, (CURRENT_DATE - INTERVAL '3 days')::timestamp),
    (25, CURRENT_DATE - INTERVAL '3 days', 7000.0, (CURRENT_DATE - INTERVAL '2 days')::timestamp),
    (25, CURRENT_DATE - INTERVAL '2 days', 8000.0, (CURRENT_DATE - INTERVAL '1 days')::timestamp),
    (25, CURRENT_DATE - INTERVAL '1 days', 9000.0, CURRENT_DATE::timestamp),
    (25, CURRENT_DATE, 2000.0, (CURRENT_DATE + INTERVAL '1 days')::timestamp)
ON CONFLICT (user_id, mining_date) DO NOTHING;

-- 17. Mining History - 모든 상태별 데이터
WITH mining_history_data AS (
    SELECT 
        type_val,
        status_val,
        ROW_NUMBER() OVER (ORDER BY type_val, status_val) as rn
    FROM (VALUES ('BROADCAST_PROGRESS'), ('BROADCAST_WATCH')) AS types(type_val)
    CROSS JOIN (VALUES ('COMPLETED'), ('FAILED'), ('CANCELLED')) AS statuses(status_val)
    LIMIT 20
)
INSERT INTO mining_history (user_id, level, amount, type, status)
SELECT 
    25,
    5,
    100.0 + rn * 10,
    type_val,
    status_val
FROM mining_history_data;

-- 18. User Missions
WITH user_mission_data AS (
    SELECT 
        m.id as mission_id,
        m.required_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY CURRENT_DATE) as rn
    FROM missions m
    WHERE m.is_active = true
    LIMIT 15
)
INSERT INTO user_missions (user_id, mission_id, mission_date, current_count, reset_at)
SELECT 
    25,
    mission_id,
    CURRENT_DATE - INTERVAL '2 days' + rn * INTERVAL '1 day',
    CASE WHEN rn = 1 THEN required_count ELSE 0 END,
    (CURRENT_DATE - INTERVAL '1 days' + rn * INTERVAL '1 day')::timestamp + INTERVAL '1 day'
FROM user_mission_data;

-- 19. Social Links
INSERT INTO social_links (user_id, provider, provider_user_id, email)
VALUES 
    (25, 'KAKAO', 'kakao_user_12345', 'testyk@kakao.com'),
    (25, 'GOOGLE', 'google_user_12345', 'testyk@gmail.com')
ON CONFLICT (user_id, provider) DO NOTHING;

-- 20. Phone Verifications
INSERT INTO phone_verifications (user_id, phone_number, verification_code, is_verified, verified_at, expires_at)
VALUES (25, '01012345678', '123456', true, CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '5 days')
ON CONFLICT (user_id) DO NOTHING;

-- 21. Subscriptions
INSERT INTO subscriptions (user_id, package_type, is_active, started_at, expires_at)
VALUES (25, 'PREMIUM', true, CURRENT_TIMESTAMP - INTERVAL '30 days', CURRENT_TIMESTAMP + INTERVAL '60 days')
ON CONFLICT (user_id) DO NOTHING;

-- 22. Reviews
INSERT INTO reviews (user_id, platform, review_id, reviewed_at)
VALUES (25, 'GOOGLE_PLAY', 'review_12345', CURRENT_TIMESTAMP - INTERVAL '20 days')
ON CONFLICT (user_id) DO NOTHING;

-- 23. Agency Memberships
INSERT INTO agency_memberships (user_id, agency_id, agency_name, joined_at)
VALUES (25, 'AGENCY001', 'Test Agency', CURRENT_TIMESTAMP - INTERVAL '15 days')
ON CONFLICT (user_id) DO NOTHING;

-- 24. Email Verifications
INSERT INTO email_verifications (user_id, email, verification_code, is_verified, verified_at, expires_at)
VALUES (25, 'testyk@example.com', 'EMAIL123', true, CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP + INTERVAL '25 days')
ON CONFLICT (user_id) DO NOTHING;

-- 25. Notifications
INSERT INTO notifications (user_id, type, title, message, is_read, related_id, metadata)
VALUES 
    (25, 'DEPOSIT_SUCCESS', '입금 완료', '입금이 성공적으로 완료되었습니다.', false, 1, '{"amount": 10000}'::jsonb),
    (25, 'WITHDRAW_SUCCESS', '출금 완료', '출금이 성공적으로 완료되었습니다.', true, 2, '{"amount": 5000}'::jsonb),
    (25, 'EXCHANGE_SUCCESS', '환전 완료', '환전이 성공적으로 완료되었습니다.', false, 3, NULL),
    (25, 'SWAP_SUCCESS', '스왑 완료', '스왑이 성공적으로 완료되었습니다.', true, 4, NULL),
    (25, 'NOTICE', '공지사항', '새로운 공지사항이 있습니다.', false, NULL, NULL),
    (25, 'LEVEL_UP', '레벨 업', '레벨이 올라갔습니다!', false, NULL, '{"level": 5}'::jsonb),
    (25, 'MISSION_ACTIVATED', '미션 활성화', '새로운 미션이 활성화되었습니다.', false, NULL, NULL);

-- 26. Inquiries - 모든 상태별 데이터
INSERT INTO inquiries (user_id, subject, content, email, status)
VALUES 
    (25, '계정 문의', '계정 관련 문의드립니다.', 'testyk@example.com', 'PENDING'),
    (25, '입금 문의', '입금이 안됩니다.', 'testyk@example.com', 'PROCESSING'),
    (25, '출금 문의', '출금이 안됩니다.', 'testyk@example.com', 'COMPLETED'),
    (25, '기타 문의', '기타 문의사항입니다.', 'testyk@example.com', 'PENDING');

-- 27. Banner Clicks (배너가 있는 경우)
WITH banner_click_data AS (
    SELECT 
        b.id as banner_id,
        ROW_NUMBER() OVER (ORDER BY b.id) as rn
    FROM banners b
    WHERE b.is_active = true
    LIMIT 5
)
INSERT INTO banner_clicks (banner_id, user_id, clicked_at, ip_address, user_agent)
SELECT 
    banner_id,
    25,
    CURRENT_TIMESTAMP - INTERVAL '3 days' + rn * INTERVAL '1 hour',
    '192.168.1.100',
    'Mozilla/5.0 Test Browser'
FROM banner_click_data;

