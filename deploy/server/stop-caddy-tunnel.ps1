$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $scriptDir 'logs\caddy-tunnel.pid'

if (Test-Path -LiteralPath $pidFile) {
    $pidValue = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    if ($pidValue) {
        Stop-Process -Id ([int]$pidValue) -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Local tunnel Caddy stopped. PID=$pidValue"
        exit 0
    }
}

Write-Host "[INFO] Local tunnel Caddy was not running."
