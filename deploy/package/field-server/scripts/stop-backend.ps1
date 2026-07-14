$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appHome = Split-Path -Parent $scriptDir
$pidFile = Join-Path $appHome 'logs\backend\backend.pid'
$envFile = Join-Path $appHome 'config\backend.env'
$port = 3001

if (Test-Path -LiteralPath $envFile) {
    Get-Content -LiteralPath $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line.StartsWith('BACKEND_PORT=')) {
            $port = [int]$line.Substring('BACKEND_PORT='.Length).Trim()
        }
    }
}

if (Test-Path -LiteralPath $pidFile) {
    $pidValue = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    if ($pidValue) {
        Stop-Process -Id ([int]$pidValue) -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Backend stopped. PID=$pidValue"
        exit 0
    }
}

$existing = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    Stop-Process -Id $existing.OwningProcess -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Backend stopped by port. PID=$($existing.OwningProcess)"
    exit 0
}

Write-Host "[INFO] Backend was not running."
