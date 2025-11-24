-- PostgreSQL 데이터베이스 및 사용자 생성
-- psql -U postgres 실행 후 아래 SQL 복사하여 실행

-- 기존 데이터베이스 삭제 (사용자 권한이 있어도 강제 삭제)
DROP DATABASE IF EXISTS coin_system_cloud;

-- 기존 사용자 삭제
DROP ROLE IF EXISTS foxya;

-- 데이터베이스 생성
CREATE DATABASE coin_system_cloud
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    TEMPLATE = template0;

-- 사용자 생성 및 비밀번호 설정
CREATE USER foxya WITH
    PASSWORD 'foxya1124!@'
    CREATEDB
    CREATEROLE
    LOGIN;

-- 데이터베이스에 대한 모든 권한 부여
GRANT ALL PRIVILEGES ON DATABASE coin_system_cloud TO foxya;

-- 스키마 권한은 별도로 실행 필요
-- 방법 1: psql에서 \c coin_system_cloud 실행 후 grant_schema.sql 실행
-- 방법 2: psql -U postgres -d coin_system_cloud -f grant_schema.sql
