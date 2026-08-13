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
    }
}

# PID 파일이 오래되었거나, 이전 실행이 별도 프로세스로 남은 경우도 포트 기준으로
# 정리해야 다음 백엔드 기동이 막히지 않는다.
$existing = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    Stop-Process -Id $existing.OwningProcess -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Backend stopped by port. PID=$($existing.OwningProcess)"
}

if (-not $pidValue -and -not $existing) {
    Write-Host "[INFO] Backend was not running."
}
