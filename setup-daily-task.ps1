# Setup script to create a scheduled task for daily role activation
# Run this script as Administrator to set up the scheduled task

param(
    [switch]$Remove,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\setup-daily-task.ps1 [-Remove] [-Help]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -Remove   : Remove the existing scheduled task"
    Write-Host "  -Help     : Show this help message"
    Write-Host ""
    Write-Host "This script creates a Windows scheduled task to run role activation daily at 07:00"
    Write-Host "Note: Run as Administrator"
    exit 0
}

$TaskName = "EntraAutoActivateRoles"
$ScriptPath = Join-Path $PSScriptRoot "run-daily-activation.ps1"
$LogPath = Join-Path $PSScriptRoot "logs"

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

if ($Remove) {
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Host "✓ Scheduled task '$TaskName' removed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to remove scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 0
}

# Create logs directory if it doesn't exist
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    Write-Host "Created logs directory: $LogPath" -ForegroundColor Green
}

# Verify the activation script exists
if (!(Test-Path $ScriptPath)) {
    Write-Host "ERROR: Activation script not found at: $ScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "Setting up daily scheduled task..." -ForegroundColor Cyan
Write-Host "Task Name: $TaskName" -ForegroundColor White
Write-Host "Script Path: $ScriptPath" -ForegroundColor White
Write-Host "Schedule: Daily at 07:00" -ForegroundColor White
Write-Host "Log Directory: $LogPath" -ForegroundColor White
Write-Host ""

try {
    # Remove existing task if it exists
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    } catch {}

    # Create the action
    $LogFile = Join-Path $LogPath "activation-$(Get-Date -Format 'yyyy-MM-dd').log"
    $Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"& '$ScriptPath' 2>&1 | Tee-Object -FilePath '$LogFile'`""
    
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $Arguments

    # Create the trigger (daily at 07:00)
    $Trigger = New-ScheduledTaskTrigger -Daily -At "07:00"

    # Create task settings
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Create the principal (run as current user)
    $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

    # Register the task
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Daily activation of Entra non-production deployment roles at 07:00"

    Write-Host "✓ Scheduled task created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Task Details:" -ForegroundColor Cyan
    Write-Host "  - Runs daily at 07:00" -ForegroundColor White
    Write-Host "  - Logs saved to: $LogPath" -ForegroundColor White
    Write-Host "  - Task name: $TaskName" -ForegroundColor White
    Write-Host ""
    Write-Host "To manage the task:" -ForegroundColor Yellow
    Write-Host "  - View: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  - Run now: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  - Remove: .\setup-daily-task.ps1 -Remove" -ForegroundColor White
    Write-Host "  - Or use Task Scheduler GUI (taskschd.msc)" -ForegroundColor White

} catch {
    Write-Host "✗ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Setup completed!" -ForegroundColor Green
