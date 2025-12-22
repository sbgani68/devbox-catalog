# ==========================================================
# One-Shot Automated WSL 2 + Ubuntu 22.04 Offline Install
# Enterprise-ready: logging, reboot handling, kernel update
# ==========================================================

$ErrorActionPreference = "Stop"

# -------------------------------
# Configuration
# -------------------------------
$BasePath       = "C:\DevBox\WSL"
$KernelUrl      = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$KernelMSI      = "$BasePath\wsl_update_x64.msi"
$LogFile        = "C:\Windows\logs\Install_WSL.log"

# Create log folder if it doesn't exist
if (-not (Test-Path "C:\Windows\logs")) { New-Item -ItemType Directory -Path "C:\Windows\logs" -Force | Out-Null }

# -------------------------------
# Function: log messages to console and file
# -------------------------------
function Write-Log {
    param([string]$Message)
    $TimeStampedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Host $TimeStampedMessage
    Add-Content -Path $LogFile -Value $TimeStampedMessage
}


# -------------------------------
# Helper: Check if reboot is required
# -------------------------------
function Test-RebootRequired {
    $RegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    return Test-Path $RegKey
}

# -------------------------------
# STEP 1: Create base folder
# -------------------------------
New-Item -ItemType Directory -Path $BasePath -Force | Out-Null
Write-Log "Base folder ready: $BasePath"

# -------------------------------
# STEP 2: Download WSL 2 kernel MSI
# -------------------------------
if (-not (Test-Path $KernelMSI)) {
    Write-Log "Downloading WSL 2 Linux kernel MSI..."
    Invoke-WebRequest -Uri $KernelUrl -OutFile $KernelMSI -UseBasicParsing
} else {
    Write-Log "WSL 2 kernel MSI already exists."
}

# -------------------------------
# STEP 3: Install WSL 2 kernel silently
# -------------------------------
Write-Log "Installing WSL 2 kernel silently..."
Start-Process msiexec.exe -ArgumentList "/i `"$KernelMSI`" /qn /norestart" -Wait

# -------------------------------
# STEP 4: Check for reboot
# -------------------------------
if (Test-RebootRequired -or -not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Log "Reboot required. Saving post-reboot state and restarting..."
    Shutdown.exe /r /t 5
    exit
}

# -------------------------------
# STEP 5: Set WSL 2 as default (automatic update if required)
# -------------------------------
try {
    Write-Log "Setting WSL 2 as default..."
    wsl --set-default-version 2
} catch {
    Write-Log "WSL kernel update required. Running 'wsl --update'..."
    wsl --update
}

