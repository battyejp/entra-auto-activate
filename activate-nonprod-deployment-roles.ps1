# PowerShell script to activate all non-production deployment roles
# This script activates all roles that contain "nonprod", "priv", and "deployment"

param(
    [switch]$DryRun,
    [switch]$Help,
    [string]$Email = "john.battye@ipfin.co.uk"
)

if ($Help) {
    Write-Host "Usage: .\activate-nonprod-deployment-roles.ps1 [-DryRun] [-Help] [-Email <email>]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -DryRun   : Show which roles would be activated without actually activating them"
    Write-Host "  -Help     : Show this help message"
    Write-Host "  -Email    : Specify the email address for account selection (default: john.battye@ipfin.co.uk)"
    Write-Host ""
    Write-Host "This script activates all roles that contain 'nonprod', 'priv', and 'deployment'"
    exit 0
}

# Define the role patterns to match
$RequiredPatterns = @("nonprod", "priv", "deployment")

# Known roles based on the previous output (you can update this list)
$KnownRoles = @(
    "priv_ipf_ehc_nonprod_commonservices_deployment",
    "priv_ipf_ehc_nonprod_customerservices_deployment",
    "priv_ipf_ehc_nonprod_wfd_deployment"
)

Write-Host "=== Entra Auto-Activate: Non-Prod Deployment Roles ===" -ForegroundColor Green
Write-Host ""

# Filter roles that match all required patterns
$MatchingRoles = $KnownRoles | Where-Object {
    $role = $_
    $matchesAll = $true
    foreach ($pattern in $RequiredPatterns) {
        if ($role -notlike "*$pattern*") {
            $matchesAll = $false
            break
        }
    }
    $matchesAll
}

if ($MatchingRoles.Count -eq 0) {
    Write-Host "No roles found matching criteria (nonprod + priv + deployment)" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($MatchingRoles.Count) matching roles:" -ForegroundColor Cyan
foreach ($role in $MatchingRoles) {
    Write-Host "  - $role" -ForegroundColor White
}
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE: Would activate the above roles" -ForegroundColor Yellow
    exit 0
}

# Confirm before proceeding
$confirmation = Read-Host "Do you want to activate these roles? (y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Starting role activation..." -ForegroundColor Green

$successCount = 0
$failureCount = 0
$results = @()

foreach ($role in $MatchingRoles) {
    Write-Host "Activating role: $role" -ForegroundColor Cyan
    
    try {
        # Run the cargo command for each role with email parameter
        $output = & cargo run -- --role-name $role --email $Email 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Successfully activated: $role" -ForegroundColor Green
            $successCount++
            $results += [PSCustomObject]@{
                Role = $role
                Status = "Success"
                Message = "Activated successfully"
            }
        } else {
            Write-Host "  ✗ Failed to activate: $role" -ForegroundColor Red
            $failureCount++
            $results += [PSCustomObject]@{
                Role = $role
                Status = "Failed"
                Message = "Exit code: $LASTEXITCODE"
            }
        }
    }
    catch {
        Write-Host "  ✗ Error activating: $role - $($_.Exception.Message)" -ForegroundColor Red
        $failureCount++
        $results += [PSCustomObject]@{
            Role = $role
            Status = "Error"
            Message = $_.Exception.Message
        }
    }
    
    Write-Host ""
    
    # Wait a bit between activations to avoid overwhelming the system
    Start-Sleep -Seconds 5
}

# Summary
Write-Host "=== ACTIVATION SUMMARY ===" -ForegroundColor Green
Write-Host "Total roles processed: $($MatchingRoles.Count)" -ForegroundColor White
Write-Host "Successful activations: $successCount" -ForegroundColor Green
Write-Host "Failed activations: $failureCount" -ForegroundColor Red
Write-Host ""

if ($results.Count -gt 0) {
    Write-Host "Detailed Results:" -ForegroundColor Cyan
    $results | Format-Table -AutoSize
}

if ($failureCount -gt 0) {
    Write-Host "Some role activations failed. Check the output above for details." -ForegroundColor Yellow
}

Write-Host "Script completed." -ForegroundColor Green
