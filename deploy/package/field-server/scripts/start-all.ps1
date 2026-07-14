$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

& (Join-Path $scriptDir 'start-backend.ps1')
Start-Sleep -Seconds 5
& (Join-Path $scriptDir 'start-web.ps1')

Write-Host "[OK] Y-ON field server started."
