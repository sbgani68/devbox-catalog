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

# ============================================
# Remove Microsoft Windows Store for all users
# ============================================

$ErrorActionPreference = "Stop"

# --- Logging Setup ---
$LogDir  = "C:\Windows\Logs"
$LogFile = "$LogDir\remove-windowsstore.log"

if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-Log {
    param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "$Timestamp $Message"
    Add-Content -Path $LogFile -Value $Line
    Write-Output $Line
}

Write-Log "Starting removal of Microsoft.WindowsStore for all users"

# --- Remove for the current user ---
Write-Log "Removing Microsoft.WindowsStore for the current user"
Get-AppxPackage -Name Microsoft.WindowsStore | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage -Name Microsoft.WindowsStore | ForEach-Object { Write-Log "Removed: $($_.Name)" }

# --- Remove provisioned package (prevents installation for new users) ---
Write-Log "Removing Microsoft.WindowsStore provisioned package (new users)"
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq "Microsoft.WindowsStore"} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
Write-Log "Provisioned package removal complete"

Write-Log "Microsoft.WindowsStore removal finished successfully"
