# Automated wrapper for daily role activation
# This script runs without user interaction for scheduled tasks

param(
    [string]$Email = "john.battye@ipfin.co.uk",
    [string]$LogLevel = "Info"
)

# Set up logging
$LogPath = Join-Path $PSScriptRoot "logs"
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = Join-Path $LogPath "auto-activation-$(Get-Date -Format 'yyyy-MM-dd-HHmm').log"

function Write-Log {
    param($Message, $Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry
}

try {
    Write-Log "=== Starting Automated Entra Role Activation ===" "Info"
    Write-Log "Email: $Email" "Info"
    Write-Log "Log file: $LogFile" "Info"
    
    # Change to script directory
    Set-Location $PSScriptRoot
    
    # Define the role patterns to match
    $RequiredPatterns = @("nonprod", "priv", "deployment")
    
    # Known roles based on the previous output
    $KnownRoles = @(
        "priv_ipf_ehc_nonprod_commonservices_deployment",
        "priv_ipf_ehc_nonprod_customerservices_deployment",
        "priv_ipf_ehc_nonprod_wfd_deployment"
    )
    
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
        Write-Log "No roles found matching criteria (nonprod + priv + deployment)" "Warning"
        exit 0
    }
    
    Write-Log "Found $($MatchingRoles.Count) matching roles to activate" "Info"
    foreach ($role in $MatchingRoles) {
        Write-Log "  - $role" "Info"
    }
    
    $successCount = 0
    $failureCount = 0
    $results = @()
    
    foreach ($role in $MatchingRoles) {
        Write-Log "Activating role: $role" "Info"
        
        try {
            # Run the cargo command for each role with email parameter
            $output = & cargo run -- --role-name $role --email $Email 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Successfully activated: $role" "Success"
                $successCount++
                $results += [PSCustomObject]@{
                    Role = $role
                    Status = "Success"
                    Time = Get-Date
                    Message = "Activated successfully"
                }
            } else {
                Write-Log "Failed to activate: $role (Exit code: $LASTEXITCODE)" "Error"
                Write-Log "Output: $output" "Debug"
                $failureCount++
                $results += [PSCustomObject]@{
                    Role = $role
                    Status = "Failed"
                    Time = Get-Date
                    Message = "Exit code: $LASTEXITCODE"
                }
            }
        }
        catch {
            Write-Log "Error activating: $role - $($_.Exception.Message)" "Error"
            $failureCount++
            $results += [PSCustomObject]@{
                Role = $role
                Status = "Error"
                Time = Get-Date
                Message = $_.Exception.Message
            }
        }
        
        # Wait between activations to avoid overwhelming the system
        if ($MatchingRoles.IndexOf($role) -lt ($MatchingRoles.Count - 1)) {
            Write-Log "Waiting 10 seconds before next activation..." "Info"
            Start-Sleep -Seconds 10
        }
    }
    
    # Summary
    Write-Log "=== ACTIVATION SUMMARY ===" "Info"
    Write-Log "Total roles processed: $($MatchingRoles.Count)" "Info"
    Write-Log "Successful activations: $successCount" "Info"
    Write-Log "Failed activations: $failureCount" "Info"
    
    # Save detailed results to CSV for easy review
    $csvFile = Join-Path $LogPath "activation-results-$(Get-Date -Format 'yyyy-MM-dd').csv"
    $results | Export-Csv -Path $csvFile -NoTypeInformation -Append
    Write-Log "Detailed results saved to: $csvFile" "Info"
    
    if ($failureCount -gt 0) {
        Write-Log "Some role activations failed. Check the detailed logs above." "Warning"
        exit 1
    } else {
        Write-Log "All role activations completed successfully!" "Success"
        exit 0
    }
    
} catch {
    Write-Log "Fatal error during execution: $($_.Exception.Message)" "Error"
    Write-Log "Stack trace: $($_.Exception.StackTrace)" "Debug"
    exit 1
} finally {
    Write-Log "=== Automated Entra Role Activation Completed ===" "Info"
}
