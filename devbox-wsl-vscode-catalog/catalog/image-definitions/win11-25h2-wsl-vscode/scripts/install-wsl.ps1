
# Enables WSL + Virtual Machine Platform (required for WSL2), sets default version to 2,
# and installs Ubuntu. A restart is typically required after enabling the Windows features.

Write-Host "Enabling Windows Subsystem for Linux..."
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Host

Write-Host "Enabling Virtual Machine Platform..."
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Host

Write-Host "Setting WSL default version to 2..."
wsl --set-default-version 2

Write-Host "Installing Ubuntu distro for WSL..."
wsl --install -d Ubuntu

Write-Host "WSL enablement requested. A restart may be required to complete feature activation."
