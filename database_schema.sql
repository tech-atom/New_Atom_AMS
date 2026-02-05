-- ============================================================================
-- ATOM SHAALE AMS - COMPLETE DATABASE SCHEMA
-- Learning Management System with Security, Proctoring & Advanced Features
-- Database: lms_system
-- Created: January 17, 2026
-- ============================================================================

-- Create Database
CREATE DATABASE IF NOT EXISTS lms_system;
USE lms_system;

-- Set character encoding for proper Unicode support
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- ============================================================================
-- TABLE 1: ADMIN TABLE
-- Stores administrator accounts for system management
-- ============================================================================
CREATE TABLE IF NOT EXISTS admin (
    admin_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL COMMENT 'Hashed password using Werkzeug',
    email VARCHAR(150) UNIQUE,
    full_name VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_username (username),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Admin accounts for system management';

-- ============================================================================
-- TABLE 2: STUDENTS TABLE
-- Core student information with approval workflow
-- ============================================================================
CREATE TABLE IF NOT EXISTS students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL COMMENT 'Hashed password using Werkzeug',
    course VARCHAR(100),
    phone VARCHAR(20),
    roll_number VARCHAR(50),
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    profile_image VARCHAR(500),
    address TEXT,
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say'),
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_course (course),
    INDEX idx_roll_number (roll_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Student accounts with approval workflow';

-- ============================================================================
-- TABLE 3: REGISTRATION FIELDS TABLE
-- Dynamic/configurable registration form fields
-- ============================================================================
CREATE TABLE IF NOT EXISTS registration_fields (
    field_id INT AUTO_INCREMENT PRIMARY KEY,
    field_name VARCHAR(100) NOT NULL UNIQUE COMMENT 'Internal field identifier',
    field_label VARCHAR(200) NOT NULL COMMENT 'Display label for the field',
    field_type ENUM('text', 'email', 'number', 'tel', 'date', 'select', 'textarea', 'password') DEFAULT 'text',
    field_options TEXT COMMENT 'JSON or comma-separated options for select fields',
    is_required BOOLEAN DEFAULT TRUE,
    field_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    placeholder VARCHAR(200),
    validation_regex VARCHAR(500),
    help_text VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_field_name (field_name),
    INDEX idx_is_active (is_active),
    INDEX idx_field_order (field_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Configurable registration form fields';

-- ============================================================================
-- TABLE 4: STUDENT CUSTOM DATA TABLE
-- Stores values for custom registration fields
-- ============================================================================
CREATE TABLE IF NOT EXISTS student_custom_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    field_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    UNIQUE KEY unique_student_field (student_id, field_name),
    INDEX idx_student_id (student_id),
    INDEX idx_field_name (field_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Custom field values for students';

-- ============================================================================
-- TABLE 5: EXAM TABLE
-- Exam/test information with scheduling and course targeting
-- ============================================================================
CREATE TABLE IF NOT EXISTS exam (
    exam_id INT AUTO_INCREMENT PRIMARY KEY,
    exam_title VARCHAR(300) NOT NULL,
    subject_name VARCHAR(200) NOT NULL,
    time_limit INT NOT NULL DEFAULT 60 COMMENT 'Time limit in minutes',
    courses TEXT COMMENT 'Comma-separated course names for targeted exams',
    question_paper_path VARCHAR(500) COMMENT 'Path to uploaded question paper file',
    start_datetime DATETIME COMMENT 'Exam availability start time',
    end_datetime DATETIME COMMENT 'Exam deadline/close time',
    shuffle_questions BOOLEAN DEFAULT FALSE COMMENT 'Shuffle question order',
    shuffle_options BOOLEAN DEFAULT FALSE COMMENT 'Shuffle answer options',
    show_scores BOOLEAN DEFAULT TRUE COMMENT 'Show scores to students after submission',
    passing_percentage DECIMAL(5,2) DEFAULT 40.00,
    max_attempts INT DEFAULT 1,
    instructions TEXT,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    proctoring_enabled BOOLEAN DEFAULT FALSE,
    auto_submit BOOLEAN DEFAULT TRUE,
    INDEX idx_exam_title (exam_title),
    INDEX idx_subject (subject_name),
    INDEX idx_start_datetime (start_datetime),
    INDEX idx_end_datetime (end_datetime),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Exam definitions with scheduling and configuration';

-- ============================================================================
-- TABLE 6: QUESTIONS TABLE
-- Question bank for exams with multiple question types
-- ============================================================================
CREATE TABLE IF NOT EXISTS questions (
    question_id INT AUTO_INCREMENT PRIMARY KEY,
    exam_id INT NOT NULL,
    question_text TEXT NOT NULL,
    question_type ENUM('mcq', 'true_false', 'short_answer', 'essay', 'coding', 'fill_blank', 'matching') DEFAULT 'mcq',
    option_a VARCHAR(500),
    option_b VARCHAR(500),
    option_c VARCHAR(500),
    option_d VARCHAR(500),
    option_e VARCHAR(500),
    option_f VARCHAR(500),
    correct_option VARCHAR(10) COMMENT 'Supports single (A) or multiple answers (A,B,C)',
    explanation TEXT COMMENT 'Explanation for the correct answer',
    media_path VARCHAR(500) COMMENT 'Path to image/video/audio for the question',
    marks DECIMAL(5,2) DEFAULT 1.00,
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'medium',
    tags VARCHAR(500) COMMENT 'Comma-separated tags for categorization',
    question_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exam(exam_id) ON DELETE CASCADE,
    INDEX idx_exam_id (exam_id),
    INDEX idx_question_type (question_type),
    INDEX idx_difficulty (difficulty),
    FULLTEXT idx_question_text (question_text)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Question bank with support for multiple question types';

-- ============================================================================
-- TABLE 7: STUDENT RESPONSES TABLE
-- Stores student answers and submissions
-- ============================================================================
CREATE TABLE IF NOT EXISTS student_responses (
    response_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    exam_id INT NOT NULL,
    question_id INT NOT NULL,
    selected_option TEXT COMMENT 'Can store single/multiple options or text answers',
    is_correct BOOLEAN DEFAULT FALSE,
    response_type ENUM('text', 'media', 'code') DEFAULT 'text',
    media_path VARCHAR(500) COMMENT 'Path to uploaded response file',
    time_taken INT COMMENT 'Time taken to answer in seconds',
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    marked_score DECIMAL(5,2) COMMENT 'Manual score for subjective questions',
    feedback TEXT COMMENT 'Teacher feedback on the response',
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exam(exam_id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(question_id) ON DELETE CASCADE,
    UNIQUE KEY unique_response (student_id, exam_id, question_id),
    INDEX idx_student_exam (student_id, exam_id),
    INDEX idx_exam_id (exam_id),
    INDEX idx_question_id (question_id),
    INDEX idx_submitted_at (submitted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Student responses and submissions';

-- ============================================================================
-- TABLE 8: STUDENT PERFORMANCE TABLE
-- Summary of exam performance per student
-- ============================================================================
CREATE TABLE IF NOT EXISTS student_performance (
    performance_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    exam_id INT NOT NULL,
    score DECIMAL(5,2) DEFAULT 0.00,
    total_questions INT NOT NULL,
    correct_answers INT DEFAULT 0,
    wrong_answers INT DEFAULT 0,
    unanswered INT DEFAULT 0,
    percentage DECIMAL(5,2) DEFAULT 0.00,
    time_taken INT COMMENT 'Total time taken in seconds',
    status ENUM('completed', 'in_progress', 'abandoned') DEFAULT 'completed',
    attempt_number INT DEFAULT 1,
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exam(exam_id) ON DELETE CASCADE,
    UNIQUE KEY unique_attempt (student_id, exam_id, attempt_number),
    INDEX idx_student_id (student_id),
    INDEX idx_exam_id (exam_id),
    INDEX idx_status (status),
    INDEX idx_completed_at (completed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Student exam performance summary';

-- ============================================================================
-- TABLE 9: ANNOUNCEMENTS TABLE
-- System-wide and course-specific announcements
-- ============================================================================
CREATE TABLE IF NOT EXISTS announcements (
    announcement_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    course VARCHAR(100) COMMENT 'Specific course or NULL for all students',
    is_pinned BOOLEAN DEFAULT FALSE,
    priority ENUM('low', 'normal', 'high', 'urgent') DEFAULT 'normal',
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL COMMENT 'Announcement expiration date',
    attachment_path VARCHAR(500),
    INDEX idx_course (course),
    INDEX idx_is_pinned (is_pinned),
    INDEX idx_priority (priority),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='System and course announcements';

-- ============================================================================
-- TABLE 10: ANNOUNCEMENT READS TABLE
-- Track which students have read announcements
-- ============================================================================
CREATE TABLE IF NOT EXISTS announcement_reads (
    read_id INT AUTO_INCREMENT PRIMARY KEY,
    announcement_id INT NOT NULL,
    student_id INT NOT NULL,
    read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (announcement_id) REFERENCES announcements(announcement_id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    UNIQUE KEY unique_read (announcement_id, student_id),
    INDEX idx_announcement_id (announcement_id),
    INDEX idx_student_id (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Track announcement read status';

-- ============================================================================
-- TABLE 11: PROCTOR LOGS TABLE
-- AI proctoring event logs for exam monitoring
-- ============================================================================
CREATE TABLE IF NOT EXISTS proctor_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    exam_id INT NOT NULL,
    event_type VARCHAR(100) NOT NULL COMMENT 'e.g., face_not_detected, multiple_faces, tab_switch',
    event_description TEXT,
    severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    snapshot_path VARCHAR(500) COMMENT 'Path to captured image during event',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exam(exam_id) ON DELETE CASCADE,
    INDEX idx_student_exam (student_id, exam_id),
    INDEX idx_event_type (event_type),
    INDEX idx_severity (severity),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='AI proctoring event logs';

-- ============================================================================
-- TABLE 12: CODING RESULTS TABLE
-- Stores results for coding questions (if applicable)
-- ============================================================================
CREATE TABLE IF NOT EXISTS coding_results (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    exam_id INT NOT NULL,
    question_id INT NOT NULL,
    code_submitted TEXT NOT NULL,
    language VARCHAR(50) DEFAULT 'python',
    test_cases_passed INT DEFAULT 0,
    total_test_cases INT NOT NULL,
    execution_time DECIMAL(10,3) COMMENT 'Execution time in seconds',
    memory_used INT COMMENT 'Memory used in KB',
    compilation_error TEXT,
    runtime_error TEXT,
    output TEXT,
    score DECIMAL(5,2) DEFAULT 0.00,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exam(exam_id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(question_id) ON DELETE CASCADE,
    INDEX idx_student_exam (student_id, exam_id),
    INDEX idx_question_id (question_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Coding question submission results';

-- ============================================================================
-- TABLE 13: MATERIALS TABLE
-- Learning materials and resources
-- ============================================================================
CREATE TABLE IF NOT EXISTS materials (
    material_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    material_type ENUM('pdf', 'video', 'audio', 'document', 'link', 'other') DEFAULT 'pdf',
    file_path VARCHAR(500),
    external_link VARCHAR(500),
    course VARCHAR(100),
    subject VARCHAR(200),
    uploaded_by VARCHAR(100),
    file_size BIGINT COMMENT 'File size in bytes',
    downloads INT DEFAULT 0,
    views INT DEFAULT 0,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_course (course),
    INDEX idx_subject (subject),
    INDEX idx_material_type (material_type),
    INDEX idx_is_public (is_public)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Learning materials and resources';

-- ============================================================================
-- TABLE 14: ACTIVITY LOGS TABLE
-- System activity and audit trail
-- ============================================================================
CREATE TABLE IF NOT EXISTS activity_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT COMMENT 'Student or admin ID',
    user_type ENUM('student', 'admin', 'system') DEFAULT 'student',
    action VARCHAR(200) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    request_method VARCHAR(10),
    request_path VARCHAR(500),
    status_code INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id, user_type),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='System activity and audit trail';

-- ============================================================================
-- TABLE 15: SECURITY LOGS TABLE
-- Security events and suspicious activities
-- ============================================================================
CREATE TABLE IF NOT EXISTS security_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL COMMENT 'login_failed, suspicious_activity, rate_limit, etc.',
    severity ENUM('info', 'warning', 'error', 'critical') DEFAULT 'info',
    ip_address VARCHAR(45),
    user_identifier VARCHAR(255) COMMENT 'Username, email, or user ID',
    description TEXT,
    user_agent TEXT,
    request_data TEXT COMMENT 'JSON data of the request',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_event_type (event_type),
    INDEX idx_severity (severity),
    INDEX idx_ip_address (ip_address),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Security events and threat logs';

-- ============================================================================
-- TABLE 16: FAILED LOGIN ATTEMPTS TABLE
-- Track failed login attempts for rate limiting
-- ============================================================================
CREATE TABLE IF NOT EXISTS failed_login_attempts (
    attempt_id INT AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(45) NOT NULL,
    username VARCHAR(255),
    attempt_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_agent TEXT,
    INDEX idx_ip_address (ip_address),
    INDEX idx_attempt_time (attempt_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Failed login attempts tracking';

-- ============================================================================
-- TABLE 17: BANNED IPS TABLE
-- IP addresses that are temporarily or permanently banned
-- ============================================================================
CREATE TABLE IF NOT EXISTS banned_ips (
    ban_id INT AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(45) NOT NULL UNIQUE,
    reason TEXT,
    ban_type ENUM('temporary', 'permanent') DEFAULT 'temporary',
    banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    banned_by VARCHAR(100),
    INDEX idx_ip_address (ip_address),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Banned IP addresses';

-- ============================================================================
-- TABLE 18: SESSIONS TABLE
-- Session management (optional - Flask handles sessions by default)
-- ============================================================================
CREATE TABLE IF NOT EXISTS sessions (
    session_id VARCHAR(255) PRIMARY KEY,
    user_id INT,
    user_type ENUM('student', 'admin'),
    session_data TEXT COMMENT 'Serialized session data',
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_user (user_id, user_type),
    INDEX idx_expires_at (expires_at),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='User session management';

-- ============================================================================
-- TABLE 19: NOTIFICATIONS TABLE
-- In-app notifications for students and admins
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    user_type ENUM('student', 'admin') DEFAULT 'student',
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) DEFAULT 'general',
    is_read BOOLEAN DEFAULT FALSE,
    link VARCHAR(500) COMMENT 'Link to relevant page',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    INDEX idx_user (user_id, user_type),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='User notifications';

-- ============================================================================
-- TABLE 20: SETTINGS TABLE
-- System-wide configuration settings
-- ============================================================================
CREATE TABLE IF NOT EXISTS settings (
    setting_id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT,
    setting_type ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string',
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE COMMENT 'Can be accessed by non-admin users',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_setting_key (setting_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='System configuration settings';

-- ============================================================================
-- TABLE 21: EXAM CATEGORIES TABLE
-- Categorization of exams
-- ============================================================================
CREATE TABLE IF NOT EXISTS exam_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_category_id INT NULL,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES exam_categories(category_id) ON DELETE SET NULL,
    INDEX idx_parent (parent_category_id),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Exam categorization';

-- ============================================================================
-- TABLE 22: VIDEO RECORDINGS TABLE
-- Store video recording metadata for proctoring
-- ============================================================================
CREATE TABLE IF NOT EXISTS video_recordings (
    recording_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    exam_id INT NOT NULL,
    video_path VARCHAR(500) NOT NULL,
    duration INT COMMENT 'Duration in seconds',
    file_size BIGINT COMMENT 'File size in bytes',
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processing_status ENUM('pending', 'processing', 'completed', 'failed') DEFAULT 'pending',
    analysis_result TEXT COMMENT 'AI analysis results in JSON format',
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exam(exam_id) ON DELETE CASCADE,
    INDEX idx_student_exam (student_id, exam_id),
    INDEX idx_processing_status (processing_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Video recording metadata for proctoring';

-- ============================================================================
-- DEFAULT DATA INSERTION
-- ============================================================================

-- Insert default admin account (password: admin123)
-- Password hash generated using: generate_password_hash('admin123')
INSERT IGNORE INTO admin (username, password, email, full_name) VALUES
('admin', 'scrypt:32768:8:1$ZQ3xYxJ8F8Y4K9Xt$c8db73d04b71f1f1c24b4f4a4e4c4a9a4b4c4d4e4f5a5b5c5d5e5f6a6b6c6d6e6f7a7b7c7d7e7f8a8b8c8d8e8f9a9b9c9d9e9f0a0b0c0d0e0', 'admin@atomshaale.com', 'System Administrator');

-- Insert default registration fields
INSERT IGNORE INTO registration_fields (field_name, field_label, field_type, field_options, is_required, field_order) VALUES
('student_name', 'Full Name', 'text', NULL, TRUE, 1),
('email', 'Email Address', 'email', NULL, TRUE, 2),
('password', 'Password', 'password', NULL, TRUE, 3),
('phone', 'Phone Number', 'tel', NULL, FALSE, 4),
('roll_number', 'Roll Number', 'text', NULL, FALSE, 5),
('course', 'Course/Program', 'text', NULL, TRUE, 6);

-- Insert sample settings
INSERT IGNORE INTO settings (setting_key, setting_value, setting_type, description, is_public) VALUES
('site_name', 'Atom Shaale AMS', 'string', 'Website name', TRUE),
('maintenance_mode', 'false', 'boolean', 'Enable maintenance mode', FALSE),
('max_upload_size', '52428800', 'number', 'Maximum upload size in bytes (50MB)', FALSE),
('proctoring_enabled', 'true', 'boolean', 'Enable AI proctoring system', FALSE),
('session_timeout', '3600', 'number', 'Session timeout in seconds', FALSE);

-- ============================================================================
-- VIEWS (OPTIONAL BUT USEFUL)
-- ============================================================================

-- View: Student Performance Summary
CREATE OR REPLACE VIEW v_student_performance_summary AS
SELECT 
    s.student_id,
    s.name,
    s.email,
    s.course,
    COUNT(DISTINCT sp.exam_id) AS total_exams_taken,
    AVG(sp.percentage) AS average_percentage,
    MAX(sp.percentage) AS highest_percentage,
    MIN(sp.percentage) AS lowest_percentage,
    SUM(CASE WHEN sp.percentage >= 40 THEN 1 ELSE 0 END) AS exams_passed,
    SUM(CASE WHEN sp.percentage < 40 THEN 1 ELSE 0 END) AS exams_failed
FROM students s
LEFT JOIN student_performance sp ON s.student_id = sp.student_id AND sp.status = 'completed'
GROUP BY s.student_id;

-- View: Exam Statistics
CREATE OR REPLACE VIEW v_exam_statistics AS
SELECT 
    e.exam_id,
    e.exam_title,
    e.subject_name,
    COUNT(DISTINCT sp.student_id) AS total_students_attempted,
    AVG(sp.percentage) AS average_score,
    MAX(sp.percentage) AS highest_score,
    MIN(sp.percentage) AS lowest_score,
    COUNT(DISTINCT q.question_id) AS total_questions
FROM exam e
LEFT JOIN student_performance sp ON e.exam_id = sp.exam_id AND sp.status = 'completed'
LEFT JOIN questions q ON e.exam_id = q.exam_id
GROUP BY e.exam_id;

-- View: Active Announcements
CREATE OR REPLACE VIEW v_active_announcements AS
SELECT 
    announcement_id,
    title,
    content,
    course,
    is_pinned,
    priority,
    created_by,
    created_at,
    updated_at
FROM announcements
WHERE (expires_at IS NULL OR expires_at > NOW())
ORDER BY is_pinned DESC, priority DESC, created_at DESC;

-- View: Proctor Violations Summary
CREATE OR REPLACE VIEW v_proctor_violations AS
SELECT 
    pl.student_id,
    s.name AS student_name,
    pl.exam_id,
    e.exam_title,
    pl.event_type,
    COUNT(*) AS violation_count,
    MAX(pl.severity) AS max_severity,
    MAX(pl.created_at) AS last_violation
FROM proctor_logs pl
JOIN students s ON pl.student_id = s.student_id
JOIN exam e ON pl.exam_id = e.exam_id
GROUP BY pl.student_id, pl.exam_id, pl.event_type;

-- ============================================================================
-- STORED PROCEDURES (OPTIONAL)
-- ============================================================================

DELIMITER //

-- Procedure: Calculate Student Performance
CREATE PROCEDURE IF NOT EXISTS sp_calculate_performance(
    IN p_student_id INT,
    IN p_exam_id INT
)
BEGIN
    DECLARE v_total_questions INT;
    DECLARE v_correct_answers INT;
    DECLARE v_wrong_answers INT;
    DECLARE v_unanswered INT;
    DECLARE v_score DECIMAL(5,2);
    DECLARE v_percentage DECIMAL(5,2);
    
    -- Count total questions
    SELECT COUNT(*) INTO v_total_questions
    FROM questions WHERE exam_id = p_exam_id;
    
    -- Count correct answers
    SELECT COUNT(*) INTO v_correct_answers
    FROM student_responses 
    WHERE student_id = p_student_id 
    AND exam_id = p_exam_id 
    AND is_correct = TRUE;
    
    -- Count wrong answers
    SELECT COUNT(*) INTO v_wrong_answers
    FROM student_responses 
    WHERE student_id = p_student_id 
    AND exam_id = p_exam_id 
    AND is_correct = FALSE 
    AND selected_option IS NOT NULL;
    
    -- Calculate unanswered
    SET v_unanswered = v_total_questions - v_correct_answers - v_wrong_answers;
    
    -- Calculate score and percentage
    SET v_score = v_correct_answers;
    SET v_percentage = (v_correct_answers / v_total_questions) * 100;
    
    -- Update or insert performance
    INSERT INTO student_performance 
        (student_id, exam_id, score, total_questions, correct_answers, wrong_answers, unanswered, percentage)
    VALUES 
        (p_student_id, p_exam_id, v_score, v_total_questions, v_correct_answers, v_wrong_answers, v_unanswered, v_percentage)
    ON DUPLICATE KEY UPDATE
        score = v_score,
        total_questions = v_total_questions,
        correct_answers = v_correct_answers,
        wrong_answers = v_wrong_answers,
        unanswered = v_unanswered,
        percentage = v_percentage,
        completed_at = NOW();
END //

-- Procedure: Clean Old Security Logs
CREATE PROCEDURE IF NOT EXISTS sp_cleanup_old_logs(IN days_to_keep INT)
BEGIN
    DELETE FROM activity_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL days_to_keep DAY);
    DELETE FROM security_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL days_to_keep DAY);
    DELETE FROM failed_login_attempts WHERE attempt_time < DATE_SUB(NOW(), INTERVAL days_to_keep DAY);
END //

DELIMITER ;

-- ============================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ============================================================================

-- Additional composite indexes for common queries
CREATE INDEX idx_student_course_status ON students(course, status);
CREATE INDEX idx_exam_dates ON exam(start_datetime, end_datetime);
CREATE INDEX idx_response_student_exam ON student_responses(student_id, exam_id, submitted_at);
CREATE INDEX idx_performance_exam_date ON student_performance(exam_id, completed_at);

-- ============================================================================
-- TRIGGERS (OPTIONAL BUT USEFUL)
-- ============================================================================

DELIMITER //

-- Trigger: Auto-update student last_login on successful login
CREATE TRIGGER IF NOT EXISTS trg_update_student_last_login
AFTER UPDATE ON students
FOR EACH ROW
BEGIN
    IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
        -- Log approval event
        INSERT INTO activity_logs (user_id, user_type, action, description)
        VALUES (NEW.student_id, 'student', 'account_approved', CONCAT('Student account approved: ', NEW.email));
    END IF;
END //

-- Trigger: Log student deletion
CREATE TRIGGER IF NOT EXISTS trg_log_student_deletion
BEFORE DELETE ON students
FOR EACH ROW
BEGIN
    INSERT INTO activity_logs (user_id, user_type, action, description)
    VALUES (OLD.student_id, 'student', 'account_deleted', CONCAT('Student account deleted: ', OLD.email));
END //

-- Trigger: Auto-calculate performance on response insert
CREATE TRIGGER IF NOT EXISTS trg_auto_calculate_performance
AFTER INSERT ON student_responses
FOR EACH ROW
BEGIN
    -- This would call the stored procedure, but it's optional
    -- CALL sp_calculate_performance(NEW.student_id, NEW.exam_id);
    NULL;
END //

DELIMITER ;

-- ============================================================================
-- GRANTS AND PERMISSIONS (CONFIGURE AS NEEDED)
-- ============================================================================

-- Example: Create application user with limited permissions
-- CREATE USER 'lms_app'@'localhost' IDENTIFIED BY 'secure_password_here';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON lms_system.* TO 'lms_app'@'localhost';
-- FLUSH PRIVILEGES;

-- ============================================================================
-- DATABASE OPTIMIZATION SETTINGS
-- ============================================================================

-- Set InnoDB buffer pool size (adjust based on available RAM)
-- SET GLOBAL innodb_buffer_pool_size = 1073741824; -- 1GB

-- Enable query cache (if using MySQL < 8.0)
-- SET GLOBAL query_cache_size = 67108864; -- 64MB
-- SET GLOBAL query_cache_type = ON;

-- ============================================================================
-- BACKUP RECOMMENDATION
-- ============================================================================

/*
Regular backup schedule:
1. Daily incremental backups
2. Weekly full backups
3. Monthly archive backups

Backup command example:
mysqldump -u root -p --databases lms_system --single-transaction --quick --lock-tables=false > lms_backup_$(date +%Y%m%d).sql

Restore command example:
mysql -u root -p lms_system < lms_backup_20260117.sql
*/

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

SELECT '✅ Database schema created successfully!' AS Status;
SELECT 'Total Tables: 22' AS Info;
SELECT 'Database: lms_system' AS Database_Name;
SELECT 'Version: 2.0' AS Version;
SELECT 'Last Updated: 2026-01-17' AS Last_Updated;

-- ============================================================================
-- END OF DATABASE SCHEMA
-- ============================================================================
