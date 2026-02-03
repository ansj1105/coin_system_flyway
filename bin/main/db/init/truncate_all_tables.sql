-- 모든 테이블의 데이터 삭제 (테이블 구조는 유지)
-- 외래키 제약조건 때문에 CASCADE 옵션 사용
-- 주의: 이 스크립트는 모든 데이터를 삭제합니다!

-- 외래키 제약조건을 일시적으로 비활성화 (더 안전한 방법)
SET session_replication_role = 'replica';

-- 모든 테이블의 데이터 삭제 (외래키 순서 고려)
-- 참조되는 테이블부터 삭제 (자식 테이블)
TRUNCATE TABLE 
    wallet_transaction_status_logs,
    wallet_transactions,
    referral_relations,
    referral_stats_logs,
    internal_transfers,
    external_transfers,
    swaps,
    exchanges,
    payment_deposits,
    token_deposits,
    airdrop_transfers,
    airdrop_phases,
    user_bonuses,
    daily_mining,
    mining_history,
    mining_sessions,
    user_missions,
    social_links,
    phone_verifications,
    subscriptions,
    reviews,
    agency_memberships,
    email_verifications,
    notifications,
    inquiries,
    banner_clicks,
    user_wallets,
    api_keys,
    banners,
    notices,
    missions,
    mining_levels,
    currency,
    users
CASCADE;

-- 시퀀스 리셋 (선택사항 - ID를 1부터 다시 시작하려면)
-- 주의: 이 부분은 주석 처리되어 있습니다. 필요시 주석 해제하세요.
/*
SELECT setval('users_id_seq', 1, false);
SELECT setval('currency_id_seq', 1, false);
SELECT setval('user_wallets_id_seq', 1, false);
SELECT setval('wallet_transactions_id_seq', 1, false);
SELECT setval('api_keys_id_seq', 1, false);
-- 다른 시퀀스들도 필요에 따라 추가
*/

-- 외래키 제약조건 다시 활성화
SET session_replication_role = 'origin';

-- 완료 메시지
DO $$
BEGIN
    RAISE NOTICE '모든 테이블의 데이터가 삭제되었습니다. 테이블 구조는 유지됩니다.';
END $$;
