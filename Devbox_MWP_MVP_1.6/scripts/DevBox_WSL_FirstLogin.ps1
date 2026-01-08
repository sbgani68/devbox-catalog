# ==========================================================
# Script Name : DevBox_WSL_FirstLogin_v2.1.9.ps1
# Purpose     : First-login setup for Dev Box WSL, Ubuntu, root default user, UV
# Notes       : Safe Windows Terminal initialization, self-healing .bashrc, robust WT Kill, single visible terminal, safe font
# ==========================================================

param(
    [string]$WslDistroName = 'Ubuntu-24.04',
    [string]$DefaultLinuxUser = 'devusr'
)

$ErrorActionPreference = 'Stop'

# -------------------------------
# Logging setup
# -------------------------------
$LogDir  = "$env:USERPROFILE\DevBox\Logs"
$LogFile = Join-Path $LogDir "DevBox_WSL_FirstLogin.log"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $msg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Host $msg
    Add-Content -Path $LogFile -Value $msg
}

Write-Log "------------------------------------------------------------"
Write-Log "Starting Dev Box WSL first-login setup (ROOT-FIRST)."

# -------------------------------
# Progress bar setup
# -------------------------------
$steps = @(
    "Preparing logging...",
    "Updating WSL kernel...",
    "Installing Ubuntu if missing...",
    "Initializing Ubuntu...",
    "Creating dummy Linux user...",
    "Configuring root environment...",
    "Installing UV...",
    "Configuring /etc/wsl.conf...",
    "Initializing Windows Terminal...",
    "Updating Windows Terminal profiles...",
    "Restarting WSL shell...",
    "Collecting WSL diagnostics...",
    "Launching Windows Terminal..."
)
$totalSteps = $steps.Count
$currentStep = 0

function Update-ProgressBar {
    param(
        [string]$Message
    )
    $percent = [math]::Round(($currentStep / $totalSteps) * 100)
    Write-Progress -Activity "Dev Box Setup (First Login)" `
                   -Status "$Message" `
                   -PercentComplete $percent
}

Write-Host "Setting up your Dev Box. Please wait…`n"

# -------------------------------
# Helper: run bash scripts in WSL and log output
# -------------------------------
function Invoke-WslBash {
    param(
        [Parameter(Mandatory)][string]$Distro,
        [Parameter(Mandatory)][string]$Script
    )

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Script))
    $bashCommand = "set -euo pipefail; echo $encoded | base64 -d | bash"

    $stdoutFile = Join-Path $env:TEMP "wsl_stdout.log"
    $stderrFile = Join-Path $env:TEMP "wsl_stderr.log"

    $process = Start-Process wsl.exe `
        -ArgumentList "--distribution $Distro --user root --exec /bin/bash -lc `"$bashCommand`"" `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $stdoutFile `
        -RedirectStandardError $stderrFile

    Get-Content $stdoutFile | ForEach-Object { Write-Log $_ }
    Get-Content $stderrFile | ForEach-Object { Write-Log $_ }

    return $process.ExitCode
}

# -------------------------------
# WSL kernel & version
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]
Write-Log "Updating WSL kernel and setting default version to WSL2..."
try {
    wsl.exe --update | Out-Null
    wsl.exe --set-default-version 2 | Out-Null
    Write-Log "WSL kernel updated."
} catch {
    Write-Log "WSL update skipped or failed: $($_.Exception.Message)"
}

# -------------------------------
# Install Ubuntu if missing
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]
$existing = wsl.exe --list --quiet 2>$null
if ($existing -notcontains $WslDistroName) {
    Write-Log "Installing Ubuntu distribution '$WslDistroName'..."
    wsl.exe --install -d $WslDistroName --no-launch 2>&1 | ForEach-Object { Write-Log $_ }
} else {
    Write-Log "Ubuntu distribution '$WslDistroName' already installed."
}
wsl.exe --set-default $WslDistroName | Out-Null

# -------------------------------
# Initialize Ubuntu
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]
Write-Log "Initializing Ubuntu..."
wsl.exe -d $WslDistroName -- echo "Ubuntu initialized." | Out-Null

# -------------------------------
# Create dummy first Linux user
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]
Write-Log "Creating dummy first Unix user '$DefaultLinuxUser'..."
$dummyUserScript = @"
if ! id $DefaultLinuxUser >/dev/null 2>&1; then
    useradd -m -s /bin/bash $DefaultLinuxUser
    echo '$DefaultLinuxUser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$DefaultLinuxUser
fi
"@
$dummyUserScript = $dummyUserScript -replace "`r`n", "`n"

