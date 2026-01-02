# ==========================================================
# Script Name : Install_WSL_Ubuntu_FirstRun.ps1
# Purpose     : Prepare WSL 2 and Ubuntu 24.04 for first user
# Context     : User context
# ==========================================================

param(
    [string]$WslDistroName = 'Ubuntu-24.04'
)

$ErrorActionPreference = 'Stop'

# -------------------------------
# Logging setup
# -------------------------------
$LogDir  = "$env:USERPROFILE\DevBox\Logs"
$LogFile = Join-Path $LogDir "Install_WSL_Ubuntu_FirstRun.log"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $TimeStampedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Host $TimeStampedMessage
    Add-Content -Path $LogFile -Value $TimeStampedMessage
}

Write-Log "------------------------------------------------------------"
Write-Log "Starting WSL & Ubuntu setup."

# -------------------------------
# Update WSL kernel/components
# -------------------------------

try {
    Write-Log "Installing WSL platform (no distribution, web-download)..."
    wsl.exe --install --no-distribution --web-download | Out-Null
    Write-Log "WSL platform install command completed."
} catch {
    Write-Log "WSL platform install path skipped or already installed. Details: $($_.Exception.Message)"
}


try {
    Write-Log "Updating WSL kernel/components..."
    wsl.exe --update | Out-Null
    wsl.exe --set-default-version 2 | Out-Null
    Write-Log "WSL platform updated and ready."
} catch {
    Write-Log "WSL update failed: $($_.Exception.Message)"
}

# -------------------------------
# Install Ubuntu distribution if missing
# -------------------------------
$existingDistros = wsl.exe --list --quiet 2>$null
if ($existingDistros -notcontains $WslDistroName) {
    Write-Log "Installing WSL distribution '$WslDistroName'..."
    wsl.exe --install -d $WslDistroName --no-launch 2>&1 | ForEach-Object { Write-Log $_ }
} else {
    Write-Log "WSL distribution '$WslDistroName' already installed."
}

# -------------------------------
# Ensure distro is default
# -------------------------------
wsl.exe --set-default $WslDistroName 2>$null | Out-Null

# -------------------------------
# Initialize Ubuntu for current user
# -------------------------------
Write-Log "Initializing Ubuntu for the current user..."
try {
    & wsl.exe -d $WslDistroName -- echo "Initializing Ubuntu..." | Out-Null
    Write-Log "Ubuntu initialization complete."
} catch {
    Write-Log "Failed to initialize Ubuntu: $_"
}

# -------------------------------
# Verify Ubuntu installation
# -------------------------------
Write-Log "Verifying Ubuntu installation..."
try {
    $unameOutput = & wsl.exe -d $WslDistroName -- uname -a 2>&1
    $unameOutput | ForEach-Object { Write-Log $_ }
} catch {
    Write-Log "Unable to verify Ubuntu installation: $_"
}

# -------------------------------
# Optional: WSL diagnostics
# -------------------------------
try {
    Write-Log "Collecting WSL diagnostics..."
    $ver = wsl.exe --version 2>&1
    $sts = wsl.exe --status 2>&1

    Add-Content -Path $LogFile -Value ("`n---- wsl --version ----`n" + ($ver | Out-String))
    Add-Content -Path $LogFile -Value ("`n---- wsl --status  ----`n" + ($sts | Out-String))

    Write-Host $ver
    Write-Host $sts
    Write-Log "WSL diagnostics collected."
} catch {
    Write-Log "Failed to collect WSL diagnostics: $_"
}

Write-Log "WSL & Ubuntu setup completed."
Write-Log "------------------------------------------------------------"
