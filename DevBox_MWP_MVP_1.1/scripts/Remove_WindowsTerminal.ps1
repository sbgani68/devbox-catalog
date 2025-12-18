# ================================
# 03_Remove_WindowsTerminal.ps1
# ================================

# --- Setup & Logging ---
$LogRoot = 'C:\ProgramData\DevBox\JSBuildLogs'
$null = New-Item -Path $LogRoot -ItemType Directory -Force -ErrorAction SilentlyContinue

$TaskName  = '03_Remove_WindowsTerminal'
$Timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'

$LogFile        = Join-Path $LogRoot "$TaskName`_$Timestamp.log"
$TranscriptFile = Join-Path $LogRoot "$TaskName`_Transcript_$Timestamp.log"

function Write-Log {
    param (
        [Parameter(Mandatory)]
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
$changed = $false

try {
    # --- Start transcript ---
    Start-Transcript -Path $TranscriptFile -Force -ErrorAction Stop | Out-Null
    $transcribing = $true

    Write-Log "Starting task: $TaskName"

    # --- Admin check ---
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Log "Script must run elevated. Aborting." 'ERROR'
        throw "Administrator privileges required."
    }

    # --- Remove provisioned packages ---
    Write-Log "Querying provisioned Appx packages matching '*WindowsTerminal*'"
    $provPackages = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like '*WindowsTerminal*'

    if ($provPackages) {
        foreach ($pkg in $provPackages) {
            Write-Log "Removing provisioned package: $($pkg.DisplayName)"
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction Stop
                Write-Log "Provisioned package removed: $($pkg.DisplayName)"
                $changed = $true
            }
            catch {
                Write-Log "Failed to remove provisioned package '$($pkg.DisplayName)': $($_.Exception.Message)" 'WARN'
            }
        }
    }
    else {
        Write-Log "No provisioned Windows Terminal packages found; skipping"
    }

    # --- Remove installed packages for all users ---
    Write-Log "Querying installed Appx packages (AllUsers) matching '*WindowsTerminal*'"
    $installedPackages = Get-AppxPackage -AllUsers | Where-Object Name -like '*WindowsTerminal*'

    if ($installedPackages) {
        foreach ($pkg in $installedPackages) {
            Write-Log "Removing installed package for all users: $($pkg.Name)"
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                Write-Log "Installed package removed: $($pkg.Name)"
                $changed = $true
            }
            catch {
                Write-Log "Failed to remove installed package '$($pkg.Name)': $($_.Exception.Message)" 'WARN'
            }
        }
    }
    else {
        Write-Log "No installed Windows Terminal packages found; skipping"
    }

    # --- Summary ---
    if ($changed) {
        Write-Log "One or more Windows Terminal packages were removed."
    }
    else {
        Write-Log "No changes were required; Windows Terminal not present."
    }

    Write-Log "Completed task: $TaskName (SUCCESS)"
}
catch {
    Write-Log "Task failed: $($_.Exception.Message)" 'ERROR'
    throw
}
finally {
    if ($transcribing) {
        try { Stop-Transcript | Out-Null }
        catch { Write-Log "Stop-Transcript failed: $($_.Exception.Message)" 'WARN' }
    }
}
