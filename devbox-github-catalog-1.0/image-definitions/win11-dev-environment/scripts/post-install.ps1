$ErrorActionPreference = "Stop"

Write-Host "Running post-install configuration..."

$dockerRoot      = "C:\Program Files\Docker\Docker"
$dockerCliPath   = Join-Path $dockerRoot "resources\bin"

function Test-PathInEnvPath {
    param([string] $PathValue, [string] $Segment)
    $segments = $PathValue.Split(';') | ForEach-Object { $_.TrimEnd('\') }
    return $segments -contains $Segment.TrimEnd('\')
}

try {
    if (-not (Test-Path $dockerRoot)) {
        Write-Warning "Docker Desktop folder not found at '$dockerRoot'. Skipping PATH configuration."
        exit 0
    }

    if (-not (Test-Path $dockerCliPath)) {
        Write-Warning "Docker CLI folder not found at '$dockerCliPath'. Skipping PATH configuration."
        exit 0
    }

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if (-not (Test-PathInEnvPath -PathValue $machinePath -Segment $dockerCliPath)) {
        $newMachinePath = ($machinePath.TrimEnd(';') + ';' + $dockerCliPath)
        [Environment]::SetEnvironmentVariable('Path', $newMachinePath, 'Machine')
        Write-Host "Added '$dockerCliPath' to MACHINE PATH."
    }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not (Test-PathInEnvPath -PathValue $userPath -Segment $dockerCliPath)) {
        $newUserPath = ($userPath.TrimEnd(';') + ';' + $dockerCliPath)
        [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
        Write-Host "Added '$dockerCliPath' to USER PATH."
    }

    $svcName = "com.docker.service"
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($null -ne $svc -and $svc.Status -ne 'Running') {
        Start-Service -Name $svcName
        Write-Host "'$svcName' started."
    }

    try {
        $dockerVersion = & docker --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $dockerVersion) {
            Write-Host "Docker is available: $dockerVersion"
        } else {
            Write-Warning "Docker CLI not available yet. A reboot may be required."
        }
    } catch {
        Write-Warning "Docker CLI invocation failed. PATH changes will apply to new sessions."
    }

    Write-Host "Post-install configuration complete."
    exit 0
}
catch {
    Write-Error "Post-install configuration failed: $($_.Exception.Message)"
    exit 1
}
