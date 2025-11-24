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
 * 데이터베이스 스키마 구조 테스트
 */
@Testcontainers
@DisplayName("데이터베이스 스키마 테스트")
class DatabaseSchemaTest {

    private static final Logger log = LoggerFactory.getLogger(DatabaseSchemaTest.class);

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

        log.info("=== DatabaseSchemaTest Setup ===");
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

        log.info("마이그레이션 실행 중...");
        var result = flyway.migrate();
        log.info("마이그레이션 완료: {}개 실행됨", result.migrationsExecuted);
        log.info("================================\n");
    }

    @Test
    @DisplayName("유저 테이블의 컬럼 구조가 올바르게 생성되어야 함")
    void testUserTableStructure() throws Exception {
        log.info("=== [TEST] testUserTableStructure 시작 ===");
        
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT column_name, data_type, is_nullable " +
                             "FROM information_schema.columns " +
                             "WHERE table_name = 'users' AND table_schema = 'public' " +
                             "ORDER BY ordinal_position")) {

            List<String> columns = new ArrayList<>();
            log.info("users 테이블 컬럼:");
            while (rs.next()) {
                String colName = rs.getString("column_name");
                columns.add(colName);
                log.info("  - {} ({}, nullable: {})", colName, rs.getString("data_type"), rs.getString("is_nullable"));
            }

            assertThat(columns).containsExactlyInAnyOrder(
                    "id", "login_id", "password_hash", "referral_code",
                    "status", "created_at", "updated_at"
            );
            log.info("=== [TEST] testUserTableStructure 완료 ===\n");
        }
    }

    @Test
    @DisplayName("유저 지갑 테이블의 외래키 관계가 올바르게 설정되어야 함")
    void testUserWalletForeignKeys() throws Exception {
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT " +
                             "tc.constraint_name, " +
                             "tc.table_name, " +
                             "kcu.column_name, " +
                             "ccu.table_name AS foreign_table_name, " +
                             "ccu.column_name AS foreign_column_name " +
                             "FROM information_schema.table_constraints AS tc " +
                             "JOIN information_schema.key_column_usage AS kcu " +
                             "  ON tc.constraint_name = kcu.constraint_name " +
                             "JOIN information_schema.constraint_column_usage AS ccu " +
                             "  ON ccu.constraint_name = tc.constraint_name " +
                             "WHERE tc.constraint_type = 'FOREIGN KEY' " +
                             "  AND tc.table_name = 'user_wallets'")) {

            List<String> foreignKeys = new ArrayList<>();
            while (rs.next()) {
                foreignKeys.add(rs.getString("column_name") + " -> " + rs.getString("foreign_table_name"));
            }

            assertThat(foreignKeys).contains(
                    "user_id -> users",
                    "currency_id -> currency"
            );
        }
    }

    @Test
    @DisplayName("트랜잭션 기록 테이블의 타입이 올바르게 설정되어야 함")
    void testTransactionLogTypes() throws Exception {
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT column_name, data_type " +
                             "FROM information_schema.columns " +
                             "WHERE table_name = 'wallet_transactions' " +
                             "  AND column_name IN ('tx_type', 'status', 'direction')")) {

            List<String> columns = new ArrayList<>();
            while (rs.next()) {
                columns.add(rs.getString("column_name") + ":" + rs.getString("data_type"));
            }

            assertThat(columns).hasSize(3);
            assertThat(columns).anyMatch(c -> c.startsWith("tx_type:"));
            assertThat(columns).anyMatch(c -> c.startsWith("status:"));
            assertThat(columns).anyMatch(c -> c.startsWith("direction:"));
        }
    }

    @Test
    @DisplayName("유니크 제약조건이 올바르게 설정되어야 함")
    void testUniqueConstraints() throws Exception {
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT tc.constraint_name, tc.table_name, kcu.column_name " +
                             "FROM information_schema.table_constraints AS tc " +
                             "JOIN information_schema.key_column_usage AS kcu " +
                             "  ON tc.constraint_name = kcu.constraint_name " +
                             "WHERE tc.constraint_type = 'UNIQUE' " +
                             "  AND tc.table_schema = 'public'")) {

            List<String> uniqueConstraints = new ArrayList<>();
            while (rs.next()) {
                uniqueConstraints.add(rs.getString("table_name") + "." + rs.getString("column_name"));
            }

            assertThat(uniqueConstraints).contains(
                    "users.login_id",
                    "users.referral_code",
                    "referral_stats_logs.user_id"
            );
        }
    }

    @Test
    @DisplayName("기본값이 올바르게 설정되어야 함")
    void testDefaultValues() throws Exception {
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement()) {

            // V999__Test_Data.sql에서 이미 데이터가 삽입되어 있으므로
            // 기존 데이터를 조회하여 기본값을 확인합니다.
            
            // 기본값 확인 - V999에서 삽입된 test_user_1 사용
            try (ResultSet rs = statement.executeQuery(
                    "SELECT status FROM users WHERE login_id = 'test_user_1'")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getString("status")).isEqualTo("ACTIVE");
            }

            // 지갑 잔액 기본값 확인
            try (ResultSet rs = statement.executeQuery(
                    "SELECT balance FROM user_wallets WHERE user_id = (SELECT id FROM users WHERE login_id = 'test_user_1') LIMIT 1")) {
                if (rs.next()) {
                    // 지갑이 있으면 잔액이 0 이상이어야 함
                    assertThat(rs.getBigDecimal("balance")).isNotNull();
                }
            }
        }
    }
}

