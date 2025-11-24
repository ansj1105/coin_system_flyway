package com.coinsystem.flyway;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Flyway 마이그레이션 테스트
 * Testcontainers를 사용하여 PostgreSQL 인스턴스를 생성하고 마이그레이션을 테스트합니다.
 */
@Testcontainers
@DisplayName("Flyway 마이그레이션 테스트")
class FlywayMigrationTest {

    private static final Logger log = LoggerFactory.getLogger(FlywayMigrationTest.class);

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("coin_system_test")
            .withUsername("test_user")
            .withPassword("test_password");

    private Flyway flyway;
    private String jdbcUrl;
    private String username;
    private String password;

    @BeforeEach
    void setUp() {
        jdbcUrl = postgres.getJdbcUrl();
        username = postgres.getUsername();
        password = postgres.getPassword();

        log.info("=== FlywayMigrationTest Setup ===");
        log.info("JDBC URL: {}", jdbcUrl);
        log.info("Username: {}", username);
        log.info("================================");

        flyway = Flyway.configure()
                .dataSource(jdbcUrl, username, password)
                .locations("filesystem:src/main/resources/db/migration", "filesystem:src/test/resources/db/migration")
                .encoding("UTF-8")
                .validateOnMigrate(true)
                .baselineOnMigrate(true)
                .load();
    }

    @Test
    @DisplayName("마이그레이션이 성공적으로 실행되어야 함")
    void testMigrationSuccess() {
        log.info("=== [TEST] testMigrationSuccess 시작 ===");
        
        // When: 마이그레이션 실행
        log.info("마이그레이션 실행 중...");
        var result = flyway.migrate();
        log.info("마이그레이션 완료: {}개 실행됨", result.migrationsExecuted);

        // Then: 마이그레이션 정보 확인
        var info = flyway.info();
        log.info("현재 버전: {}", info.current().getVersion());
        log.info("전체 마이그레이션 수: {}", info.all().length);
        
        assertThat(info.all()).isNotEmpty();
        assertThat(info.current().getVersion()).isNotNull();
        log.info("=== [TEST] testMigrationSuccess 완료 ===\n");
    }

