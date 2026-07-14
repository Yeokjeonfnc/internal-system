$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $scriptDir 'backend.env'
$port = 3001
if (Test-Path -LiteralPath $envFile) {
    Get-Content -LiteralPath $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line.StartsWith('BACKEND_PORT=')) {
            $port = [int]$line.Substring('BACKEND_PORT='.Length).Trim()
        }
    }
}

$pidFile = Join-Path $scriptDir 'logs\backend.pid'
if (Test-Path -LiteralPath $pidFile) {
    $pidValue = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    if ($pidValue) {
        Stop-Process -Id ([int]$pidValue) -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Field backend stopped. PID=$pidValue"
        exit 0
    }
}

$existing = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    Stop-Process -Id $existing.OwningProcess -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Field backend stopped by port. PID=$($existing.OwningProcess)"
    exit 0
}

Write-Host "[INFO] Field backend was not running."
