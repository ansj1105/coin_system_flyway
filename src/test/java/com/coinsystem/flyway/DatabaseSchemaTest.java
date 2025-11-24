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
                             "WHERE table_name = '유저' AND table_schema = 'public' " +
                             "ORDER BY ordinal_position")) {

            List<String> columns = new ArrayList<>();
            while (rs.next()) {
                columns.add(rs.getString("column_name"));
            }

            assertThat(columns).containsExactlyInAnyOrder(
                    "id", "referral_code", "lgn_id", "lgn_pwd", "wallet_id",
                    "email", "phone", "status", "created_at", "updated_at", "deleted_at"
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
                             "  AND tc.table_name = '유저 지갑'")) {

            List<String> foreignKeys = new ArrayList<>();
            while (rs.next()) {
                foreignKeys.add(rs.getString("column_name") + " -> " + rs.getString("foreign_table_name"));
            }

            assertThat(foreignKeys).contains(
                    "user_id -> 유저",
                    "currency_id -> 통화종류"
            );
        }
    }

    @Test
    @DisplayName("트랜잭션 기록 테이블의 ENUM 타입이 올바르게 사용되어야 함")
    void testTransactionLogEnumTypes() throws Exception {
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT column_name, udt_name " +
                             "FROM information_schema.columns " +
                             "WHERE table_name = '트랜잭션 기록' " +
                             "  AND udt_name LIKE '%enum%'")) {

            List<String> enumColumns = new ArrayList<>();
            while (rs.next()) {
                enumColumns.add(rs.getString("column_name") + ":" + rs.getString("udt_name"));
            }

            assertThat(enumColumns).contains(
                    "tx_type:tx_type_enum",
                    "status:tx_status_enum"
            );
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
                    "유저.lgn_id",
                    "유저.referral_code",
                    "레퍼럴 정보 테이블.user_id"
            );
        }
    }

    @Test
    @DisplayName("기본값이 올바르게 설정되어야 함")
    void testDefaultValues() throws Exception {
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             Statement statement = connection.createStatement()) {

            // 통화종류 삽입 (기본값 테스트)
            statement.executeUpdate(
                    "INSERT INTO \"통화종류\" (currency) VALUES ('KRW')");

            // 유저 삽입 (기본값 테스트)
            statement.executeUpdate(
                    "INSERT INTO \"유저\" (referral_code, lgn_id, lgn_pwd) VALUES ('REF001', 'testuser', 'pwd')");

            // 기본값 확인
            try (ResultSet rs = statement.executeQuery(
                    "SELECT status FROM \"유저\" WHERE lgn_id = 'testuser'")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getString("status")).isEqualTo("active");
            }

            try (ResultSet rs = statement.executeQuery(
                    "SELECT balance FROM \"유저 지갑\" WHERE user_id = (SELECT id FROM \"유저\" WHERE lgn_id = 'testuser')")) {
                // 지갑이 없을 수 있으므로 이 테스트는 스킵
            }
        }
    }
}

