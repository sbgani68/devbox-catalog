Write-Host "Enabling WSL and required features..."

# Enable WSL feature if not already enabled
if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -ne "Enabled") {
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
}

# Enable Virtual Machine Platform if not already enabled
if ((Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State -ne "Enabled") {
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
}

# Set WSL 2 as default version
wsl --set-default-version 2

Write-Host "WSL installation complete."
