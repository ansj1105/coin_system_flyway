# Coin System Flyway Migration

PostgreSQL 데이터베이스 마이그레이션을 위한 Flyway 프로젝트입니다.

## 프로젝트 구조

```
coin_system_flyway/
├── build.gradle              # Gradle 빌드 설정
├── settings.gradle           # Gradle 프로젝트 설정
├── gradle.properties         # 데이터베이스 연결 설정
└── src/main/resources/db/migration/
    ├── V1__Create_enum_types.sql    # ENUM 타입 생성
    ├── V2__Create_tables.sql        # 테이블 생성
    └── V3__Create_indexes.sql       # 인덱스 생성
```

## 데이터베이스 스키마

### 테이블 목록

1. **통화종류** - 통화 종류 관리
2. **유저** - 사용자 정보
3. **유저 지갑** - 사용자 지갑 정보
4. **레퍼럴 정보 테이블** - 레퍼럴 정보 관리
5. **레퍼럴 관계 테이블** - 레퍼럴 관계 관리
6. **트랜잭션 기록** - 트랜잭션 기록
7. **트랜잭션 상태 기록** - 트랜잭션 상태 기록

## 사전 요구사항

- Java 11 이상
- PostgreSQL 12 이상
- **Gradle은 설치 불필요**: 프로젝트에 포함된 Gradle Wrapper(`gradlew`)로 동일 버전의 Gradle을 자동 사용합니다.

## 설정

### 1. 데이터베이스 생성

데이터베이스와 사용자를 생성하는 방법은 여러 가지가 있습니다:

#### 방법 1: 통합 SQL 스크립트 사용 (권장)

```bash
psql -U postgres -f src/main/resources/db/init/create_all.sql
```

#### 방법 2: 셸 스크립트 사용

```bash
cd src/main/resources/db/init
./create_database_and_user.sh
```

#### 방법 3: 수동으로 SQL 실행

```sql
-- postgres 슈퍼유저로 연결
psql -U postgres

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

-- 데이터베이스 권한 부여
GRANT ALL PRIVILEGES ON DATABASE coin_system_cloud TO foxya;

-- 데이터베이스에 연결하여 스키마 권한 부여
\c coin_system_cloud
GRANT ALL ON SCHEMA public TO foxya;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO foxya;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO foxya;
```

자세한 내용은 `src/main/resources/db/init/README.md`를 참조하세요.

### 2. 데이터베이스 연결 설정

`gradle.properties` 파일에 이미 설정되어 있습니다:

```properties
db.url=jdbc:postgresql://localhost:5432/coin_system_cloud
db.user=foxya
db.password=foxya1124!@
```

또는 명령줄에서 속성을 전달할 수도 있습니다:

```bash
./gradlew flywayMigrate -Pdb.url=jdbc:postgresql://localhost:5432/coin_system_cloud -Pdb.user=foxya -Pdb.password=foxya1124!@
```

## 사용 방법

### 서버에서 마이그레이션 실행

서버에는 **Java만 설치**되어 있으면 됩니다. Gradle은 `gradlew`가 필요한 버전을 자동으로 받아 사용합니다.

```bash
# 기본 설정( gradle.properties 또는 아래 -P 옵션)으로 마이그레이션
./gradlew flywayMigrate

# DB 연결을 옵션으로 지정
./gradlew flywayMigrate -Pdb.url=jdbc:postgresql://호스트:5432/DB명 -Pdb.user=유저 -Pdb.password=비밀번호
```

### 마이그레이션 실행 (로컬)

```bash
./gradlew flywayMigrate
```

### 마이그레이션 정보 확인

```bash
./gradlew flywayInfo
```

### 마이그레이션 되돌리기 (Rollback)

```bash
./gradlew flywayRepair
```

### 기존 DB에 Flyway 적용 (데이터 유지)

이미 테이블이 있는 DB에서 `flywayMigrate` 시 **"relation already exists"** 가 나오는 경우, **애플리케이션 데이터는 건드리지 않고** Flyway 기록만 맞추면 됩니다.

**주의:** 아래에서 정리하는 것은 Flyway 전용 테이블 `flyway_schema_history` 뿐이며, **실제 비즈니스 테이블/데이터는 삭제되지 않습니다.**

1. **실패한 마이그레이션 정리**
   ```bash
   ./gradlew flywayRepair
   ```

