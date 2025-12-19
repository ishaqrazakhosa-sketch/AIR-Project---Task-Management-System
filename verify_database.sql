-- ============================================
-- AIR PROJECT DATABASE VERIFICATION SCRIPT
-- Enhanced Version
-- ============================================

-- 0. Set output formatting
SET @OLD_SQL_MODE = @@SQL_MODE;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';
SET @OLD_TIME_ZONE = @@TIME_ZONE;
SET TIME_ZONE = '+00:00';

-- Start verification
SELECT '🚀 AIR PROJECT DATABASE VERIFICATION STARTED' as verification_header;
SELECT CONCAT('Timestamp: ', NOW()) as start_time;
SELECT '============================================' as separator;

-- 1. DATABASE EXISTENCE & METADATA
SELECT '📊 DATABASE METADATA:' as section_header;
SELECT 
    SCHEMA_NAME as database_name,
    IF(SCHEMA_NAME = 'air_project', '✅ EXISTS', '❌ MISSING') as existence_status,
    DEFAULT_CHARACTER_SET_NAME as character_set,
    DEFAULT_COLLATION_NAME as collation,
    CONCAT(ROUND(SUM(data_length + index_length) / 1024 / 1024, 2), ' MB') as total_size,
    (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'air_project') as table_count
FROM information_schema.SCHEMATA 
WHERE SCHEMA_NAME = 'air_project'
GROUP BY SCHEMA_NAME;

-- 2. TABLE DETAILED ANALYSIS
SELECT '📋 TABLE DETAILS:' as section_header;
SELECT 
    t.TABLE_NAME as table_name,
    t.TABLE_ROWS as estimated_rows,
    CONCAT(ROUND(t.DATA_LENGTH / 1024 / 1024, 2), ' MB') as data_size,
    CONCAT(ROUND(t.INDEX_LENGTH / 1024 / 1024, 2), ' MB') as index_size,
    t.TABLE_COLLATION as collation,
    t.ENGINE as storage_engine,
    DATE_FORMAT(t.CREATE_TIME, '%Y-%m-%d %H:%i:%s') as created,
    DATE_FORMAT(t.UPDATE_TIME, '%Y-%m-%d %H:%i:%s') as last_updated,
    (SELECT COUNT(*) FROM information_schema.COLUMNS c 
     WHERE c.TABLE_SCHEMA = t.TABLE_SCHEMA AND c.TABLE_NAME = t.TABLE_NAME) as column_count
FROM information_schema.TABLES t
WHERE t.TABLE_SCHEMA = 'air_project'
ORDER BY t.DATA_LENGTH DESC;

-- 3. COLUMN SCHEMA VALIDATION
SELECT '🔍 COLUMN STRUCTURE VALIDATION:' as section_header;
WITH ExpectedSchema AS (
    SELECT 'air_users' as table_name, 'id' as column_name, 'int' as expected_type, 'NO' as expected_nullable, 'PRI' as expected_key UNION ALL
    SELECT 'air_users', 'email', 'varchar(120)', 'NO', 'UNI' UNION ALL
    SELECT 'air_users', 'password', 'varchar(255)', 'NO', '' UNION ALL
    SELECT 'air_users', 'name', 'varchar(100)', 'NO', '' UNION ALL
    SELECT 'air_users', 'created_at', 'timestamp', 'NO', '' UNION ALL
    SELECT 'air_users', 'updated_at', 'timestamp', 'NO', '' UNION ALL
    SELECT 'air_tasks', 'id', 'int', 'NO', 'PRI' UNION ALL
    SELECT 'air_tasks', 'user_id', 'int', 'NO', 'MUL' UNION ALL
    SELECT 'air_tasks', 'title', 'varchar(200)', 'NO', '' UNION ALL
    SELECT 'air_tasks', 'description', 'text', 'YES', '' UNION ALL
    SELECT 'air_tasks', 'due_date', 'datetime', 'YES', 'MUL' UNION ALL
    SELECT 'air_tasks', 'priority', 'enum', 'YES', 'MUL' UNION ALL
    SELECT 'air_tasks', 'completed', 'tinyint(1)', 'YES', 'MUL' UNION ALL
    SELECT 'air_tasks', 'created_at', 'timestamp', 'NO', '' UNION ALL
    SELECT 'air_tasks', 'updated_at', 'timestamp', 'NO', ''
)
SELECT 
    c.TABLE_NAME,
    c.COLUMN_NAME,
    c.COLUMN_TYPE,
    c.IS_NULLABLE,
    c.COLUMN_KEY,
    CASE 
        WHEN c.COLUMN_TYPE LIKE e.expected_type || '%' AND 
             c.IS_NULLABLE = e.expected_nullable AND
             (c.COLUMN_KEY = e.expected_key OR (c.COLUMN_KEY = '' AND e.expected_key = ''))
        THEN '✅ VALID'
        ELSE CONCAT('❌ MISMATCH: Expected ', e.expected_type, '/', e.expected_nullable, '/', e.expected_key)
    END as validation_status
