-- Create ENUM types for PostgreSQL

-- Transaction type enum
CREATE TYPE tx_type_enum AS ENUM ('입금', '출금', 'DEPOSIT', 'WITHDRAWAL');

-- Transaction status enum
CREATE TYPE tx_status_enum AS ENUM ('대기중', '처리중', '완료', '실패', 'PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');

-- Referral status enum
CREATE TYPE referral_status_enum AS ENUM ('active', 'deactive', 'ACTIVE', 'DEACTIVE');

-- Currency type enum
CREATE TYPE currency_type_enum AS ENUM ('KRW', 'USDT', 'BTC', 'ETH', 'BNB');

