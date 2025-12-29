# =========================================================
# PART 1: Enable WSL & Virtual Machine Platform
# Reboot Required Before Installing Ubuntu
# Skips if features are already enabled
# =========================================================

$ErrorActionPreference = "Stop"

# -------------------------------
# Logging Setup
# -------------------------------
$LogFile = "C:\Windows\Logs\EnableWSL_Feature.log"
if (-not (Test-Path "C:\Windows\Logs")) { New-Item -ItemType Directory -Path "C:\Windows\Logs" -Force | Out-Null }

function Write-Log {
    param ([string]$Message)
    $TimeStampedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Host $TimeStampedMessage
    Add-Content -Path $LogFile -Value $TimeStampedMessage
}

# -------------------------------
# Check if WSL is enabled
# -------------------------------
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
$vmFeature  = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

$rebootRequired = $false

# -------------------------------
# Enable WSL if needed
# -------------------------------
if ($wslFeature.State -ne "Enabled") {
    Write-Log "Enabling Windows Subsystem for Linux..."
    try {
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
        Write-Log "WSL feature enabled successfully."
        $rebootRequired = $true
    } catch {
        Write-Log "ERROR: Failed to enable WSL feature: $_"
        exit 1
    }
} else {
    Write-Log "WSL feature already enabled. Skipping..."
}

# -------------------------------
# Enable Virtual Machine Platform if needed
# -------------------------------
if ($vmFeature.State -ne "Enabled") {
    Write-Log "Enabling Virtual Machine Platform..."
    try {
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
        Write-Log "Virtual Machine Platform enabled successfully."
        $rebootRequired = $true
    } catch {
        Write-Log "ERROR: Failed to enable Virtual Machine Platform: $_"
        exit 1
    }
} else {
    Write-Log "Virtual Machine Platform already enabled. Skipping..."
}

# -------------------------------
# Reboot if needed
# -------------------------------
if ($rebootRequired) {
    Write-Log "Rebooting system to apply changes..."
    #shutdown.exe /r /t 0 /f
} else {
    Write-Log "No reboot required. All features already enabled."
}
