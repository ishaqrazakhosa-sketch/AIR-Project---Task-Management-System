# SIMPLE DATABASE MANAGER
$mysql = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
$user = "root"
$pass = "pMYSQL123"
$db = "air_project"

function Show-Menu {
    Clear-Host
    Write-Host "=========================================="
    Write-Host "  SIMPLE DATABASE MANAGER"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "1. Test MySQL Connection"
    Write-Host "2. Show Database Status"
    Write-Host "3. View Users"
    Write-Host "4. View Tasks"
    Write-Host "5. Start Flask Backend"
    Write-Host "6. Exit"
    Write-Host ""
}

function Test-Connection {
    Write-Host "Testing MySQL connection..."
    & $mysql -u $user -p$pass -e "SELECT 'Connected' as Status;"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: MySQL is working" -ForegroundColor Green
    } else {
        Write-Host "ERROR: MySQL connection failed" -ForegroundColor Red
    }
}

function Show-Status {
    Write-Host "`n=== Database Status ===" -ForegroundColor Cyan
    & $mysql -u $user -p$pass -e "SHOW DATABASES LIKE '$db';"
    
    Write-Host "`n=== Tables in $db ===" -ForegroundColor Yellow
    & $mysql -u $user -p$pass -D $db -e "SHOW TABLES;"
    
    Write-Host "`n=== Record Counts ===" -ForegroundColor Cyan
    & $mysql -u $user -p$pass -D $db -e "SELECT 'Users:' as Type, COUNT(*) as Count FROM air_users UNION SELECT 'Tasks:' as Type, COUNT(*) as Count FROM air_tasks;"
}

function Show-Users {
    Write-Host "`n=== Users ===" -ForegroundColor Cyan
    & $mysql -u $user -p$pass -D $db -e "SELECT id, email, name FROM air_users;"
}

function Show-Tasks {
    Write-Host "`n=== Tasks ===" -ForegroundColor Cyan
    & $mysql -u $user -p$pass -D $db -e "SELECT id, title, priority, CASE WHEN completed = 1 THEN 'Yes' ELSE 'No' END as completed FROM air_tasks LIMIT 10;"
}

function Start-Flask {
    Write-Host "`n=== Starting Flask Backend ===" -ForegroundColor Cyan
    Write-Host "Opening: http://localhost:5000" -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
    py backend.py
}

# Main loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Select option (1-6)"
    
    switch ($choice) {
        "1" { Test-Connection }
        "2" { Show-Status }
        "3" { Show-Users }
        "4" { Show-Tasks }
        "5" { Start-Flask }
        "6" { 
            Write-Host "Goodbye!" -ForegroundColor Cyan
            exit 0
        }
        default { 
            Write-Host "Invalid choice" -ForegroundColor Red 
        }
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue..."
}