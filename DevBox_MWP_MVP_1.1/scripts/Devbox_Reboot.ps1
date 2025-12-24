# --- Admin check (guard only) ---
$wi = [Security.Principal.WindowsIdentity]::GetCurrent()
$wp = New-Object Security.Principal.WindowsPrincipal($wi)
$IsAdmin  = $wp.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$IsSystem = $wi.Name -eq 'NT AUTHORITY\SYSTEM'

Write-Host "Identity: $($wi.Name)"
Write-Host "IsAdmin : $IsAdmin"
Write-Host "IsSystem: $IsSystem"

if (-not ($IsAdmin -or $IsSystem)) {
    Write-Error "This script must run elevated (Admin or SYSTEM)."
    exit 1
}

# --- Silent forced reboot with 5-second delay and logging only ---

# Ensure log directory exists
$LogDir  = "C:\Windows\Logs"
$LogFile = Join-Path $LogDir "DevBox_Reboot.log"
if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-Log([string]$Message) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    Add-Content -LiteralPath $LogFile -Value "$timestamp`t$Message"
}

try {
    Write-Log "Silent forced reboot scheduled in 5 seconds."

    # Completely silent forced reboot with 5-second timeout
    Start-Process "$env:SystemRoot\System32\shutdown.exe" `
        -ArgumentList "/r /t 5 /f" `
        -NoNewWindow

    Write-Log "shutdown.exe triggered with /r /t 5 /f."

    Start-Sleep -Seconds 2
    Exit 0
}
catch {
    Write-Log ("ERROR: " + $_.Exception.Message)
    throw
}
