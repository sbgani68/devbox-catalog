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

# ============================================
# Enterprise WSL 2 Ubuntu 24.04 Installation
# Silent, Logged, Verified
# Logs: C:\Windows\Logs\wsl-ubuntu-install.log
# ============================================

$ErrorActionPreference = "Stop"

# --- Logging Setup ---
$LogDir  = "C:\Windows\Logs"
$LogFile = "$LogDir\wsl-ubuntu-install.log"

if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-Log {
    param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "$Timestamp $Message"
    Add-Content -Path $LogFile -Value $Line
    Write-Output $Line
}

# --- Step 0: Check if Ubuntu-24.04 is already installed ---
Write-Log "Checking if Ubuntu-24.04 is already installed"

$ExistingDistrosRaw = wsl.exe --list --verbose 2>&1
$ExistingDistrosLines = $ExistingDistrosRaw -split "`r?`n"
$ExistingDistrosLines | ForEach-Object { Write-Log $_ }

if ($ExistingDistrosLines -contains "Ubuntu-24.04") {
    Write-Log "Ubuntu-24.04 is already installed. Skipping installation."
} else {
    # --- Step 1: Install Ubuntu-24.04 ---
    Write-Log "Installing Ubuntu 24.04 LTS (no launch)"
    wsl.exe --install -d Ubuntu-24.04 --no-launch 2>&1 | ForEach-Object { Write-Log $_ }
}

# --- Step 2: Verify installation ---
Write-Log "Verifying Ubuntu-24.04 installation"

$InstalledDistrosRaw = wsl.exe --list --verbose 2>&1
$InstalledDistrosLines = $InstalledDistrosRaw -split "`r?`n"
$InstalledDistrosLines | ForEach-Object { Write-Log $_ }

# --- Step 3: Non-interactive sanity check ---
Write-Log "Performing non-interactive sanity check (uname -a)"

$UnameOutputRaw = wsl.exe -d Ubuntu-24.04 -- uname -a 2>&1
$UnameOutputLines = $UnameOutputRaw -split "`r?`n"
$UnameOutputLines | ForEach-Object { Write-Log $_ }

if ($LASTEXITCODE -ne 0) {
    Write-Log "Ubuntu-24.04 command execution failed"
    exit 1
}

Write-Log "Ubuntu-24.04 installation confirmed successfully."
