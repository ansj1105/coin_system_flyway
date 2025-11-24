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

            // Then: 모든 테이블이 존재해야 함
            assertThat(rs.next()).isTrue();
            assertThat(rs.getString("tablename")).contains("통화종류");
            
            assertThat(rs.next()).isTrue();
            assertThat(rs.getString("tablename")).contains("유저");
            
            assertThat(rs.next()).isTrue();
            assertThat(rs.getString("tablename")).contains("유저 지갑");
            
            assertThat(rs.next()).isTrue();
            assertThat(rs.getString("tablename")).contains("레퍼럴 정보 테이블");
            
            assertThat(rs.next()).isTrue();
            assertThat(rs.getString("tablename")).contains("레퍼럴 관계 테이블");
            
            assertThat(rs.next()).isTrue();
            assertThat(rs.getString("tablename")).contains("트랜잭션 기록");
            
            assertThat(rs.next()).isTrue();
            assertThat(rs.getString("tablename")).contains("트랜잭션 상태 기록");
        }
    }

    @Test
    @DisplayName("ENUM 타입이 생성되어야 함")
    void testEnumTypesCreated() throws Exception {
        // Given: 마이그레이션 실행
        flyway.migrate();

        // When: ENUM 타입 목록 조회
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT typname FROM pg_type WHERE typtype = 'e' ORDER BY typname")) {

            // Then: ENUM 타입들이 존재해야 함
            var enumTypes = new java.util.ArrayList<String>();
            while (rs.next()) {
                enumTypes.add(rs.getString("typname"));
            }

            assertThat(enumTypes).contains(
                    "currency_type_enum",
                    "referral_status_enum",
                    "tx_status_enum",
                    "tx_type_enum"
            );
        }
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

        // When: 통화종류 데이터 삽입
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement()) {

            // 통화종류 삽입
            statement.executeUpdate(
                    "INSERT INTO \"통화종류\" (currency, name, symbol) VALUES ('KRW', '한국 원', '₩')");
            statement.executeUpdate(
                    "INSERT INTO \"통화종류\" (currency, name, symbol) VALUES ('USDT', 'Tether', 'USDT')");

            // 유저 삽입
            statement.executeUpdate(
                    "INSERT INTO \"유저\" (referral_code, lgn_id, lgn_pwd, email) VALUES ('REF001', 'testuser', 'password123', 'test@example.com')");

            // Then: 데이터 조회 확인
            try (ResultSet rs = statement.executeQuery(
                    "SELECT COUNT(*) FROM \"통화종류\"")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getInt(1)).isEqualTo(2);
            }

            try (ResultSet rs = statement.executeQuery(
                    "SELECT COUNT(*) FROM \"유저\" WHERE lgn_id = 'testuser'")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getInt(1)).isEqualTo(1);
            }
        }
    }
}

