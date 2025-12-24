# --- Admin check (guard only) ---
$wi = [Security.Principal.WindowsIdentity]::GetCurrent()
$wp = New-Object Security.Principal.WindowsPrincipal($wi)
$IsAdmin  = $wp.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$IsSystem = $wi.Name -eq 'NT AUTHORITY\SYSTEM'

Write-Host "Identity: $($wi.Name)"
Write-Host "IsAdmin : $IsAdmin"
Write-Host "IsSystem: $IsSystem"

if (-not ($IsAdmin -or $IsSystem)) {
    Write-Error "This script must run elevated (Admin or SYSTEM)."
    exit 1
}

# ==========================================================
# One-Shot Automated WSL 2 + Ubuntu 22.04 Offline Install
# Enterprise-ready: logging, reboot handling
# ==========================================================

$ErrorActionPreference = "Stop"

# -------------------------------
# Configuration
# -------------------------------
$BasePath = "C:\DevBox\WSL"
$LogFile  = "C:\Windows\logs\Install_WSL.log"

# Create log folder if it doesn't exist
if (-not (Test-Path "C:\Windows\logs")) { 
    New-Item -ItemType Directory -Path "C:\Windows\logs" -Force | Out-Null 
}

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
# STEP 2: Check for reboot
# -------------------------------
if (Test-RebootRequired -or -not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Log "Reboot required. Saving post-reboot state and restarting..."
    Shutdown.exe /r /t 5
    exit
}

# -------------------------------
# STEP 3: Set WSL 2 as default (automatic update if required)
# -------------------------------
try {
    Write-Log "Setting WSL 2 as default..."
    wsl --update
    wsl --set-default-version 2
} catch {
    Write-Log "WSL kernel update required. Running 'wsl --update'..."
    wsl --update
}
