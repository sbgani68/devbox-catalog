
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
# One-Shot Automated WSL 2 Platform Setup (Unattended)
# Enterprise-ready: logging
# ==========================================================

$ErrorActionPreference = "Stop"

# -------------------------------
# Configuration
# -------------------------------
$BasePath = "C:\DevBox\WSL"
$LogDir   = "C:\Windows\Logs"
$LogFile  = Join-Path $LogDir "Install_WSL.log"

# Create log folder if it doesn't exist
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
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
# STEP 1: Create base folder
# -------------------------------
New-Item -ItemType Directory -Path $BasePath -Force | Out-Null
Write-Log "Base folder ready: $BasePath"

# -------------------------------
# STEP 2: Install WSL platform (no distro, web-download)
# -------------------------------
try {
    Write-Log "Installing WSL platform (no distribution, web-download)..."
    wsl.exe --install --no-distribution --web-download | Out-Null
    Write-Log "WSL platform install command completed."
} catch {
    Write-Log "WSL platform install path skipped or already installed. Details: $($_.Exception.Message)"
}

# -------------------------------
# STEP 3: Update WSL components
# -------------------------------
try {
    Write-Log "Updating WSL components via 'wsl --update'..."
    wsl.exe --update | Out-Null
    Write-Log "WSL update completed."
} catch {
    Write-Log "wsl --update failed. Details: $($_.Exception.Message)"
    # Intentionally continuing; kernel may already be current or will be set by later steps.
}

# -------------------------------
# STEP 4: Set WSL 2 as default
# -------------------------------
try {
    Write-Log "Setting WSL 2 as default..."
    wsl.exe --set-default-version 2 | Out-Null
    Write-Log "Default WSL version set to 2."
} catch {
    Write-Log "Failed to set default to WSL 2. Details: $($_.Exception.Message)"
}

# -------------------------------
# STEP 5: Status / Diagnostics
# -------------------------------
try {
    Write-Log "Collecting WSL diagnostics..."
    $ver = wsl.exe --version 2>&1
    $sts = wsl.exe --status  2>&1
    Add-Content -Path $LogFile -Value ("`n---- wsl --version ----`n" + ($ver | Out-String))
    Add-Content -Path $LogFile -Value ("`n---- wsl --status  ----`n" + ($sts | Out-String))
    Write-Host $ver
    Write-Host $sts
    Write-Log "Diagnostics collected."
} catch {
    Write-Log "Unable to query WSL status/version. Details: $($_.Exception.Message)"
}

Write-Log "WSL platform configured (unattended) — script complete."