Invoke-WslBash -Distro $WslDistroName -Script $dummyUserScript | Out-Null
Write-Log "Dummy Unix user '$DefaultLinuxUser' created (OOBE satisfied)."

# -------------------------------
# Self-healing root environment
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]
Write-Log "Configuring root environment and self-healing .bashrc..."
$rootEnvScript = @'
mkdir -p ~/workspace ~/.local/bin

# Remove any old/broken aliases
sed -i "/alias ll=/d" ~/.bashrc
sed -i "/alias la=/d" ~/.bashrc
sed -i "/alias l=/d" ~/.bashrc

# Add correct aliases
echo "alias ll='ls -alF'" >> ~/.bashrc
echo "alias la='ls -A'" >> ~/.bashrc
echo "alias l='ls -CF'" >> ~/.bashrc

# Ensure UV env is sourced safely
if ! grep -q "source ~/.local/bin/env" ~/.bashrc; then
    echo "source ~/.local/bin/env" >> ~/.bashrc
fi
'@
$rootEnvScript = $rootEnvScript -replace "`r`n", "`n"

Invoke-WslBash -Distro $WslDistroName -Script $rootEnvScript | Out-Null
Write-Log "Root environment configured (idempotent, .bashrc fixed)."

# -------------------------------
# Install UV for root
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]
Write-Log "Installing UV for root..."
$uvInstallScript = @'
export DEBIAN_FRONTEND=noninteractive

mkdir -p ~/.local/bin
apt-get update -y
apt-get upgrade -y --with-new-pkgs
apt-get autoremove -y
apt-get install -y curl gnupg ca-certificates

# Install UV
if curl -LsSf https://astral.sh/uv/install.sh | sh; then
    echo "UV installed successfully"

    # Persist PATH for current session
    if [ -f "$HOME/.local/bin/env" ]; then
        source "$HOME/.local/bin/env"
    fi

    # Persist PATH in .bashrc for future sessions
    grep -qxF "source \$HOME/.local/bin/env" ~/.bashrc || echo "source \$HOME/.local/bin/env" >> ~/.bashrc

    uv --version
else
    echo "UV installation FAILED"
    exit 42
fi
'@
$uvInstallScript = $uvInstallScript -replace "`r`n", "`n"

$uvExitCode = Invoke-WslBash -Distro $WslDistroName -Script $uvInstallScript

switch ($uvExitCode) {
    0 { Write-Log "UV installed successfully for root." }
    42 { Write-Log "UV installation failed due to network/TLS issues." }
    default { Write-Log "UV installation failed with exit code $uvExitCode." }
}

# -------------------------------
# /etc/wsl.conf: set default root user
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]
Write-Log "Configuring /etc/wsl.conf to default root user..."
$wslConfScript = @"
mkdir -p /etc
echo '[user]' > /etc/wsl.conf
echo 'default=root' >> /etc/wsl.conf
"@
$wslConfScript = $wslConfScript -replace "`r`n", "`n"

Invoke-WslBash -Distro $WslDistroName -Script $wslConfScript | Out-Null
Write-Log "/etc/wsl.conf set to default root."

# -------------------------------
# Windows Terminal initialization (headless)
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]
$wtPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
$profileJson = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

function Initialize-WindowsTerminal {
    param(
        [int]$waitSecondsBeforeKill = 5,
        [int]$waitSecondsAfterKill = 10,
        [switch]$HiddenWindow
    )

    if (Test-Path $wtPath) {
        Write-Log "Launching Windows Terminal briefly to initialize settings.json and WSL profiles..."
        if ($HiddenWindow) {
            $proc = Start-Process $wtPath -ArgumentList "new-tab" -PassThru -WindowStyle Hidden
        } else {
            $proc = Start-Process $wtPath -ArgumentList "new-tab" -PassThru
        }

        Start-Sleep -Seconds $waitSecondsBeforeKill

        # Safely attempt Kill
        if (-not $proc.HasExited) {
            try {
                $proc.Kill()
                Write-Log "Windows Terminal process killed successfully."
            } catch {
                Write-Log "Windows Terminal process already exited."
            }
        } else {
            Write-Log "Windows Terminal process already exited before Kill."
        }

        Write-Log "Waiting $waitSecondsAfterKill seconds to ensure profiles are fully created..."
        Start-Sleep -Seconds $waitSecondsAfterKill
        Write-Log "Windows Terminal initialization complete."
    } else {
        Write-Log "Windows Terminal executable not found at $wtPath. Skipping initialization."
    }
}

# Headless initialization BEFORE profile update
Initialize-WindowsTerminal -waitSecondsBeforeKill 5 -waitSecondsAfterKill 10 -HiddenWindow

