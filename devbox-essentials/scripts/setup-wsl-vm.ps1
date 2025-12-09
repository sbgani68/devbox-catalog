Write-Host "Enabling WSL2 and virtualization features..."

dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host "Installing WSL..."
wsl --install --no-launch
