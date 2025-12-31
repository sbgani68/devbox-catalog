# =====================================================================
# Script Name : EnableWSL_Feature.ps1
# Purpose     : Prepare Windows for WSL2 by enabling required OS features
# Context     : SYSTEM (Dev Box provisioning / image build)
# =====================================================================

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------
$LogRoot = 'C:\ProgramData\Microsoft\DevBoxAgent\Logs'
$LogFile = Join-Path $LogRoot 'EnableWSL_Feature.log'

if (-not (Test-Path $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "$timestamp $Message"

    Write-Host $entry
    Add-Content -Path $LogFile -Value $entry
}

Write-Log "------------------------------------------------------------"
Write-Log "Starting WSL prerequisite configuration (SYSTEM context)."

# ---------------------------------------------------------------------
# Feature definitions
# ---------------------------------------------------------------------
$RequiredFeatures = @(
    'Microsoft-Windows-Subsystem-Linux',
    'VirtualMachinePlatform'
)

$RebootRequired = $false

# ---------------------------------------------------------------------
# Evaluate and enable required features
# ---------------------------------------------------------------------
foreach ($FeatureName in $RequiredFeatures) {

    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName
    }
    catch {
        Write-Log "Failed to query feature state for '$FeatureName'. $_"
        throw
    }

    if ($feature.State -eq 'Enabled') {
        Write-Log "Feature '$FeatureName' is already enabled."
        continue
    }

    Write-Log "Enabling feature '$FeatureName'..."
    try {
        dism.exe /online /enable-feature /featurename:$FeatureName /all /norestart | Out-Null
        Write-Log "Feature '$FeatureName' enabled."
        $RebootRequired = $true
    }
    catch {
        Write-Log "Failed to enable feature '$FeatureName'. $_"
        throw
    }
}

# ---------------------------------------------------------------------
# Reboot handling
# ---------------------------------------------------------------------
if ($RebootRequired) {
    Write-Log "System reboot required. Rebooting now..."
    shutdown.exe /r /t 10 /f
}
else {
    Write-Log "All required features are already enabled. No reboot required."
}

Write-Log "WSL prerequisite configuration completed."
Write-Log "------------------------------------------------------------"
