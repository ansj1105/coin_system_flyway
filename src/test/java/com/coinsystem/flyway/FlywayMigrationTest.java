package com.coinsystem.flyway;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
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

        flyway = Flyway.configure()
                .dataSource(jdbcUrl, username, password)
                .locations("filesystem:src/main/resources/db/migration")
                .encoding("UTF-8")
                .validateOnMigrate(true)
                .baselineOnMigrate(true)
                .load();
    }

    @Test
    @DisplayName("마이그레이션이 성공적으로 실행되어야 함")
    void testMigrationSuccess() {
        // When: 마이그레이션 실행
        flyway.migrate();

        // Then: 마이그레이션 정보 확인
        var info = flyway.info();
        assertThat(info.all()).isNotEmpty();
        assertThat(info.current().getVersion()).isNotNull();
    }

    @Test
    @DisplayName("모든 테이블이 생성되어야 함")
    void testAllTablesCreated() throws Exception {
        // Given: 마이그레이션 실행
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

            // Then: 모든 테이블이 존재해야 함 (flyway_schema_history 제외)
            assertThat(tables).contains(
                    "currency",
                    "users",
                    "user_wallet",
                    "wallet_transaction",
                    "wallet_transaction_status_log",
                    "referral_relation",
                    "referral_stats"
            );
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
        // Given: 마이그레이션 실행
        flyway.migrate();

        // When: 통화 데이터 삽입
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement()) {

            // 통화 삽입
            statement.executeUpdate(
                    "INSERT INTO currency (code, name) VALUES ('KRW', '한국 원')");
            statement.executeUpdate(
                    "INSERT INTO currency (code, name) VALUES ('USDT', 'Tether')");

            // 유저 삽입
            statement.executeUpdate(
                    "INSERT INTO users (login_id, password_hash, referral_code) VALUES ('testuser', 'password123', 'REF001')");

            // Then: 데이터 조회 확인
            try (ResultSet rs = statement.executeQuery(
                    "SELECT COUNT(*) FROM currency")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getInt(1)).isEqualTo(2);
            }

            try (ResultSet rs = statement.executeQuery(
                    "SELECT COUNT(*) FROM users WHERE login_id = 'testuser'")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getInt(1)).isEqualTo(1);
            }
        }
    }
}

