-- ==============================================================================
-- FLASHCARD LEARNING SYSTEM - POSTGRESQL DATABASE SCHEMA
-- Phục vụ: Đồ án hệ thống học tập Spaced Repetition (FSRS) & Machine Learning (DKT)
-- Tham khảo nghiệp vụ: Quizlet Core Domain + FSRS v5 + Deep Knowledge Tracing
-- ==============================================================================

-- Bật extension tạo UUID nếu cần thiết
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 1. BẢNG NGƯỜI DÙNG & XÁC THỰC (USERS & AUTHENTICATION)
-- Hỗ trợ cả đăng ký nội bộ (Email/Pass) và Google Sign-In mà KHÔNG CẦN Firebase
-- ==============================================================================
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255), -- NULL nếu đăng nhập bằng Google
    full_name VARCHAR(150) NOT NULL,
    avatar_url TEXT,
    role VARCHAR(30) NOT NULL DEFAULT 'STUDENT' CHECK (role IN ('STUDENT', 'TEACHER', 'ADMIN')),
    auth_provider VARCHAR(30) NOT NULL DEFAULT 'LOCAL' CHECK (auth_provider IN ('LOCAL', 'GOOGLE')),
    provider_id VARCHAR(255), -- Google Sub ID khi dùng Google Sign-In
    streak_count INT NOT NULL DEFAULT 0, -- Số ngày học liên tục
    last_active_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    banned_at TIMESTAMP WITH TIME ZONE,    -- Thời điểm bị Admin khóa
    ban_reason VARCHAR(255),               -- Lý do Admin khóa tài khoản
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_provider ON users(auth_provider, provider_id);