2. **Flyway 스키마 이력 테이블 삭제** (해당 DB에 접속해서 실행)
   - baseline은 "테이블이 없을 때"만 동작하므로, **테이블을 DROP**해야 합니다. 비즈니스 테이블/데이터는 영향 없음.
   - 현재 DB가 **이미 최신 스키마(V42까지)** 라고 가정할 때만 사용합니다.
   ```sql
   -- 해당 DB에 접속한 뒤 (예: psql -U foxya -d coin_system_cloud)
   DROP TABLE IF EXISTS flyway_schema_history;
   ```

3. **Baseline으로 "여기까지 적용됨" 표시**
   - 마지막 적용된 마이그레이션 버전이 V42라면:
   ```bash
   ./gradlew flywayBaseline -Pflyway.baselineVersion=42
   ```
   - 다른 버전까지 적용된 DB라면 그 버전 번호로 넣습니다 (예: `-Pflyway.baselineVersion=30`).

4. **이후부터는 일반 마이그레이션**
   ```bash
   ./gradlew flywayMigrate
   ```
   - V43 이상이 생기면 이 명령으로만 적용하면 됩니다.

**DB가 V42보다 이전 스키마인 경우:** `flyway.baselineVersion` 을 실제 적용된 마지막 버전으로 넣고, 4번 `flywayMigrate` 를 실행하면 그 다음 버전들만 적용됩니다.

### 마이그레이션 검증

```bash
./gradlew flywayValidate
```

## 테스트

이 프로젝트는 Testcontainers를 사용하여 실제 PostgreSQL 인스턴스에서 마이그레이션을 테스트합니다.

### 테스트 실행

```bash
./gradlew test
```

또는 특정 테스트만 실행:

```bash
./gradlew test --tests "FlywayMigrationTest"
./gradlew test --tests "DatabaseSchemaTest"
```

### 테스트 내용

테스트는 다음을 검증합니다:

1. **FlywayMigrationTest**
   - 마이그레이션이 성공적으로 실행되는지 확인
   - 모든 테이블이 생성되는지 확인
   - ENUM 타입이 생성되는지 확인
   - 인덱스가 생성되는지 확인
   - 외래키 제약조건이 생성되는지 확인
   - 트리거가 생성되는지 확인
   - 마이그레이션의 멱등성(idempotent) 확인
   - 데이터 삽입 및 조회 테스트

2. **DatabaseSchemaTest**
   - 테이블 구조 검증
   - 외래키 관계 검증
   - ENUM 타입 사용 검증
   - 유니크 제약조건 검증
   - 기본값 설정 검증

### 테스트 환경

- **Testcontainers**: Docker를 사용하여 격리된 PostgreSQL 인스턴스 생성
- **PostgreSQL 버전**: 15-alpine
- **테스트 데이터베이스**: coin_system_test
- **테스트 사용자**: test_user / test_password

**참고**: 테스트 실행을 위해서는 Docker가 설치되어 있어야 합니다.

## 주요 개선사항

1. **ENUM 타입 정의**: PostgreSQL ENUM 타입으로 트랜잭션 타입, 상태 등을 정의
2. **AUTO_INCREMENT**: SERIAL/BIGSERIAL로 자동 증가 ID 구현
3. **인덱스 추가**: 쿼리 성능 향상을 위한 인덱스 추가
4. **외래키 제약조건**: 데이터 무결성을 위한 외래키 관계 설정
5. **트리거**: `updated_at` 필드 자동 업데이트를 위한 트리거 추가
6. **추가 필드**: 
   - 통화종류: name, symbol 필드 추가
   - 유저: email, phone, status 필드 추가
   - 레퍼럴 정보: total_reward 필드 추가
   - 레퍼럴 관계: reward_rate 필드 추가
   - 트랜잭션 기록: fee, block_number, confirmations, from_address, to_address, memo 필드 추가
7. **UNIQUE 제약조건**: 중복 방지를 위한 유니크 제약조건 추가
8. **기본값 설정**: created_at, updated_at 등에 기본값 설정

## 마이그레이션 순서

1. **V1__Create_enum_types.sql**: ENUM 타입 생성
2. **V2__Create_tables.sql**: 모든 테이블 생성 및 외래키 관계 설정
3. **V3__Create_indexes.sql**: 성능 최적화를 위한 인덱스 생성

## 주의사항

- 한글 테이블명과 컬럼명을 사용하므로 PostgreSQL에서는 따옴표로 감싸야 합니다.
- 프로덕션 환경에서는 반드시 백업 후 마이그레이션을 실행하세요.
- 마이그레이션 파일명은 Flyway 규칙을 따라야 합니다: `V{version}__{description}.sql`

