# ================================
# 04_UAC_Policy_Default.ps1
# Enforces Windows DEFAULT UAC slider (Secure Desktop ON)
# ================================

# --- Setup & logging ---
$LogRoot = 'C:\ProgramData\DevBox\JSBuildLogs'
$null = New-Item -Path $LogRoot -ItemType Directory -Force -ErrorAction SilentlyContinue

$TaskName  = '04_UAC_Policy_Default'
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
$SysKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'

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

    # --- Target: Windows DEFAULT UAC slider ---
    $Target = @{
        EnableLUA                  = 1  # UAC enabled
        ConsentPromptBehaviorAdmin = 5  # Prompt for consent (default)
        PromptOnSecureDesktop      = 1  # Secure desktop ON
    }

    # --- Read current values ---
    $Current = @{}
    foreach ($name in $Target.Keys) {
        $Current[$name] = (Get-ItemProperty -Path $SysKey -Name $name -ErrorAction SilentlyContinue).$name
    }

    Write-Log "Current UAC state: EnableLUA=$($Current.EnableLUA); ConsentPromptBehaviorAdmin=$($Current.ConsentPromptBehaviorAdmin); PromptOnSecureDesktop=$($Current.PromptOnSecureDesktop)"

    $Changed = $false

    foreach ($name in $Target.Keys) {
        $Desired = [int]$Target[$name]
        $Existing = $Current[$name]

        if ($Existing -ne $Desired) {
            Write-Log "Setting $name -> $Desired"
            New-ItemProperty `
                -Path $SysKey `
                -Name $name `
                -PropertyType DWord `
                -Value $Desired `
                -Force `
                -ErrorAction Stop | Out-Null

            $Changed = $true
        }
        else {
            Write-Log "$name already set to $Desired; no change"
        }
    }

    # --- Confirm post-change ---
    $Post = @{}
    foreach ($name in $Target.Keys) {
        $Post[$name] = (Get-ItemProperty -Path $SysKey -Name $name -ErrorAction SilentlyContinue).$name
    }

    Write-Log "Post-change UAC state: EnableLUA=$($Post.EnableLUA); ConsentPromptBehaviorAdmin=$($Post.ConsentPromptBehaviorAdmin); PromptOnSecureDesktop=$($Post.PromptOnSecureDesktop)"

    if ($Changed) {
        Write-Log "UAC policy enforced to Windows DEFAULT slider (secure desktop enabled)."
        Write-Log "A reboot or user sign-out may be required for full effect." 'WARN'
    }
    else {
        Write-Log "UAC already at Windows DEFAULT slider; no changes required."
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