-- ==============================================================================
-- 2. BẢNG KHÁI NIỆM KIẾN THỨC (KNOWLEDGE COMPONENTS - CHO MÔ HÌNH DKT)
-- DKT cần ánh xạ từng thẻ/câu hỏi vào 1 đơn vị kiến thức (Skill / Concept)
-- ==============================================================================
CREATE TABLE knowledge_components (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(100),
    description TEXT,
    parent_id BIGINT REFERENCES knowledge_components(id) ON DELETE SET NULL, -- Hỗ trợ cây kỹ năng (Skill Tree: Môn -> Chủ đề -> Khái niệm)
    is_standard BOOLEAN NOT NULL DEFAULT TRUE, -- Do Admin chuẩn hóa (TRUE) hay giáo viên tự tạo (FALSE)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_kc_category ON knowledge_components(category);
CREATE INDEX idx_kc_parent ON knowledge_components(parent_id);

-- ==============================================================================
-- 3. BẢNG BỘ THẺ (DECKS / STUDY SETS) VÀ THẺ (CARDS)
-- Tham khảo Quizlet: 1 Deck gồm nhiều Cards (Thuật ngữ - Định nghĩa)
-- ==============================================================================
CREATE TABLE decks (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    card_count INT NOT NULL DEFAULT 0, -- Lưu đệm số thẻ để truy vấn nhanh
    views_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete
);

CREATE INDEX idx_decks_user ON decks(user_id);
CREATE INDEX idx_decks_is_public ON decks(is_public) WHERE deleted_at IS NULL;

CREATE TABLE cards (
    id BIGSERIAL PRIMARY KEY,
    deck_id BIGINT NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    front_text TEXT NOT NULL,         -- Thuật ngữ (Term)
    back_text TEXT NOT NULL,          -- Định nghĩa (Definition)
    front_image_url TEXT,             -- Hỗ trợ ảnh từ OCR hoặc upload
    audio_url TEXT,                   -- Hỗ trợ phát âm
    hint TEXT,                        -- Gợi ý khi bí
    order_index INT NOT NULL DEFAULT 0,
    kc_id BIGINT REFERENCES knowledge_components(id) ON DELETE SET NULL, -- Ánh xạ vào DKT
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_cards_deck ON cards(deck_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_cards_kc ON cards(kc_id);

-- Đánh dấu thẻ sao vàng (Starred Cards - như Quizlet để học riêng thẻ khó)
CREATE TABLE user_card_stars (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_id BIGINT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, card_id)
);

-- ==============================================================================
-- 4. BẢNG THUẬT TOÁN FSRS (SPACED REPETITION SCHEDULER)
-- Lưu trữ trạng thái trí nhớ của từng người dùng trên từng thẻ
-- ==============================================================================
CREATE TABLE fsrs_card_states (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_id BIGINT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    stability DOUBLE PRECISION NOT NULL DEFAULT 0.0,    -- Độ bền trí nhớ (S)
    difficulty DOUBLE PRECISION NOT NULL DEFAULT 0.0,   -- Độ khó (D) từ 1..10
    elapsed_days INT NOT NULL DEFAULT 0,                -- Số ngày trôi qua từ lần ôn trước
    scheduled_days INT NOT NULL DEFAULT 0,              -- Khoảng thời gian hẹn giờ (Interval)
    reps INT NOT NULL DEFAULT 0,                        -- Tổng số lần đã ôn thẻ này
    lapses INT NOT NULL DEFAULT 0,                      -- Số lần bị quên (ấn Again)
    state VARCHAR(20) NOT NULL DEFAULT 'NEW' CHECK (state IN ('NEW', 'LEARNING', 'REVIEW', 'RELEARNING')),
    last_review TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,         -- Ngày đến hạn ôn tiếp theo
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_card_fsrs UNIQUE(user_id, card_id)
);

CREATE INDEX idx_fsrs_user_due ON fsrs_card_states(user_id, due_date);

-- Lịch sử ôn thẻ FSRS (Review Log): Dùng để fine-tune trọng số FSRS cá nhân hóa
CREATE TABLE fsrs_review_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_id BIGINT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    rating SMALLINT NOT NULL CHECK (rating IN (1, 2, 3, 4)), -- 1: Again, 2: Hard, 3: Good, 4: Easy
    scheduled_days INT NOT NULL,
    elapsed_days INT NOT NULL,
    review_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    duration_ms INT -- Thời gian suy nghĩ trước khi trả lời
);

CREATE INDEX idx_fsrs_logs_user ON fsrs_review_logs(user_id, review_time);

-- ==============================================================================
-- 5. BẢNG BÀI KIỂM TRA TRẮC NGHIỆM 1 IN 4 & DEEP KNOWLEDGE TRACING (DKT)
-- ==============================================================================
CREATE TABLE quiz_tests (
    id BIGSERIAL PRIMARY KEY,
    deck_id BIGINT NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    time_limit_minutes INT DEFAULT 15,
    pass_score INT DEFAULT 70,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE quiz_questions (
    id BIGSERIAL PRIMARY KEY,
    quiz_test_id BIGINT NOT NULL REFERENCES quiz_tests(id) ON DELETE CASCADE,
    card_id BIGINT REFERENCES cards(id) ON DELETE SET NULL,
    kc_id BIGINT REFERENCES knowledge_components(id) ON DELETE SET NULL,
    question_text TEXT NOT NULL,
    option_a TEXT NOT NULL,
    option_b TEXT NOT NULL,
    option_c TEXT NOT NULL,
    option_d TEXT NOT NULL,
    correct_option CHAR(1) NOT NULL CHECK (correct_option IN ('A', 'B', 'C', 'D')),
    explanation TEXT
);

CREATE INDEX idx_quiz_questions_test ON quiz_questions(quiz_test_id);

CREATE TABLE quiz_attempts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quiz_test_id BIGINT NOT NULL REFERENCES quiz_tests(id) ON DELETE CASCADE,
    score INT NOT NULL,
    total_questions INT NOT NULL,
    duration_seconds INT NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_quiz_attempts_user ON quiz_attempts(user_id);

-- Bảng log câu trả lời phục vụ trực tiếp cho mô hình DKT (Deep Knowledge Tracing)
-- Vector chuỗi đầu vào của DKT: (kc_id, is_correct) theo trình tự thời gian
CREATE TABLE dkt_question_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    attempt_id BIGINT NOT NULL REFERENCES quiz_attempts(id) ON DELETE CASCADE,
    question_id BIGINT NOT NULL REFERENCES quiz_questions(id) ON DELETE CASCADE,
    kc_id BIGINT NOT NULL REFERENCES knowledge_components(id) ON DELETE CASCADE,
    is_correct SMALLINT NOT NULL CHECK (is_correct IN (0, 1)), -- 0: Sai, 1: Đúng
    response_time_ms INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dkt_logs_user_kc ON dkt_question_logs(user_id, kc_id, created_at);

-- Bảng lưu trữ trạng thái năng lực (Knowledge State) dự đoán bởi DKT
CREATE TABLE dkt_student_mastery (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kc_id BIGINT NOT NULL REFERENCES knowledge_components(id) ON DELETE CASCADE,
    mastery_probability DOUBLE PRECISION NOT NULL DEFAULT 0.0 CHECK (mastery_probability >= 0.0 AND mastery_probability <= 1.0),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_kc_mastery UNIQUE(user_id, kc_id)
);

-- ==============================================================================
-- 6. BẢNG LỚP HỌC & NHÓM HỌC TẬP (CLASSES & ASSIGNMENTS)
-- Tương tự Quizlet Class: Giáo viên tạo lớp, chia sẻ bộ thẻ, giao bài tập
-- ==============================================================================
CREATE TABLE classes (
    id BIGSERIAL PRIMARY KEY,
    teacher_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    class_code VARCHAR(10) NOT NULL UNIQUE, -- Mã PIN tham gia lớp
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_classes_code ON classes(class_code);
CREATE INDEX idx_classes_teacher ON classes(teacher_id);

CREATE TABLE class_members (
    id BIGSERIAL PRIMARY KEY,
    class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'STUDENT' CHECK (role IN ('STUDENT', 'CO_TEACHER')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_class_member UNIQUE(class_id, user_id)
);

-- Các bộ thẻ được đưa vào lớp học
CREATE TABLE class_decks (
    class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    deck_id BIGINT NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (class_id, deck_id)
);

-- Bài tập được giao trong lớp
CREATE TABLE assignments (
    id BIGSERIAL PRIMARY KEY,
    class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    deck_id BIGINT NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    min_score INT DEFAULT 80, -- Điểm trắc nghiệm yêu cầu đạt
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE assignment_submissions (
    id BIGSERIAL PRIMARY KEY,
    assignment_id BIGINT NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'LATE')),
    score INT,
    submitted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_assignment_student UNIQUE(assignment_id, student_id)
);

-- ==============================================================================
-- 7. BẢNG MINI-GAME ÔN TẬP (MATCH GAME & LEADERBOARD)
-- Tương tự Match game của Quizlet: Ghi nhận thời gian và xếp hạng
-- ==============================================================================
CREATE TABLE game_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    deck_id BIGINT NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    game_type VARCHAR(30) NOT NULL DEFAULT 'MATCH' CHECK (game_type IN ('MATCH', 'FALLING_WORDS')),
    score INT NOT NULL DEFAULT 0,
    time_seconds DOUBLE PRECISION NOT NULL, -- Thời gian hoàn thành tính bằng giây (càng ít càng tốt)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_game_deck_leaderboard ON game_sessions(deck_id, game_type, time_seconds ASC);

-- ==============================================================================
-- 8. BẢNG AI CHATBOT LỊCH SỬ HỘI THOẠI
-- ==============================================================================
CREATE TABLE ai_conversations (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    deck_id BIGINT REFERENCES decks(id) ON DELETE SET NULL,
    card_id BIGINT REFERENCES cards(id) ON DELETE SET NULL,
    title VARCHAR(200) DEFAULT 'Hỏi đáp bài học',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ai_messages (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    sender VARCHAR(20) NOT NULL CHECK (sender IN ('USER', 'ASSISTANT')),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_messages_conv ON ai_messages(conversation_id, created_at ASC);

-- ==============================================================================
-- 9. CÁC BẢNG DÀNH RIÊNG CHO ACTOR QUẢN TRỊ VIÊN (ADMINISTRATOR)
-- Quản trị nội dung, kiểm duyệt vi phạm, cấu hình hệ thống và ghi log thao tác
-- ==============================================================================

-- Bảng báo cáo nội dung vi phạm (Người dùng report -> Admin duyệt)
CREATE TABLE content_reports (
    id BIGSERIAL PRIMARY KEY,
    reporter_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- Người gửi báo cáo
    target_type VARCHAR(30) NOT NULL CHECK (target_type IN ('DECK', 'USER', 'COMMENT')),
    target_id BIGINT NOT NULL, -- ID của bộ thẻ hoặc ID của user bị report
    reason VARCHAR(100) NOT NULL, -- Lý do: SPAM, INAPPROPRIATE, WRONG_KNOWLEDGE, COPYRIGHT
    description TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'RESOLVED', 'REJECTED')),
    resolved_by BIGINT REFERENCES users(id) ON DELETE SET NULL, -- Admin xử lý
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_reports_status ON content_reports(status);
CREATE INDEX idx_reports_target ON content_reports(target_type, target_id);

-- Bảng cấu hình hệ thống (Admin quản lý tham số động)
CREATE TABLE system_settings (
    id BIGSERIAL PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE, -- Ví dụ: 'FSRS_DEFAULT_RETENTION', 'AI_MODEL_NAME'
    setting_value TEXT NOT NULL,
    description TEXT,
    updated_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Bảng nhật ký thao tác quản trị (Admin Audit Logs - phục vụ kiểm toán và minh bạch)
CREATE TABLE admin_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    admin_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL, -- Ví dụ: 'BAN_USER', 'UNBAN_USER', 'DELETE_DECK', 'UPDATE_SETTING'
    target_entity VARCHAR(50) NOT NULL, -- Ví dụ: 'USER', 'DECK', 'SETTING'
    target_id BIGINT,
    details TEXT, -- Lưu chi tiết dạng JSON hoặc chuỗi mô tả
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_admin ON admin_audit_logs(admin_id, created_at DESC);

-- Bảng thống kê hệ thống hàng ngày (Daily System Analytics)
-- Phục vụ vẽ biểu đồ Dashboard cho Admin mà không cần chạy query SUM/COUNT nặng nề
CREATE TABLE daily_system_analytics (
    id BIGSERIAL PRIMARY KEY,
    stat_date DATE NOT NULL UNIQUE,
    active_users_count INT NOT NULL DEFAULT 0,
    new_users_count INT NOT NULL DEFAULT 0,
    total_reviews_count INT NOT NULL DEFAULT 0,
    total_quiz_attempts INT NOT NULL DEFAULT 0,
    ocr_scans_count INT NOT NULL DEFAULT 0,
    ai_requests_count INT NOT NULL DEFAULT 0,
    avg_fsrs_retention DOUBLE PRECISION NOT NULL DEFAULT 0.0, -- Tỉ lệ nhớ bài trung bình toàn trường
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_analytics_date ON daily_system_analytics(stat_date DESC);

-- Bảng quản lý hạn mức AI (AI Quota) theo người dùng do Admin cấu hình
CREATE TABLE user_ai_quotas (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    daily_request_limit INT NOT NULL DEFAULT 30, -- Giới hạn số câu hỏi AI mỗi ngày
    requests_used_today INT NOT NULL DEFAULT 0,
    last_reset_date DATE NOT NULL DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Bảng thông báo toàn hệ thống do Admin phát hành (System Announcements)
CREATE TABLE system_announcements (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(30) NOT NULL DEFAULT 'INFO' CHECK (type IN ('INFO', 'WARNING', 'MAINTENANCE', 'EVENT')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE -- Hết hạn hiển thị
);

CREATE INDEX idx_announcements_active ON system_announcements(is_active, created_at DESC);


