# ================================
# 03_Install_Ubuntu2204.ps1
# ================================

# --- Setup & logging ---
$LogRoot = 'C:\ProgramData\DevBox\JSBuildLogs'
$null = New-Item -Path $LogRoot -ItemType Directory -Force -ErrorAction SilentlyContinue

$TaskName  = '03_Install_Ubuntu2204'
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

    $UbuntuDistro = 'Ubuntu-22.04'

    # --- Check if WSL is available ---
    try {
        & wsl.exe --status 1>$null 2>$null
    } catch {
        Write-Log "WSL is not available. Likely pending reboot from feature enablement." 'WARN'
        Write-Log "Ubuntu installation deferred until WSL is functional." 'WARN'
        return
    }

    # --- Query installed distributions ---
    Write-Log "Checking for installed WSL distributions"

    $installedDistros = & wsl.exe -l -q 2>$null |
        ForEach-Object { $_.Trim() }

    if ($installedDistros -contains $UbuntuDistro) {
        Write-Log "$UbuntuDistro is already installed. Skipping install."
    }
    else {
        Write-Log "$UbuntuDistro not found. Issuing install command."

        try {
            $output = & wsl.exe --install -d $UbuntuDistro 2>&1
            $exitCode = $LASTEXITCODE

            if ($output) {
                Write-Log ("wsl.exe output:`n" + ($output -join "`n"))
            }

            Write-Log "wsl.exe exit code: $exitCode"

            if ($exitCode -ne 0) {
                Write-Log "Ubuntu install returned non-zero exit code. This is common during image builds." 'WARN'
                Write-Log "Distro package may be staged but not initialized." 'WARN'
            }
            else {
                Write-Log "$UbuntuDistro install command completed successfully."
            }
        }
        catch {
            Write-Log "Exception during Ubuntu install: $($_.Exception.Message)" 'WARN'
        }
    }

    # --- Visibility: WSL status ---
    try {
        Write-Log "WSL status:"
        $status = & wsl.exe --status 2>&1
        if ($status) {
            Write-Log ($status -join "`n")
        }
    }
    catch {
        Write-Log "Unable to query WSL status: $($_.Exception.Message)" 'WARN'
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
        } catch {
            Write-Log "Stop-Transcript failed: $($_.Exception.Message)" 'WARN'
        }
    }
}
