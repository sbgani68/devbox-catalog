# ============================================
# Script Name : Remove_MSStore.ps1
# Purpose     : Remove Microsoft Windows Store for all users
# Context     : SYSTEM (Dev Box provisioning / image build)
# ============================================

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------
$LogRoot = "C:\ProgramData\Microsoft\DevBoxAgent\Logs"
$LogFile = Join-Path $LogRoot "Remove_MSStore.log"

if (-not (Test-Path $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

Write-Log "------------------------------------------------------------"
Write-Log "Starting removal of Microsoft.WindowsStore for all users"

# ---------------------------------------------------------------------
# Remove for the current user
# ---------------------------------------------------------------------
Write-Log "Removing Microsoft.WindowsStore for the current user"
try {
    $apps = Get-AppxPackage -Name Microsoft.WindowsStore -ErrorAction SilentlyContinue
    if ($apps) {
        $apps | Remove-AppxPackage -ErrorAction SilentlyContinue
        foreach ($app in $apps) {
            Write-Log "Removed: $($app.Name)"
        }
    } else {
        Write-Log "No Microsoft.WindowsStore package found for the current user."
    }
}
catch {
    Write-Log "Error removing Microsoft.WindowsStore for current user: $_"
}

# ---------------------------------------------------------------------
# Remove provisioned package (prevents installation for new users)
# ---------------------------------------------------------------------
Write-Log "Removing Microsoft.WindowsStore provisioned package (new users)"
try {
    $provPackage = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq "Microsoft.WindowsStore"}
    if ($provPackage) {
        $provPackage | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        Write-Log "Provisioned package removal complete"
    } else {
        Write-Log "No provisioned Microsoft.WindowsStore package found"
    }
}
catch {
    Write-Log "Error removing provisioned package: $_"
}

Write-Log "Microsoft.WindowsStore removal finished successfully"
Write-Log "------------------------------------------------------------"