# -------------------------------
# Update Microsoft.WSL and Windows.Terminal.Wsl profiles
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]

try {
    if (Test-Path $profileJson) {
        $jsonRaw = Get-Content $profileJson -Raw
        $settings = $jsonRaw | ConvertFrom-Json

        foreach ($profile in $settings.profiles.list) {
            if ($profile.name -eq "$WslDistroName" -and $profile.source -eq "Microsoft.WSL") {
                Write-Log "Updating Microsoft.WSL $WslDistroName profile..."
                
                # Set root commandline
                if ($profile.PSObject.Properties["commandline"]) {
                    $profile.commandline = "wsl.exe -d $WslDistroName -u root"
                } else {
                    $profile.PSObject.Properties.Add(
                        [PSNoteProperty]::new("commandline", "wsl.exe -d $WslDistroName -u root")
                    )
                }

                # Set safe font
                if ($profile.PSObject.Properties["fontFace"]) {
                    $profile.fontFace = "Cascadia Code"
                } else {
                    $profile.PSObject.Properties.Add(
                        [PSNoteProperty]::new("fontFace", "Cascadia Code")
                    )
                }

                $settings.defaultProfile = $profile.guid
            }

            if ($profile.name -eq "$WslDistroName" -and $profile.source -eq "Windows.Terminal.Wsl") {
                Write-Log "Updating hidden Windows.Terminal.Wsl $WslDistroName profile..."
                
                # Set root commandline
                if ($profile.PSObject.Properties["commandline"]) {
                    $profile.commandline = "wsl.exe -d $WslDistroName -u root"
                } else {
                    $profile.PSObject.Properties.Add(
                        [PSNoteProperty]::new("commandline", "wsl.exe -d $WslDistroName -u root")
                    )
                }

                # Set safe font
                if ($profile.PSObject.Properties["fontFace"]) {
                    $profile.fontFace = "Cascadia Code"
                } else {
                    $profile.PSObject.Properties.Add(
                        [PSNoteProperty]::new("fontFace", "Cascadia Code")
                    )
                }
            }
        }

        $settings | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $profileJson
        Write-Log "Windows Terminal profiles updated successfully with root commandline and safe font."
    }
} catch {
    Write-Log "Failed to update Windows Terminal profiles: $($_.Exception.Message)"
}

# Headless initialization AFTER profile update
Initialize-WindowsTerminal -waitSecondsBeforeKill 1 -waitSecondsAfterKill 10 -HiddenWindow

# -------------------------------
# Restart WSL shell
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]
Write-Log "Restarting WSL shell to apply updated environment..."
try {
    wsl.exe --terminate $WslDistroName 2>&1 | ForEach-Object { Write-Log $_ }
    Start-Process wsl.exe -ArgumentList "-d $WslDistroName -u root -e bash -c exit" -NoNewWindow -Wait
    Write-Log "WSL shell restarted successfully."
} catch {
    Write-Log "Warning: WSL shell restart failed: $($_.Exception.Message)"
}

# -------------------------------
# Collect WSL diagnostics
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]
Write-Log "Collecting WSL diagnostics..."
$ver = wsl.exe --version 2>&1
$sts = wsl.exe --status 2>&1
Add-Content $LogFile "`n---- wsl --version ----`n$ver"
Add-Content $LogFile "`n---- wsl --status ----`n$sts"

# -------------------------------
# Final visible Windows Terminal launch
# -------------------------------
$currentStep++
Update-ProgressBar -Message $steps[$currentStep-1]
Write-Log "Launching Windows Terminal with Ubuntu as root (visible)..."
if (Test-Path $wtPath) {
    Start-Process $wtPath -ArgumentList "new-tab -p '$WslDistroName'"
    Write-Log "Windows Terminal launched (visible)."
} else {
    Write-Log "Windows Terminal executable not found at $wtPath"
}

# -------------------------------
# Completion banner
# -------------------------------
$currentStep = $totalSteps
Update-ProgressBar -Message "Dev Box setup COMPLETE!"
Start-Sleep -Seconds 1

Write-Host "`n============================================================"
Write-Host "Dev Box WSL setup COMPLETE"
Write-Host "Distro          : $WslDistroName"
Write-Host "Default user    : root"
Write-Host "WSL version     : 2"
Write-Host "UV              : $(if ($uvExitCode -eq 0) { 'Installed and ready' } else { 'Pending network fix' })"
Write-Host "Logs available  : $LogFile"
Write-Host "Open Windows Terminal to start work"
Write-Host "============================================================`n"

Write-Log "Dev Box WSL first-login setup completed."
Write-Log "------------------------------------------------------------"
