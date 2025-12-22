-- Update user role
-- ansj1105 유저의 role을 3(슈퍼어드민)으로 설정

UPDATE users 
SET role = 3 
WHERE login_id = 'ansj1105';

-- 확인
SELECT id, login_id, role, status 
FROM users 
WHERE login_id = 'ansj1105';



