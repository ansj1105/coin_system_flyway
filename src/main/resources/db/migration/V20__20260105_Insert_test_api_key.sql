-- 테스트용 API Key 데이터
-- R__로 시작하는 파일은 Repeatable migration으로, 내용이 변경되면 다시 실행됩니다

-- 기존 테스트 데이터 삭제
DELETE FROM api_keys WHERE client_name IN ('admin', 'test', '안서정', '엑스이허브');

-- 테스트용 API Key 추가
INSERT INTO api_keys (api_key, api_secret, client_name, description, is_active, expires_at, created_at, updated_at)
VALUES 
    -- 활성화된 관리자 API Key (만료일 없음)
    ('sk_live_admin_2024_a8f3b2c9d1e4f5a6b7c8d9e0f1a2b3c', 'sec_live_admin_2024_x9y8z7w6v5u4t3s2r1q0p9o8n7m6l', 'admin', '관리자 API 키', true, NULL, NOW(), NOW()),
    -- 활성화된 테스트 API Key (만료일 있음, 미래)
    ('sk_test_dev_2024_b7e2a1d0c9f8e7d6c5b4a3b2c1d0e9f', 'sec_test_dev_2024_y8x7w6v5u4t3s2r1q0p9o8n7m6l5', 'test', '테스트용 API 키 (만료일 있음)', true, NOW() + INTERVAL '30 days', NOW(), NOW()),
    -- 비활성화된 API Key
    ('sk_live_anseojeong_2024_c6d1e0f9a8b7c6d5e4f3a2b1c0d9e', 'sec_live_anseojeong_2024_z9y8x7w6v5u4t3s2r1q0p9o8n7', '안서정', '안서정 API 키 (비활성화)', false, NULL, NOW(), NOW()),
    -- 만료된 API Key
    ('sk_live_xhub_2024_d5c0b9a8f7e6d5c4b3a2f1e0d9c8b7a', 'sec_live_xhub_2024_a0b9c8d7e6f5a4b3c2d1e0f9a8b7c', '엑스이허브', '엑스이허브 API 키 (만료됨)', true, NOW() - INTERVAL '1 day', NOW(), NOW())
ON CONFLICT (api_key) DO UPDATE
SET 
    api_secret = EXCLUDED.api_secret,
    client_name = EXCLUDED.client_name,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active,
    expires_at = EXCLUDED.expires_at,
    updated_at = NOW();

-- 시퀀스 리셋 (ID 순서 보장)
SELECT setval('api_keys_id_seq', (SELECT COALESCE(MAX(id), 1) FROM api_keys));

