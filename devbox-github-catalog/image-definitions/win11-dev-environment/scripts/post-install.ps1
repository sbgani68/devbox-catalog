
Write-Host "Running post-install configuration..."
$dockerPath = "C:\Program Files\Docker\Docker"
if (Test-Path $dockerPath) {
    setx PATH "$env:PATH;$dockerPath"
}
Write-Host "Post-install configuration complete."
