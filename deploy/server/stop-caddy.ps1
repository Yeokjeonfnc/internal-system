$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $scriptDir 'logs\caddy.pid'

if (Test-Path -LiteralPath $pidFile) {
    $pidValue = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    if ($pidValue) {
        Stop-Process -Id ([int]$pidValue) -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Caddy stopped. PID=$pidValue"
        exit 0
    }
}

$processes = Get-Process -Name caddy -ErrorAction SilentlyContinue
if ($processes) {
    $processes | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Caddy stopped by process name."
    exit 0
}

Write-Host "[INFO] Caddy was not running."
