# ============================================
# Change UAC Settings for All Users
# ============================================

$ErrorActionPreference = "Stop"

# --- Logging Setup ---
$LogDir  = "C:\Windows\Logs"
$LogFile = "$LogDir\change-uac.log"

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

Write-Log "Starting UAC configuration for all users"

# --- UAC Settings ---
# Enable or disable UAC (1 = enabled, 0 = disabled)
$EnableUAC = 1

# Prompt for consent for non-admin users (1 = yes, 0 = no)
$ConsentPromptBehaviorUser = 3 # Default, 3 = prompt for credentials, 0 = no prompt

# Prompt for consent for admin users in Admin Approval Mode (0-5)
$ConsentPromptBehaviorAdmin = 5 # Default: 5 = prompt for consent

# Always notify when programs try to make changes
$EnableSecureDesktop = 1 # 1 = yes, 0 = no

# --- Apply settings ---
$UACRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

Set-ItemProperty -Path $UACRegistryPath -Name "EnableLUA" -Value $EnableUAC
Set-ItemProperty -Path $UACRegistryPath -Name "ConsentPromptBehaviorAdmin" -Value $ConsentPromptBehaviorAdmin
Set-ItemProperty -Path $UACRegistryPath -Name "ConsentPromptBehaviorUser" -Value $ConsentPromptBehaviorUser
Set-ItemProperty -Path $UACRegistryPath -Name "PromptOnSecureDesktop" -Value $EnableSecureDesktop

Write-Log "UAC settings updated successfully. A system restart may be required for changes to take effect."
