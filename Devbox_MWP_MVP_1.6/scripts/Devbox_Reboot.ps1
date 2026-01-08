# ============================================
# Script Name : DevBox_Reboot.ps1
# Purpose     : Silent forced reboot with logging
# Context     : SYSTEM (Dev Box provisioning / image build)
# ============================================

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------
$LogRoot = "C:\ProgramData\Microsoft\DevBoxAgent\Logs"
$LogFile = Join-Path $LogRoot "DevBox_Reboot.log"

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
Write-Log "Starting silent forced reboot process."

try {
    Write-Log "Silent forced reboot scheduled in 5 seconds."

    # Trigger silent forced reboot with 5-second delay
    Start-Process "$env:SystemRoot\System32\shutdown.exe" `
        -ArgumentList "/r /t 5 /f" `
        -NoNewWindow

    Write-Log "shutdown.exe triggered with /r /t 5 /f."

    Start-Sleep -Seconds 2
}
catch {
    Write-Log "ERROR: $_"
    throw
}

Write-Log "Reboot script execution completed."
Write-Log "------------------------------------------------------------"
