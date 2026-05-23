$ErrorActionPreference = 'Continue'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

& (Join-Path $scriptDir 'stop-web.ps1')
& (Join-Path $scriptDir 'stop-backend.ps1')

Write-Host "[OK] Y-ON field server stopped."
