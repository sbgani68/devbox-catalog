# ============================================
# Script Name : Create_WSL_FirstRun_Shortcut.ps1
# Purpose     : Create a one-time WSL & Ubuntu setup shortcut for all users
# Context     : SYSTEM (runs during Dev Box provisioning)
# ============================================

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------
$LogRoot = "C:\ProgramData\Microsoft\DevBoxAgent\Logs"
$LogFile = Join-Path $LogRoot "Create_WSL_FirstRun_Shortcut.log"

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
Write-Log "Starting WSL First-Run shortcut creation."

# ---------------------------------------------------------------------
# Shortcut path
# ---------------------------------------------------------------------
$DesktopPath = "C:\Users\Public\Desktop"
$ShortcutName = "Set up WSL & Ubuntu.lnk"
$ShortcutPath = Join-Path $DesktopPath $ShortcutName

# Full path to the orchestrator script
$OrchestratorScript = "C:\ProgramData\Microsoft\DevBoxAgent\ImageDefinitions\devbox_mwp_mvp_1.1\win11-24h2-ent-m365-wsl2-ubuntu\scripts\DevBox_WSL_FirstLogin.ps1"

if (-not (Test-Path $ShortcutPath)) {
    Write-Log "Creating shortcut on Public Desktop..."

    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)

        # Target: full path to PowerShell
        $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

        # Arguments: full path to orchestrator script
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$OrchestratorScript`""

        # Use WSL executable icon
        $Shortcut.IconLocation = "C:\Windows\System32\wsl.exe,0"

        $Shortcut.WorkingDirectory = $DesktopPath
        $Shortcut.Save()

        Write-Log "Shortcut created at $ShortcutPath"
    }
    catch {
        Write-Log "ERROR: Failed to create shortcut: $_"
    }
}
else {
    Write-Log "Shortcut already exists at $ShortcutPath, skipping."
}

Write-Log "WSL First-Run shortcut creation completed."
Write-Log "------------------------------------------------------------"
