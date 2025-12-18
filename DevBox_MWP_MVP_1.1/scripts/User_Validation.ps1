# ================================
# 99_User_Validation.ps1
# Runs at first user login
# ================================

# --- Setup & logging ---
$LogRoot = 'C:\ProgramData\DevBox\JSBuildLogs'
$null = New-Item -Path $LogRoot -ItemType Directory -Force -ErrorAction SilentlyContinue

$TaskName  = '99_User_Validation'
$Timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'

$LogFile        = Join-Path $LogRoot "$TaskName`_$Timestamp.log"
$TranscriptFile = Join-Path $LogRoot "$TaskName`_Transcript_$Timestamp.log"

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet('INFO','PASS','WARN','FAIL')]
        [string]$Level = 'INFO'
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'o'), $Level, $Message

    try {
        Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop
    } catch {
        Write-Host "LOGGING FAILURE: $line"
    }

    Write-Host $line
}

$transcribing = $false
$Failures = 0

try {
    Start-Transcript -Path $TranscriptFile -Force -ErrorAction Stop | Out-Null
    $transcribing = $true

    Write-Log "Starting first-login user validation"

    # ------------------------------------------------------------
    # WSL availability
    # ------------------------------------------------------------
    try {
        $wslStatus = & wsl.exe --status 2>&1
        Write-Log "WSL available" 'PASS'
        Write-Log ($wslStatus -join "`n")
    }
    catch {
        Write-Log "WSL not available: $($_.Exception.Message)" 'FAIL'
        $Failures++
    }

    # ------------------------------------------------------------
    # Ubuntu 22.04 presence & execution
    # ------------------------------------------------------------
    try {
        $distros = & wsl.exe -l -q 2>$null | ForEach-Object { $_.Trim() }
        if ($distros -contains 'Ubuntu-22.04') {
            Write-Log "Ubuntu-22.04 distro present" 'PASS'

            $test = & wsl.exe -d Ubuntu-22.04 -- echo 'WSL_OK' 2>&1
            if ($test -match 'WSL_OK') {
                Write-Log "Ubuntu-22.04 launched successfully" 'PASS'
            }
            else {
                Write-Log "Ubuntu-22.04 present but not initialized yet" 'WARN'
            }
        }
        else {
            Write-Log "Ubuntu-22.04 distro not found" 'FAIL'
            $Failures++
        }
    }
    catch {
        Write-Log "Error checking Ubuntu distro: $($_.Exception.Message)" 'FAIL'
        $Failures++
    }

    # ------------------------------------------------------------
    # Default WSL version
    # ------------------------------------------------------------
    try {
        $default = (& wsl.exe --status 2>&1 | Select-String 'Default Version').Line
        if ($default -match '2') {
            Write-Log "WSL default version is 2" 'PASS'
        }
        else {
            Write-Log "WSL default version is not 2" 'WARN'
        }
    }
    catch {
        Write-Log "Unable to determine WSL default version" 'WARN'
    }

    # ------------------------------------------------------------
    # UAC baseline validation
    # ------------------------------------------------------------
    try {
        $sysKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'

        $uac = Get-ItemProperty -Path $sysKey -ErrorAction Stop

        if ($uac.EnableLUA -eq 1 -and
            $uac.ConsentPromptBehaviorAdmin -eq 5 -and
            $uac.PromptOnSecureDesktop -eq 1) {

            Write-Log "UAC policy matches Windows DEFAULT slider" 'PASS'
        }
        else {
            Write-Log "UAC policy does not match expected baseline" 'WARN'
            Write-Log "EnableLUA=$($uac.EnableLUA); ConsentPromptBehaviorAdmin=$($uac.ConsentPromptBehaviorAdmin); PromptOnSecureDesktop=$($uac.PromptOnSecureDesktop)"
        }
    }
    catch {
        Write-Log "Unable to read UAC policy: $($_.Exception.Message)" 'WARN'
    }

    # ------------------------------------------------------------
    # Microsoft Store (should be absent for user)
    # ------------------------------------------------------------
    try {
        $store = Get-AppxPackage -Name 'Microsoft.WindowsStore' -ErrorAction SilentlyContinue
        if ($store) {
            Write-Log "Microsoft Store is still installed for user" 'WARN'
        }
        else {
            Write-Log "Microsoft Store not present for user" 'PASS'
        }
    }
    catch {
        Write-Log "Error checking Microsoft Store package" 'WARN'
    }

    # ------------------------------------------------------------
    # Developer tools
    # ------------------------------------------------------------
    function Test-Tool {
        param ($Name, $Command)

        try {
            $out = & $Command 2>&1
            Write-Log "$Name available: $($out | Select-Object -First 1)" 'PASS'
        }
        catch {
            Write-Log "$Name not available" 'WARN'
        }
    }

    Test-Tool 'Git'     { git --version }
    Test-Tool 'VS Code' { code --version }
    Test-Tool 'Docker'  { docker --version }

    # ------------------------------------------------------------
    # Summary
    # ------------------------------------------------------------
    if ($Failures -eq 0) {
        Write-Log "User validation completed successfully" 'PASS'
    }
    else {
        Write-Log "User validation completed with $Failures critical failure(s)" 'FAIL'
    }
}
catch {
    Write-Log "Unexpected validation failure: $($_.Exception.Message)" 'FAIL'
}
finally {
    if ($transcribing) {
        try {
            Stop-Transcript | Out-Null
        } catch {
            Write-Log "Stop-Transcript failed: $($_.Exception.Message)" 'WARN'
        }
    }
}
