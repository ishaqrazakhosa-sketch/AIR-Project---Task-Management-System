# AIR PROJECT DATABASE MANAGER
# Clean Working Version

# Configuration
$MySQLPath = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
$MySQLUser = "root"
$MySQLPassword = "pMYSQL123"
$Database = "air_project"

function Show-Menu {
    Clear-Host
    Write-Host "=========================================="
    Write-Host "  AIR PROJECT DATABASE MANAGER"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "1. Test MySQL Connection"
    Write-Host "2. Show Database Status"
    Write-Host "3. View Users Table"
    Write-Host "4. View Tasks Table"
    Write-Host "5. Create Test User"
    Write-Host "6. Reset Database"
    Write-Host "7. Exit"
    Write-Host ""
}

function Test-MySQLConnection {
    Write-Host "Testing MySQL connection..."
    try {
        $result = & $MySQLPath -u $MySQLUser -p$MySQLPassword -e "SELECT 'OK' as status" 2>$null
        if ($result -like "*OK*") {
            Write-Host "SUCCESS: MySQL connection working" -ForegroundColor Green
            return $true
        } else {
            Write-Host "ERROR: MySQL connection failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "ERROR: MySQL connection failed" -ForegroundColor Red
        return $false
    }
}

function Show-DatabaseStatus {
    Write-Host ""
    Write-Host "=== Database Status ===" -ForegroundColor Cyan
    
    # Check if database exists
    $dbCheck = & $MySQLPath -u $MySQLUser -p$MySQLPassword -e "SHOW DATABASES LIKE '$Database';" 2>$null
    if ($dbCheck -like "*$Database*") {
        Write-Host "Database: $Database [EXISTS]" -ForegroundColor Green
        
        # Show tables
        Write-Host "Tables:" -ForegroundColor Yellow
        & $MySQLPath -u $MySQLUser -p$MySQLPassword -D $Database -e "SHOW TABLES;" 2>$null
        
        # Show counts
        Write-Host ""
        Write-Host "Record Counts:" -ForegroundColor Cyan
        $userCount = & $MySQLPath -u $MySQLUser -p$MySQLPassword -D $Database -e "SELECT COUNT(*) FROM air_users;" 2>$null
        $taskCount = & $MySQLPath -u $MySQLUser -p$MySQLPassword -D $Database -e "SELECT COUNT(*) FROM air_tasks;" 2>$null
        Write-Host "  Users: $userCount" -ForegroundColor Yellow
        Write-Host "  Tasks: $taskCount" -ForegroundColor Yellow
    }
    else {
        Write-Host "Database: $Database [NOT FOUND]" -ForegroundColor Red
    }
}

function Show-UsersTable {
    Write-Host ""
    Write-Host "=== Users Table ===" -ForegroundColor Cyan
    & $MySQLPath -u $MySQLUser -p$MySQLPassword -D $Database -e "SELECT id, email, name FROM air_users ORDER BY id;" 2>$null
}

function Show-TasksTable {
    Write-Host ""
    Write-Host "=== Tasks Table ===" -ForegroundColor Cyan
    & $MySQLPath -u $MySQLUser -p$MySQLPassword -D $Database -e "SELECT t.id, t.title, u.name as user, t.priority, CASE WHEN t.completed = 1 THEN 'Yes' ELSE 'No' END as completed FROM air_tasks t JOIN air_users u ON t.user_id = u.id ORDER BY t.id LIMIT 20;" 2>$null
}

function Create-TestUser {
    Write-Host ""
    Write-Host "=== Create New User ===" -ForegroundColor Cyan
    
    $email = Read-Host "Enter email"
    $password = Read-Host "Enter password" -AsSecureString
    $name = Read-Host "Enter name"
    
    # Convert secure string to plain text
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    $query = "INSERT INTO air_users (email, password, name) VALUES ('$email', '$plainPassword', '$name');"
    
    try {
        & $MySQLPath -u $MySQLUser -p$MySQLPassword -D $Database -e $query 2>$null
        Write-Host "SUCCESS: User created" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Could not create user" -ForegroundColor Red
    }
}

function Reset-Database {
    Write-Host ""
    Write-Host "=== RESET DATABASE ===" -ForegroundColor Red
    Write-Host "WARNING: This will DELETE ALL DATA!" -ForegroundColor Red
    
    $confirm = Read-Host "Type 'RESET' to confirm (or anything else to cancel)"
    if ($confirm -ne "RESET") {
        Write-Host "Reset cancelled" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Resetting database..."
    
    # Create SQL commands
    $commands = @(
        "DROP DATABASE IF EXISTS $Database;",
        "CREATE DATABASE $Database CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;",
        "USE $Database;",
        "CREATE TABLE air_users (id INT PRIMARY KEY AUTO_INCREMENT, email VARCHAR(120) UNIQUE NOT NULL, password VARCHAR(255) NOT NULL, name VARCHAR(100) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP);",
        "CREATE TABLE air_tasks (id INT PRIMARY KEY AUTO_INCREMENT, user_id INT NOT NULL, title VARCHAR(200) NOT NULL, description TEXT, due_date DATETIME NULL, priority ENUM('low', 'medium', 'high') DEFAULT 'medium', completed BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY (user_id) REFERENCES air_users(id) ON DELETE CASCADE);",
        "INSERT INTO air_users (email, password, name) VALUES ('test@example.com', 'password123', 'Test User'), ('admin@airproject.com', 'admin123', 'Administrator');",
        "INSERT INTO air_tasks (user_id, title, description, due_date, priority, completed) VALUES (1, 'Welcome to AIR Project', 'Explore all features', NOW(), 'medium', FALSE), (1, 'Complete Setup Guide', 'Follow setup instructions', DATE_ADD(NOW(), INTERVAL 1 DAY), 'high', FALSE);"
    )
    
    foreach ($cmd in $commands) {
        try {
            & $MySQLPath -u $MySQLUser -p$MySQLPassword -e $cmd 2>$null
        }
        catch {
            # Continue even if some commands fail
        }
    }
    
    Write-Host "SUCCESS: Database reset complete!" -ForegroundColor Green
}

# ==================== MAIN ====================

# Check if MySQL is installed
if (-not (Test-Path $MySQLPath)) {
    Write-Host "ERROR: MySQL not found at: $MySQLPath" -ForegroundColor Red
    Write-Host "Please install MySQL or update the path." -ForegroundColor Yellow
    exit 1
}

# Set execution policy
try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
}
catch {
    # Ignore error
}

# Main menu loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Select option (1-7)"
    
    switch ($choice) {
        "1" { 
            Test-MySQLConnection 
            Write-Host ""
            Read-Host "Press Enter to continue..."
        }
        "2" { 
            Show-DatabaseStatus 
            Write-Host ""
            Read-Host "Press Enter to continue..."
        }
        "3" { 
            Show-UsersTable 
            Write-Host ""
            Read-Host "Press Enter to continue..."
        }
        "4" { 
            Show-TasksTable 
            Write-Host ""
            Read-Host "Press Enter to continue..."
        }
        "5" { 
            Create-TestUser 
            Write-Host ""
            Read-Host "Press Enter to continue..."
        }
        "6" { 
            Reset-Database 
            Write-Host ""
            Read-Host "Press Enter to continue..."
        }
        "7" { 
            Write-Host "Goodbye!" -ForegroundColor Cyan
            exit 0
        }
        default { 
            Write-Host "Invalid choice" -ForegroundColor Red 
            Write-Host ""
            Read-Host "Press Enter to continue..."
        }
    }
}