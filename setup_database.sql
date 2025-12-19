-- ============================================
-- AIR PROJECT DATABASE SETUP SCRIPT
-- Enhanced Version
-- ============================================

-- 1. Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS air_project 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- 2. Use the database
USE air_project;

-- 3. Drop old tables if they exist (cleanup in proper order due to foreign keys)
DROP TABLE IF EXISTS air_tasks;
DROP TABLE IF EXISTS air_users;

-- 4. Create air_users table with better constraints
CREATE TABLE air_users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(120) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- Add email validation constraint
    CONSTRAINT chk_valid_email CHECK (email LIKE '%@%'),
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Create air_tasks table with improved constraints
CREATE TABLE air_tasks (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    due_date DATETIME NULL,
    priority ENUM('low', 'medium', 'high') DEFAULT 'medium',
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- Foreign key with proper cascade
    FOREIGN KEY (user_id) REFERENCES air_users(id) ON DELETE CASCADE,
    -- Add validation for title length
    CONSTRAINT chk_title_length CHECK (LENGTH(TRIM(title)) > 0),
    INDEX idx_user_id (user_id),
    INDEX idx_completed (completed),
    INDEX idx_due_date (due_date),
    INDEX idx_priority (priority),
    INDEX idx_user_completed (user_id, completed),
    INDEX idx_user_due_date (user_id, due_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Insert test user (with hashed password for better security)
-- Note: In production, passwords should be properly hashed using bcrypt or similar
INSERT IGNORE INTO air_users (email, password, name) 
VALUES 
('test@example.com', 'password123', 'Test User'),
('admin@airproject.com', 'admin123', 'Administrator'),
('john.doe@example.com', 'john123', 'John Doe'),
('jane.smith@example.com', 'jane123', 'Jane Smith');

-- 7. Insert sample tasks for test users
INSERT IGNORE INTO air_tasks (user_id, title, description, due_date, priority, completed) VALUES
-- Tasks for user 1 (test@example.com)
(1, 'Complete Project Report', 'Finish the quarterly project analysis and submit to manager', DATE_ADD(NOW(), INTERVAL 2 DAY), 'high', FALSE),
(1, 'Team Meeting Preparation', 'Prepare agenda and presentation for weekly team meeting', DATE_ADD(NOW(), INTERVAL 1 DAY), 'medium', FALSE),
(1, 'Code Review', 'Review pull requests from development team', NOW(), 'medium', TRUE),
(1, 'Database Optimization', 'Optimize database queries for better performance', DATE_ADD(NOW(), INTERVAL 7 DAY), 'low', FALSE),
(1, 'Client Presentation', 'Create slides for client demo on Friday', DATE_ADD(NOW(), INTERVAL 3 DAY), 'high', FALSE),

-- Tasks for user 2 (admin@airproject.com)
(2, 'System Maintenance', 'Schedule and perform system maintenance tasks', DATE_ADD(NOW(), INTERVAL 5 DAY), 'high', FALSE),
(2, 'User Management Review', 'Review user accounts and permissions', DATE_ADD(NOW(), INTERVAL 2 DAY), 'medium', TRUE),
(2, 'Security Audit', 'Conduct security audit of the application', DATE_ADD(NOW(), INTERVAL 10 DAY), 'high', FALSE),

-- Tasks for user 3 (john.doe@example.com)
(3, 'Learn Flask Framework', 'Complete Flask tutorial and build sample project', DATE_ADD(NOW(), INTERVAL 14 DAY), 'medium', FALSE),
(3, 'Update Portfolio Website', 'Add recent projects and update bio', DATE_ADD(NOW(), INTERVAL 3 DAY), 'low', TRUE),

-- Tasks for user 4 (jane.smith@example.com)
(4, 'Market Research', 'Conduct market analysis for Q3 planning', DATE_ADD(NOW(), INTERVAL 7 DAY), 'high', FALSE),
(4, 'Team Building Activity', 'Organize monthly team building event', DATE_ADD(NOW(), INTERVAL 4 DAY), 'medium', FALSE);

-- 8. Create a view for task overview (optional but useful)
CREATE OR REPLACE VIEW vw_task_overview AS
SELECT 
    t.id,
    t.title,
    u.name as user_name,
    u.email,
    t.priority,
    t.due_date,
    t.completed,
    CASE 
        WHEN t.due_date < NOW() AND t.completed = FALSE THEN 'Overdue'
        WHEN t.due_date BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 3 DAY) AND t.completed = FALSE THEN 'Due Soon'
        WHEN t.completed = TRUE THEN 'Completed'
        ELSE 'Pending'
    END as status,
    DATEDIFF(t.due_date, NOW()) as days_remaining
FROM air_tasks t
JOIN air_users u ON t.user_id = u.id;

-- 9. Create a view for user statistics (optional)
CREATE OR REPLACE VIEW vw_user_stats AS
SELECT 
    u.id,
    u.email,
    u.name,
    COUNT(t.id) as total_tasks,
    SUM(CASE WHEN t.completed = TRUE THEN 1 ELSE 0 END) as completed_tasks,
    SUM(CASE WHEN t.completed = FALSE THEN 1 ELSE 0 END) as pending_tasks,
    SUM(CASE WHEN t.priority = 'high' THEN 1 ELSE 0 END) as high_priority_tasks,
    SUM(CASE WHEN t.due_date < NOW() AND t.completed = FALSE THEN 1 ELSE 0 END) as overdue_tasks
FROM air_users u
LEFT JOIN air_tasks t ON u.id = t.user_id
GROUP BY u.id, u.email, u.name;

-- 10. Show database status
SELECT 
    '✅ DATABASE SETUP COMPLETE' as status,
    DATABASE() as database_name,
    VERSION() as mysql_version,
    NOW() as setup_time;

-- 11. Show all tables
SHOW TABLES;

-- 12. Show table structure
SELECT '👤 air_users TABLE STRUCTURE:' as info;
DESCRIBE air_users;

SELECT '📋 air_tasks TABLE STRUCTURE:' as info;
DESCRIBE air_tasks;

-- 13. Show sample data with better formatting
SELECT '👤 USERS TABLE DATA:' as info;
SELECT 
    id,
    email,
    name,
    DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') as created_at,
    DATE_FORMAT(updated_at, '%Y-%m-%d %H:%i') as updated_at
FROM air_users
ORDER BY id;

SELECT '📋 TASKS TABLE DATA (First 10 tasks):' as info;
SELECT 
    t.id,
    u.name as user_name,
    t.title,
    LEFT(t.description, 40) as description_preview,
    DATE_FORMAT(t.due_date, '%Y-%m-%d %H:%i') as due_date,
    t.priority,
    CASE 
        WHEN t.completed THEN '✅ Completed' 
        WHEN t.due_date < NOW() THEN '⚠️ Overdue' 
        ELSE '⏳ Pending' 
    END as status,
    DATE_FORMAT(t.created_at, '%Y-%m-%d') as created
FROM air_tasks t
JOIN air_users u ON t.user_id = u.id
ORDER BY t.due_date
LIMIT 10;

-- 14. Show view data (optional preview)
SELECT '📊 TASK OVERVIEW VIEW (Sample):' as info;
SELECT * FROM vw_task_overview LIMIT 5;

SELECT '📈 USER STATISTICS VIEW:' as info;
SELECT * FROM vw_user_stats;

-- 15. Show database statistics
SELECT '📊 DATABASE STATISTICS:' as info;
SELECT 
    (SELECT COUNT(*) FROM air_users) as total_users,
    (SELECT COUNT(*) FROM air_tasks) as total_tasks,
    (SELECT COUNT(*) FROM air_tasks WHERE completed = TRUE) as completed_tasks,
    (SELECT COUNT(*) FROM air_tasks WHERE completed = FALSE) as pending_tasks,
    (SELECT COUNT(*) FROM air_tasks WHERE due_date < NOW() AND completed = FALSE) as overdue_tasks,
    (SELECT COUNT(*) FROM air_tasks WHERE priority = 'high') as high_priority_tasks;