FROM information_schema.COLUMNS c
JOIN ExpectedSchema e ON c.TABLE_NAME = e.table_name AND c.COLUMN_NAME = e.column_name
WHERE c.TABLE_SCHEMA = 'air_project'
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- 4. INDEX ANALYSIS
SELECT '📈 INDEX ANALYSIS:' as section_header;
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) as indexed_columns,
    CASE 
        WHEN INDEX_NAME = 'PRIMARY' THEN 'PRIMARY KEY'
        WHEN NON_UNIQUE = 0 THEN 'UNIQUE INDEX'
        ELSE 'NON-UNIQUE INDEX'
    END as index_type,
    CARDINALITY as estimated_uniqueness
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'air_project'
GROUP BY TABLE_NAME, INDEX_NAME, NON_UNIQUE, CARDINALITY
ORDER BY TABLE_NAME, INDEX_NAME = 'PRIMARY' DESC, INDEX_NAME;

-- 5. FOREIGN KEY INTEGRITY CHECK
SELECT '🔗 REFERENTIAL INTEGRITY:' as section_header;
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME,
    '✅ ACTIVE' as constraint_status
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'air_project' 
AND REFERENCED_TABLE_NAME IS NOT NULL
AND CONSTRAINT_NAME IN (
    SELECT CONSTRAINT_NAME 
    FROM information_schema.TABLE_CONSTRAINTS 
    WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' 
    AND TABLE_SCHEMA = 'air_project'
);

-- 6. DATA QUALITY CHECKS
SELECT '🎯 DATA QUALITY ANALYSIS:' as section_header;

-- User data validation
SELECT 
    'air_users' as table_name,
    COUNT(*) as total_users,
    COUNT(DISTINCT email) as unique_emails,
    SUM(CASE WHEN email LIKE '%@%' THEN 1 ELSE 0 END) as valid_emails,
    SUM(CASE WHEN LENGTH(password) >= 8 THEN 1 ELSE 0 END) as secure_passwords,
    SUM(CASE WHEN LENGTH(TRIM(name)) > 0 THEN 1 ELSE 0 END) as valid_names,
    MIN(created_at) as oldest_user,
    MAX(created_at) as newest_user
FROM air_users;

-- Task data validation
SELECT 
    'air_tasks' as table_name,
    COUNT(*) as total_tasks,
    SUM(CASE WHEN LENGTH(TRIM(title)) > 0 THEN 1 ELSE 0 END) as valid_titles,
    SUM(CASE WHEN due_date IS NOT NULL THEN 1 ELSE 0 END) as tasks_with_due_dates,
    SUM(CASE WHEN completed = TRUE THEN 1 ELSE 0 END) as completed_tasks,
    SUM(CASE WHEN priority IN ('low', 'medium', 'high') THEN 1 ELSE 0 END) as valid_priorities,
    AVG(TIMESTAMPDIFF(HOUR, created_at, COALESCE(due_date, NOW()))) as avg_hours_to_complete
