$ErrorActionPreference = 'Stop'

function Resolve-Caddy {
    if ($env:CADDY_PATH -and (Test-Path -LiteralPath $env:CADDY_PATH)) {
        return $env:CADDY_PATH
    }

    $cmd = Get-Command caddy.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $roots = @(
        (Join-Path $appHome 'bin'),
        'C:\Program Files\Caddy',
        'C:\Program Files',
        'C:\Program Files (x86)'
    )
    if ($env:LOCALAPPDATA) {
        $roots += (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages')
    }
    foreach ($root in $roots) {
        if (-not $root -or -not (Test-Path -LiteralPath $root)) {
            continue
        }
        $found = Get-ChildItem -LiteralPath $root -Recurse -Filter caddy.exe -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            Select-Object -First 1
        if ($found) {
            return $found.FullName
        }
    }

    throw 'caddy.exe not found. Install Caddy first: winget install -e --id CaddyServer.Caddy'
}

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
# Caddy 접근(감사) 로그 폴더 — Caddyfile 의 log 블록이 사용한다.
New-Item -ItemType Directory -Force -Path (Join-Path $appHome 'logs\caddy') | Out-Null

$existing = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    throw "Port 8080 is already in use. PID=$($existing.OwningProcess -join ',')"
}

$caddy = Resolve-Caddy
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
