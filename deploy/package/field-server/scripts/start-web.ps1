$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appHome = Split-Path -Parent $scriptDir
$logDir = Join-Path $appHome 'logs\web'
$pidFile = Join-Path $logDir 'web.pid'
$caddyFile = Join-Path $appHome 'caddy\Caddyfile.http'

if (-not (Test-Path -LiteralPath $caddyFile)) {
    throw "Caddyfile not found: $caddyFile"
}
if (-not (Test-Path -LiteralPath (Join-Path $appHome 'web\index.html'))) {
    throw "Web build not found: $appHome\web"
}

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$existing = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    throw "Port 8080 is already in use. PID=$($existing.OwningProcess -join ',')"
}

$caddy = (Get-Command caddy.exe -ErrorAction Stop).Source
$out = Join-Path $logDir 'web.out.log'
$err = Join-Path $logDir 'web.err.log'
$env:YON_APP_HOME = $appHome

$process = Start-Process -FilePath $caddy `
    -ArgumentList @('run', '--config', $caddyFile, '--adapter', 'caddyfile') `
    -WorkingDirectory $appHome `
    -WindowStyle Hidden `
    -RedirectStandardOutput $out `
    -RedirectStandardError $err `
    -PassThru

Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ASCII
Write-Host "[OK] Web started. PID=$($process.Id), URL=http://localhost:8080"