FROM air_tasks;

-- 7. ORPHANED RECORDS CHECK
SELECT '🔍 ORPHANED RECORDS CHECK:' as section_header;
SELECT 
    'air_tasks with invalid user_id' as check_type,
    COUNT(*) as orphaned_count,
    GROUP_CONCAT(id ORDER BY id) as orphaned_ids
FROM air_tasks t
LEFT JOIN air_users u ON t.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 
    'Users without any tasks' as check_type,
    COUNT(*) as users_without_tasks,
    GROUP_CONCAT(u.id ORDER BY u.id) as user_ids
FROM air_users u
LEFT JOIN air_tasks t ON u.id = t.user_id
WHERE t.id IS NULL;

-- 8. PERFORMANCE METRICS
SELECT '⚡ PERFORMANCE METRICS:' as section_header;
SELECT 
    'Task Completion Rate' as metric,
    CONCAT(
        ROUND(
            (SELECT COUNT(*) FROM air_tasks WHERE completed = TRUE) * 100.0 / 
            GREATEST((SELECT COUNT(*) FROM air_tasks), 1), 
        1), '%') as value
UNION ALL
SELECT 
    'Avg Tasks per User',
    ROUND(
        (SELECT COUNT(*) FROM air_tasks) * 1.0 / 
        GREATEST((SELECT COUNT(*) FROM air_users), 1), 
    2)
UNION ALL
SELECT 
    'Overdue Task Percentage',
    CONCAT(
        ROUND(
            (SELECT COUNT(*) FROM air_tasks WHERE completed = FALSE AND due_date < NOW()) * 100.0 / 
            GREATEST((SELECT COUNT(*) FROM air_tasks WHERE completed = FALSE), 1), 
        1), '%')
UNION ALL
SELECT 
    'High Priority Pending Tasks',
    (SELECT COUNT(*) FROM air_tasks WHERE priority = 'high' AND completed = FALSE);

-- 9. SAMPLE DATA PREVIEW
SELECT '👁️ SAMPLE DATA PREVIEW:' as section_header;

-- User sample
SELECT '👤 SAMPLE USERS (First 5):' as preview_type;
SELECT 
    id,
    email,
    name,
    LENGTH(password) as password_length,
    DATE_FORMAT(created_at, '%Y-%m-%d') as joined_date,
    DATE_FORMAT(updated_at, '%Y-%m-%d %H:%i') as last_updated
FROM air_users 
ORDER BY id
LIMIT 5;

-- Task sample with user info
SELECT '📋 SAMPLE TASKS WITH DETAILS:' as preview_type;
SELECT 
    t.id as task_id,
    t.title,
    u.name as assigned_to,
    u.email,
    CASE t.priority
        WHEN 'high' THEN CONCAT('🔴 ', t.priority)
        WHEN 'medium' THEN CONCAT('🟡 ', t.priority)
        WHEN 'low' THEN CONCAT('🟢 ', t.priority)
        ELSE t.priority
    END as priority,
    CASE 
        WHEN t.completed THEN '✅ Completed'
        WHEN t.due_date IS NULL THEN '📅 No deadline'
        WHEN t.due_date < NOW() THEN CONCAT('⚠️ Overdue by ', TIMESTAMPDIFF(DAY, t.due_date, NOW()), ' days')
        ELSE CONCAT('⏳ Due in ', TIMESTAMPDIFF(DAY, NOW(), t.due_date), ' days')
    END as status,
    DATE_FORMAT(t.due_date, '%b %d, %Y') as due_date,
    DATE_FORMAT(t.created_at, '%Y-%m-%d') as created
FROM air_tasks t
JOIN air_users u ON t.user_id = u.id
ORDER BY 
    CASE WHEN t.completed THEN 1 ELSE 0 END,
    t.due_date,
    CASE t.priority
        WHEN 'high' THEN 1
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 3
    END
LIMIT 10;

