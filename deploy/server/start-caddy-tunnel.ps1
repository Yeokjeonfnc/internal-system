$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$logDir = Join-Path $repoRoot 'deploy\server\logs'
$pidFile = Join-Path $logDir 'caddy-tunnel.pid'
$caddyFile = Join-Path $scriptDir 'Caddyfile.tunnel'

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$existing = Get-NetTCPConnection -LocalPort 8080,8180 -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    throw "Port 8080 or 8180 is already in use. PID=$($existing.OwningProcess -join ',')"
}

$caddy = (Get-Command caddy.exe -ErrorAction Stop).Source
$out = Join-Path $logDir 'caddy-tunnel.out.log'
$err = Join-Path $logDir 'caddy-tunnel.err.log'

$process = Start-Process -FilePath $caddy `
    -ArgumentList @('run', '--config', $caddyFile, '--adapter', 'caddyfile') `
    -WorkingDirectory $repoRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $out `
    -RedirectStandardError $err `
    -PassThru

Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ASCII
Write-Host "[OK] Local tunnel Caddy started. PID=$($process.Id), field=http://127.0.0.1:8080, prod=http://127.0.0.1:8180"
