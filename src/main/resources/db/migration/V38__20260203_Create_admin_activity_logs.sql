-- 관리자 활동 로그 테이블 (admin-logs API용)
CREATE TABLE IF NOT EXISTS admin_activity_logs (
    id BIGSERIAL NOT NULL,
    admin_id BIGINT NULL,
    grade VARCHAR(20) NULL,
    action VARCHAR(50) NULL,
    target VARCHAR(255) NULL,
    details TEXT NULL,
    ip VARCHAR(45) NULL,
    result VARCHAR(20) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PK_admin_activity_logs PRIMARY KEY (id),
    CONSTRAINT FK_admin_activity_logs_admin FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE SET NULL
);

COMMENT ON TABLE admin_activity_logs IS '관리자 활동 로그 (로그인/접근/실행)';
