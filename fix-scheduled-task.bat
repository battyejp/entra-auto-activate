@echo off
echo === Fixing Entra Auto-Activate Scheduled Task ===
echo.
echo This script will:
echo 1. Remove the broken scheduled task
echo 2. Create a new one with correct settings using XML
echo.
echo NOTE: This script must be run as Administrator
echo Right-click this file and select "Run as administrator"
echo.
pause

cd /d "d:\Work\Github\entra-auto-activate"

echo Removing old task...
schtasks /delete /tn "EntraAutoActivateRoles" /f

echo.
echo Creating new task with fixed settings...
schtasks /create /tn "EntraAutoActivateRoles" /xml "fixed-task.xml"

echo.
echo Verifying task creation...
schtasks /query /tn "EntraAutoActivateRoles"

echo.
echo Task update completed!
echo The task will now run daily at 07:00 and wake the computer if needed.
pause