-- 10. HEALTH SCORE CALCULATION
SELECT '🏥 DATABASE HEALTH SCORE:' as section_header;
WITH HealthMetrics AS (
    SELECT 
        -- Database existence (10 points)
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = 'air_project') 
             THEN 10 ELSE 0 END as db_exists,
        
        -- All tables exist (20 points)
        CASE WHEN (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'air_project') >= 2
             THEN 20 ELSE 0 END as tables_exist,
        
        -- No orphaned records (20 points)
        CASE WHEN (SELECT COUNT(*) FROM air_tasks t LEFT JOIN air_users u ON t.user_id = u.id WHERE u.id IS NULL) = 0
             THEN 20 ELSE 0 END as no_orphans,
        
        -- Data quality (20 points)
        CASE WHEN (SELECT COUNT(*) FROM air_users WHERE email LIKE '%@%') = (SELECT COUNT(*) FROM air_users)
             THEN 10 ELSE 0 END +
        CASE WHEN (SELECT COUNT(*) FROM air_tasks WHERE LENGTH(TRIM(title)) > 0) = (SELECT COUNT(*) FROM air_tasks)
             THEN 10 ELSE 0 END as data_quality,
        
        -- Performance indexes (20 points)
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.STATISTICS 
                         WHERE TABLE_SCHEMA = 'air_project' AND TABLE_NAME = 'air_tasks' 
                         AND INDEX_NAME = 'idx_user_id')
             THEN 10 ELSE 0 END +
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.KEY_COLUMN_USAGE 
                         WHERE TABLE_SCHEMA = 'air_project' AND CONSTRAINT_NAME LIKE '%foreign%')
             THEN 10 ELSE 0 END as performance,
        
        -- Sample data (10 points)
        CASE WHEN (SELECT COUNT(*) FROM air_users) > 0 AND (SELECT COUNT(*) FROM air_tasks) > 0
             THEN 10 ELSE 0 END as has_data
)
SELECT 
    CONCAT(ROUND((db_exists + tables_exist + no_orphans + data_quality + performance + has_data), 0), '/100') as health_score,
    CASE 
        WHEN (db_exists + tables_exist + no_orphans + data_quality + performance + has_data) >= 90 THEN '💚 EXCELLENT'
        WHEN (db_exists + tables_exist + no_orphans + data_quality + performance + has_data) >= 70 THEN '💙 GOOD'
        WHEN (db_exists + tables_exist + no_orphans + data_quality + performance + has_data) >= 50 THEN '💛 FAIR'
        ELSE '❤️ NEEDS ATTENTION'
    END as health_status,
    db_exists as 'DB Exists',
    tables_exist as 'Tables',
    no_orphans as 'No Orphans',
    data_quality as 'Data Quality',
    performance as 'Performance',
    has_data as 'Has Data'
FROM HealthMetrics;

-- 11. RECOMMENDATIONS
SELECT '💡 RECOMMENDATIONS:' as section_header;
SELECT 
    'If health score < 70' as condition,
    'Run setup_database.sql to recreate database' as recommendation
UNION ALL
SELECT 
    'If orphaned records found',
    'Clean up orphaned tasks or assign to valid users'
UNION ALL
SELECT 
    'If missing indexes',
    'Add indexes on frequently queried columns'
UNION ALL
SELECT 
    'If data quality issues',
    'Run data validation and cleanup procedures'
UNION ALL
SELECT 
    'If performance issues',
    'Consider adding more indexes or optimizing queries';

-- Completion
SELECT '============================================' as separator;
SELECT '✅ DATABASE VERIFICATION COMPLETED' as completion_message;
SELECT CONCAT('End Time: ', NOW()) as end_time;
SELECT CONCAT('Duration: ', TIMESTAMPDIFF(SECOND, @start_time, NOW()), ' seconds') as duration;

-- Restore original settings
SET SQL_MODE = @OLD_SQL_MODE;
SET TIME_ZONE = @OLD_TIME_ZONE;