$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$logDir = Join-Path $scriptDir 'logs'
$pidFile = Join-Path $logDir 'web.pid'
$caddyFile = Join-Path $scriptDir 'Caddyfile.http'

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$existing = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    throw "Port 8080 is already in use. PID=$($existing.OwningProcess -join ',')"
}

$caddy = (Get-Command caddy.exe -ErrorAction Stop).Source
$out = Join-Path $logDir 'web.out.log'
$err = Join-Path $logDir 'web.err.log'

$process = Start-Process -FilePath $caddy `
    -ArgumentList @('run', '--config', $caddyFile, '--adapter', 'caddyfile') `
    -WorkingDirectory $repoRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $out `
    -RedirectStandardError $err `
    -PassThru

Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ASCII
Write-Host "[OK] Field web started. PID=$($process.Id), URL=http://localhost:8080"
