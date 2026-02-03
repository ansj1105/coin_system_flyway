-- 에어드랍 Phase 중복 입금 허용: (user_id, phase) 유니크 제약 제거
-- 동일 사용자가 동일 phase(예: phase1, phase2)에 대해 여러 건 입금 가능

ALTER TABLE airdrop_phases DROP CONSTRAINT IF EXISTS UK_airdrop_phases_user_phase;
