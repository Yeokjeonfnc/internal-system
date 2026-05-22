$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$logDir = Join-Path $repoRoot 'deploy\server\logs'
$pidFile = Join-Path $logDir 'caddy.pid'
$caddyFile = Join-Path $scriptDir 'Caddyfile'

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$existing = Get-NetTCPConnection -LocalPort 80,443 -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    throw "Port 80 or 443 is already in use. Stop the current web server first. PID=$($existing.OwningProcess -join ',')"
}

$caddy = (Get-Command caddy.exe -ErrorAction Stop).Source
$out = Join-Path $logDir 'caddy.out.log'
$err = Join-Path $logDir 'caddy.err.log'

$process = Start-Process -FilePath $caddy `
    -ArgumentList @('run', '--config', $caddyFile, '--adapter', 'caddyfile') `
    -WorkingDirectory $repoRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $out `
    -RedirectStandardError $err `
    -PassThru

Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ASCII
Write-Host "[OK] Caddy started. PID=$($process.Id), config=$caddyFile"
