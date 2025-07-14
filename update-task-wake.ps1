# Script to update the scheduled task with WakeToRun capability
# Run this script as Administrator

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

$TaskName = "EntraAutoActivateRoles"

Write-Host "Updating scheduled task to enable WakeToRun..." -ForegroundColor Cyan

try {
    # Delete the existing task
    schtasks /delete /tn $TaskName /f
    Write-Host "✓ Removed existing task" -ForegroundColor Green
    
    # Create the new task with updated XML
    schtasks /create /tn $TaskName /xml "task_updated.xml"
    Write-Host "✓ Created updated task with WakeToRun enabled" -ForegroundColor Green
    
    # Verify the task was created
    $TaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    Write-Host ""
    Write-Host "Task Status:" -ForegroundColor Cyan
    Write-Host "  Next Run Time: $($TaskInfo.NextRunTime)" -ForegroundColor White
    Write-Host "  Last Run Time: $($TaskInfo.LastRunTime)" -ForegroundColor White
    Write-Host "  Task Name: $($TaskInfo.TaskName)" -ForegroundColor White
    
    Write-Host ""
    Write-Host "✓ Task updated successfully! The computer will now wake at 07:00 to run the role activation." -ForegroundColor Green
    
} catch {
    Write-Host "✗ Failed to update task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
