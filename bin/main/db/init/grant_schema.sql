-- 스키마 권한 부여 (coin_system_cloud 데이터베이스에 연결한 후 실행)
-- 실행 방법: psql -U postgres -d coin_system_cloud -f grant_schema.sql

GRANT ALL ON SCHEMA public TO foxya;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO foxya;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO foxya;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO foxya;

