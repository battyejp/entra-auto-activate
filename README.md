- install edgedriver: https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/?form=MA13LH
  - make sure the version matches your edge
  - add it to your path
- run with `entra-auto-activate --role-name <rolename>`

## Prerequisites

### 1. Install Rust
Download and install Rust from [rustup.rs](https://rustup.rs/) or run:
```powershell
# Download and run the installer
Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile "rustup-init.exe"
.\rustup-init.exe -y

# Refresh PATH in current session
$env:PATH += ";$env:USERPROFILE\.cargo\bin"

# Verify installation
cargo --version
rustc --version
```

### 2. Install Visual Studio Build Tools
Rust on Windows requires the Microsoft C++ build tools:
```powershell
# Install via winget
winget install Microsoft.VisualStudio.2022.BuildTools

# Or download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/
```

### 3. Install Windows SDK
```powershell
# Download and install Windows 10/11 SDK
$url = "https://go.microsoft.com/fwlink/?linkid=2173743"
$output = "C:\temp\winsdksetup.exe"
New-Item -ItemType Directory -Path "C:\temp" -Force
Invoke-WebRequest -Uri $url -OutFile $output
Start-Process $output -ArgumentList "/quiet" -Wait
```

### 4. Install Microsoft Edge WebDriver
```powershell
# Add Edge WebDriver to PATH (if not already done)
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$newPath = "C:\edgedriver_win64"
if ($currentPath -notlike "*$newPath*") {
    $updatedPath = $currentPath + ";" + $newPath
    [Environment]::SetEnvironmentVariable("PATH", $updatedPath, "Machine")
}

# Update current session PATH
$env:PATH += ";C:\edgedriver_win64"

# Verify installation
Get-Command msedgedriver
```

## Building the Application

### Build Commands
```powershell
# Clone or navigate to the project directory
cd d:\Work\Github\entra-auto-activate

# Build in debug mode (faster compilation, larger binary)
cargo build

# Build in release mode (optimized, smaller binary)
cargo build --release

# Build and run immediately
cargo run -- --role-name "your-role-name"

# Check for compilation errors without building
cargo check
```

### Troubleshooting Build Issues

#### 1. Linker Errors (LNK1181: cannot open input file 'kernel32.lib')
This usually means Windows SDK is missing:
```powershell
# Ensure Visual Studio Build Tools with C++ workload is installed
winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.22000"
```

#### 2. msedgedriver not found
```powershell
# Verify Edge WebDriver is in PATH
Get-Command msedgedriver

# If not found, download from:
# https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/
# And add to PATH as shown in prerequisites
```

#### 3. Cargo not recognized
```powershell
# Refresh PATH after Rust installation
$env:PATH += ";$env:USERPROFILE\.cargo\bin"

# Or restart PowerShell/Command Prompt
```

### Build Output Locations
- **Debug builds**: `target\debug\entra-auto-activate.exe`
- **Release builds**: `target\release\entra-auto-activate.exe`

## Usage

### Single Role Activation
```powershell
# Using default email (john.battye@ipfin.co.uk)
cargo run -- --role-name "priv_ipf_ehc_nonprod_customerservices_deployment"

# Specifying a different email address
cargo run -- --role-name "priv_ipf_ehc_nonprod_customerservices_deployment" --email "your.email@ipfin.co.uk"
```

### Bulk Role Activation
Use the PowerShell script to activate multiple non-production deployment roles at once:

```powershell
# Dry run (shows what would be activated)
.\activate-nonprod-deployment-roles.ps1 -DryRun

# Actually activate the roles with default email
.\activate-nonprod-deployment-roles.ps1

# Use a different email address
.\activate-nonprod-deployment-roles.ps1 -Email "your.email@ipfin.co.uk"
```

The bulk script activates all roles that contain:
- `nonprod` (non-production)
- `priv` (privileged)
- `deployment` (deployment access)

## Automated Daily Execution

### Setup Daily Scheduled Task (Windows)
To automatically run the role activation every day at 07:00:

1. **Run as Administrator** and execute the setup script:
   ```powershell
   .\setup-daily-task.ps1
   ```

2. **Verify the task was created**:
   ```powershell
   Get-ScheduledTask -TaskName "EntraAutoActivateRoles"
   ```

3. **Test the task immediately**:
   ```powershell
   Start-ScheduledTask -TaskName "EntraAutoActivateRoles"
   ```

4. **Remove the task** (if needed):
   ```powershell
   .\setup-daily-task.ps1 -Remove
   ```

### Manual Daily Script
You can also run the automated version manually:
```powershell
.\run-daily-activation.ps1
```

### Logs
All automated runs create detailed logs in the `logs/` directory:
- Execution logs: `auto-activation-YYYY-MM-DD-HHMM.log`
- Results CSV: `activation-results-YYYY-MM-DD.csv`