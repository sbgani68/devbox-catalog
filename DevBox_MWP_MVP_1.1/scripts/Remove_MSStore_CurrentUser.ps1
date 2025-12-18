# ================================
# 05_Remove_MSStore_CurrentUser.ps1
# Removes Microsoft Store for current user (dynamic package lookup)
# ================================

# --- Setup & logging ---
$LogRoot = 'C:\ProgramData\DevBox\JSBuildLogs'
$null = New-Item -Path $LogRoot -ItemType Directory -Force -ErrorAction SilentlyContinue

$TaskName  = '05_Remove_MSStore_CurrentUser'
$Timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'

$LogFile        = Join-Path $LogRoot "$TaskName`_$Timestamp.log"
$TranscriptFile = Join-Path $LogRoot "$TaskName`_Transcript_$Timestamp.log"

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'o'), $Level, $Message

    try {
        Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Host "LOGGING FAILURE: $line"
    }

    Write-Host $line
}

$transcribing = $false

try {
    # --- Start transcript ---
    Start-Transcript -Path $TranscriptFile -Force -ErrorAction Stop | Out-Null
    $transcribing = $true

    Write-Log "Starting task: $TaskName"

    # --- Discover Microsoft Store package dynamically ---
    $pkg = Get-AppxPackage -Name 'Microsoft.WindowsStore' -ErrorAction SilentlyContinue

    if ($pkg) {
        Write-Log "Removing Microsoft Store for current user: $($pkg.PackageFullName)"

        Remove-AppxPackage `
            -Package $pkg.PackageFullName `
            -ErrorAction Stop

        Write-Log "Microsoft Store removed for current user."
    }
    else {
        Write-Log "Microsoft Store package not found for current user (already removed or disabled)." 'WARN'
    }

    Write-Log "Completed task: $TaskName (SUCCESS)"
}
catch {
    Write-Log "Task failed: $($_.Exception.Message)" 'ERROR'
    throw
}
finally {
    if ($transcribing) {
        try {
            Stop-Transcript | Out-Null
        }
        catch {
            Write-Log "Stop-Transcript failed: $($_.Exception.Message)" 'WARN'
        }
    }
}
