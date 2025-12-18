# ================================
# 02_Enable_WSL.ps1
# ================================

# --- Setup & logging ---
$LogRoot = 'C:\ProgramData\DevBox\JSBuildLogs'
$null = New-Item -Path $LogRoot -ItemType Directory -Force -ErrorAction SilentlyContinue

$TaskName  = '02_Enable_WSL'
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
    } catch {
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

    # --- Admin check ---
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Log "Script must run elevated. Aborting." 'ERROR'
        throw "Administrator privileges required."
    }

    # --- Required Windows features for WSL2 ---
    $features = @(
        'Microsoft-Windows-Subsystem-Linux',
        'VirtualMachinePlatform'
    )

    $changed = $false
    $restartRequested = $false

    foreach ($feature in $features) {
        Write-Log "Checking feature: $feature"

        $featureInfo = Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction Stop
        Write-Log "Current state of '$feature': $($featureInfo.State)"

        if ($featureInfo.State -ne 'Enabled') {
            Write-Log "Enabling feature '$feature' (NoRestart)"

            $result = Enable-WindowsOptionalFeature `
                -Online `
                -FeatureName $feature `
                -NoRestart `
                -ErrorAction Stop

            Write-Log "Enable result for '$feature': State=$($result.State) RestartNeeded=$($result.RestartNeeded)"

            $changed = $true
            if ($result.RestartNeeded) {
                $restartRequested = $true
            }
        }
        else {
            Write-Log "Feature '$feature' already enabled; skipping"
        }
    }

    # --- Configure WSL default version ---
    Write-Log "Setting WSL default version to 2"

    try {
        $wslOutput = & wsl.exe --set-default-version 2 2>&1
        $exitCode = $LASTEXITCODE

        if ($wslOutput) {
            Write-Log ("wsl.exe output:`n" + ($wslOutput -join "`n"))
        }

        Write-Log "wsl.exe exit code: $exitCode"

        if ($exitCode -ne 0) {
            Write-Log "Non-zero exit setting default WSL version. Likely pending reboot or kernel install." 'WARN'
        }
        else {
            Write-Log "WSL default version successfully set to 2"
        }
    }
    catch {
        Write-Log "Exception while executing wsl.exe: $($_.Exception.Message)" 'WARN'
    }

    # --- WSL status (best-effort visibility) ---
    try {
        $status = & wsl.exe --status 2>&1
        if ($status) {
            Write-Log ("WSL status:`n" + ($status -join "`n"))
        }
    }
    catch {
        Write-Log "Unable to query WSL status: $($_.Exception.Message)" 'WARN'
    }

    # --- Summary & Forced Reboot ---
    if ($changed) {
        Write-Log "One or more Windows features were modified during this run."
        Write-Log "Restart required: $restartRequested"
        Write-Log "Forcing system reboot to complete WSL enablement." 'WARN'

        if ($transcribing) {
            try {
                Stop-Transcript | Out-Null
                $transcribing = $false
            }
            catch {
                Write-Log "Stop-Transcript failed prior to reboot: $($_.Exception.Message)" 'WARN'
            }
        }

        Write-Log "Initiating forced reboot now."
        Restart-Computer -Force -Wait
    }
    else {
        Write-Log "No feature changes were required; system already compliant."
        Write-Log "Completed task: $TaskName (SUCCESS)"
    }
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
