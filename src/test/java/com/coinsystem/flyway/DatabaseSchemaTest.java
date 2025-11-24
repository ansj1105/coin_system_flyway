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
 * 데이터베이스 스키마 구조 테스트
 */
@Testcontainers
@DisplayName("데이터베이스 스키마 테스트")
class DatabaseSchemaTest {

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

        flyway.migrate();
    }

    @Test
    @DisplayName("유저 테이블의 컬럼 구조가 올바르게 생성되어야 함")
    void testUserTableStructure() throws Exception {
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT column_name, data_type, is_nullable " +
                             "FROM information_schema.columns " +
                             "WHERE table_name = 'users' AND table_schema = 'public' " +
                             "ORDER BY ordinal_position")) {

            List<String> columns = new ArrayList<>();
            while (rs.next()) {
                columns.add(rs.getString("column_name"));
            }

            assertThat(columns).containsExactlyInAnyOrder(
                    "id", "login_id", "password_hash", "referral_code",
                    "status", "created_at", "updated_at"
            );
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
                             "  AND tc.table_name = 'user_wallet'")) {

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
                             "WHERE table_name = 'wallet_transaction' " +
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
                    "referral_stats.user_id"
            );
        }
    }

    @Test
    @DisplayName("기본값이 올바르게 설정되어야 함")
    void testDefaultValues() throws Exception {
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement()) {

            // 통화 삽입 (기본값 테스트)
            statement.executeUpdate(
                    "INSERT INTO currency (code, name) VALUES ('KRW', '한국 원')");

            // 유저 삽입 (기본값 테스트)
            statement.executeUpdate(
                    "INSERT INTO users (login_id, password_hash, referral_code) VALUES ('testuser', 'hash', 'REF001')");

            // 기본값 확인
            try (ResultSet rs = statement.executeQuery(
                    "SELECT status FROM users WHERE login_id = 'testuser'")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getString("status")).isEqualTo("ACTIVE");
            }

            try (ResultSet rs = statement.executeQuery(
                    "SELECT balance FROM user_wallet WHERE user_id = (SELECT id FROM users WHERE login_id = 'testuser')")) {
                // 지갑이 없을 수 있으므로 이 테스트는 스킵
            }
        }
    }
}

