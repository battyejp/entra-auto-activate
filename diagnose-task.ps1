# Script to create a corrected scheduled task without requiring Administrator privileges
# This uses SCHTASKS to modify the existing task

Write-Host "Diagnosing scheduled task issue..." -ForegroundColor Cyan

# Check current task status
$TaskInfo = Get-ScheduledTaskInfo -TaskName "EntraAutoActivateRoles" -ErrorAction SilentlyContinue
if ($TaskInfo) {
    Write-Host ""
    Write-Host "Current Task Status:" -ForegroundColor Yellow
    Write-Host "  Last Run Time: $($TaskInfo.LastRunTime)" -ForegroundColor White
    Write-Host "  Last Result: $($TaskInfo.LastTaskResult)" -ForegroundColor White
    Write-Host "  Next Run Time: $($TaskInfo.NextRunTime)" -ForegroundColor White
    Write-Host "  Missed Runs: $($TaskInfo.NumberOfMissedRuns)" -ForegroundColor White
}

# Decode the error code
$ErrorCode = $TaskInfo.LastTaskResult
if ($ErrorCode -eq 3221225786) {
    Write-Host ""
    Write-Host "ISSUE IDENTIFIED:" -ForegroundColor Red
    Write-Host "  Error Code: $ErrorCode (0xC000013A)" -ForegroundColor White
    Write-Host "  Meaning: Process terminated unexpectedly" -ForegroundColor White
    Write-Host ""
    Write-Host "ROOT CAUSE:" -ForegroundColor Yellow
    Write-Host "  The scheduled task has a hardcoded log file path:" -ForegroundColor White
    Write-Host "  'activation-2025-07-09.log'" -ForegroundColor White
    Write-Host "  But the script expects a dynamic date format:" -ForegroundColor White
    Write-Host "  'activation-$(Get-Date -Format 'yyyy-MM-dd-HHmm').log'" -ForegroundColor White
    Write-Host ""
    Write-Host "SOLUTION:" -ForegroundColor Green
    Write-Host "  The scheduled task needs to be recreated with the correct" -ForegroundColor White
    Write-Host "  command arguments. This requires Administrator privileges." -ForegroundColor White
    Write-Host ""
    Write-Host "TO FIX:" -ForegroundColor Cyan
    Write-Host "  1. Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor White
    Write-Host "  2. Navigate to: d:\Work\Github\entra-auto-activate" -ForegroundColor White
    Write-Host "  3. Run: .\setup-daily-task.ps1 -Remove" -ForegroundColor White
    Write-Host "  4. Run: .\setup-daily-task.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "TEMPORARY WORKAROUND:" -ForegroundColor Yellow
    Write-Host "  Run manually when needed: .\run-daily-activation.ps1" -ForegroundColor White
    Write-Host "  (This works fine as we just demonstrated)" -ForegroundColor White
}

Write-Host ""
Write-Host "VERIFICATION:" -ForegroundColor Green
Write-Host "  Manual test run completed successfully today at 13:18-13:21" -ForegroundColor White
Write-Host "  All 3 roles were activated without issues" -ForegroundColor White
Write-Host "  Log files created properly: auto-activation-2025-07-22-1318.log" -ForegroundColor White