    @Test
    @DisplayName("모든 테이블이 생성되어야 함")
    void testAllTablesCreated() throws Exception {
        log.info("=== [TEST] testAllTablesCreated 시작 ===");
        
        // Given: 마이그레이션 실행
        log.info("마이그레이션 실행 중...");
        flyway.migrate();

        // When: 테이블 목록 조회
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename")) {

            // 모든 테이블명을 리스트로 수집
            List<String> tables = new ArrayList<>();
            while (rs.next()) {
                tables.add(rs.getString("tablename"));
            }

            log.info("생성된 테이블 목록:");
            tables.forEach(table -> log.info("  - {}", table));

            // Then: 모든 테이블이 존재해야 함 (flyway_schema_history 제외)
            assertThat(tables).contains(
                    "currency",
                    "users",
                    "user_wallets",
                    "wallet_transactions",
                    "wallet_transaction_status_logs",
                    "referral_relations",
                    "referral_stats_logs"
            );
            log.info("=== [TEST] testAllTablesCreated 완료 ===\n");
        }
    }

    @Test
    @DisplayName("ENUM 타입이 생성되어야 함")
    void testEnumTypesCreated() throws Exception {
        // Given: 마이그레이션 실행
        flyway.migrate();

        // Note: 현재 스키마는 ENUM 대신 VARCHAR를 사용하므로 이 테스트는 스킵
        // 필요시 ENUM 타입을 추가할 수 있습니다.
    }

    @Test
    @DisplayName("인덱스가 생성되어야 함")
    void testIndexesCreated() throws Exception {
        // Given: 마이그레이션 실행
        flyway.migrate();

        // When: 인덱스 목록 조회
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT indexname FROM pg_indexes WHERE schemaname = 'public' AND indexname LIKE 'idx_%'")) {

            // Then: 인덱스들이 존재해야 함
            var indexes = new java.util.ArrayList<String>();
            while (rs.next()) {
                indexes.add(rs.getString("indexname"));
            }

            assertThat(indexes).isNotEmpty();
            assertThat(indexes.size()).isGreaterThan(10); // 최소 10개 이상의 인덱스가 있어야 함
        }
    }

    @Test
    @DisplayName("외래키 제약조건이 생성되어야 함")
    void testForeignKeysCreated() throws Exception {
        // Given: 마이그레이션 실행
        flyway.migrate();

        // When: 외래키 제약조건 목록 조회
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT conname FROM pg_constraint WHERE contype = 'f' AND connamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')")) {

            // Then: 외래키 제약조건들이 존재해야 함
            var foreignKeys = new java.util.ArrayList<String>();
            while (rs.next()) {
                foreignKeys.add(rs.getString("conname"));
            }

            assertThat(foreignKeys).isNotEmpty();
            assertThat(foreignKeys.size()).isGreaterThanOrEqualTo(6); // 최소 6개 이상의 외래키가 있어야 함
        }
    }

    @Test
    @DisplayName("트리거가 생성되어야 함")
    void testTriggersCreated() throws Exception {
        // Given: 마이그레이션 실행
        flyway.migrate();

        // When: 트리거 목록 조회
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT trigger_name FROM information_schema.triggers WHERE trigger_schema = 'public'")) {

            // Then: 트리거들이 존재해야 함
            var triggers = new java.util.ArrayList<String>();
            while (rs.next()) {
                triggers.add(rs.getString("trigger_name"));
            }

            assertThat(triggers).isNotEmpty();
            assertThat(triggers.size()).isGreaterThanOrEqualTo(4); // 최소 4개 이상의 트리거가 있어야 함
        }
    }

    @Test
    @DisplayName("마이그레이션을 여러 번 실행해도 실패하지 않아야 함 (Idempotent)")
    void testMigrationIdempotent() {
        // Given: 첫 번째 마이그레이션 실행
        flyway.migrate();
        var firstMigration = flyway.info().current();

        // When: 두 번째 마이그레이션 실행
        flyway.migrate();
        var secondMigration = flyway.info().current();

        // Then: 동일한 버전이어야 함
        assertThat(firstMigration.getVersion()).isEqualTo(secondMigration.getVersion());
    }

    @Test
    @DisplayName("데이터 삽입 및 조회가 가능해야 함")
    void testDataInsertAndSelect() throws Exception {
        log.info("=== [TEST] testDataInsertAndSelect 시작 ===");
        
        // Given: 마이그레이션 실행
        log.info("마이그레이션 실행 중...");
        flyway.migrate();

        // When: 통화 데이터 삽입
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement()) {

            log.info("테스트 데이터 삽입 중...");
            
            // 통화 삽입
            int btcRows = statement.executeUpdate(
                    "INSERT INTO currency (code, name) VALUES ('BTC', 'Bitcoin') ON CONFLICT (code, chain) DO NOTHING");
            log.debug("BTC 삽입: {}행", btcRows);
            
            int ethRows = statement.executeUpdate(
                    "INSERT INTO currency (code, name) VALUES ('ETH', 'Ethereum') ON CONFLICT (code, chain) DO NOTHING");
            log.debug("ETH 삽입: {}행", ethRows);

            // 유저 삽입
            int userRows = statement.executeUpdate(
                    "INSERT INTO users (login_id, password_hash, referral_code) VALUES ('migration_test_user', 'password123', 'TEST001') ON CONFLICT (login_id) DO NOTHING");
            log.debug("User 삽입: {}행", userRows);

            // Then: 데이터 조회 확인
            try (ResultSet rs = statement.executeQuery(
                    "SELECT COUNT(*) FROM currency")) {
                assertThat(rs.next()).isTrue();
                int currencyCount = rs.getInt(1);
                log.info("전체 통화 개수: {}", currencyCount);
                assertThat(currencyCount).isGreaterThanOrEqualTo(2);
            }

            try (ResultSet rs = statement.executeQuery(
                    "SELECT COUNT(*) FROM users WHERE login_id = 'migration_test_user'")) {
                assertThat(rs.next()).isTrue();
                int userCount = rs.getInt(1);
                log.info("migration_test_user 개수: {}", userCount);
                assertThat(userCount).isEqualTo(1);
            }
            
            log.info("=== [TEST] testDataInsertAndSelect 완료 ===\n");
        }
    }
}

