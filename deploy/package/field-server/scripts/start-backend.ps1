$ErrorActionPreference = 'Stop'

function Import-EnvFile {
    param([string]$Path)
    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        $name = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1).Trim()
        Set-Item -Path "Env:$name" -Value $value
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appHome = Split-Path -Parent $scriptDir
$envFile = Join-Path $appHome 'config\backend.env'
$jarPath = Join-Path $appHome 'backend\erp-backend-1.0.0.jar'
$logDir = Join-Path $appHome 'logs\backend'
$pidFile = Join-Path $logDir 'backend.pid'

if (-not (Test-Path -LiteralPath $envFile)) {
    throw "Missing config: $envFile. Copy config\backend.env.example to config\backend.env first."
}
Import-EnvFile $envFile

if (-not (Test-Path -LiteralPath $jarPath)) {
    throw "Backend jar not found: $jarPath"
}

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$port = [int]$env:BACKEND_PORT
$existing = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    throw "Port $port is already in use. PID=$($existing.OwningProcess -join ',')"
}

$java = $null
if ($env:JAVA_HOME) {
    $candidate = Join-Path $env:JAVA_HOME 'bin\java.exe'
    if (Test-Path -LiteralPath $candidate) {
        $java = $candidate
    }
}
if (-not $java) {
    $java = (Get-Command java.exe -ErrorAction Stop).Source
}

$out = Join-Path $logDir 'backend.out.log'
$err = Join-Path $logDir 'backend.err.log'

$args = @(
    '-jar', $jarPath,
    "--server.port=$port",
    "--spring.datasource.url=jdbc:postgresql://$env:DB_HOST`:$env:DB_PORT/$env:DB_NAME",
    "--spring.datasource.username=$env:DB_USER",
    "--spring.datasource.password=$env:DB_PASSWORD"
)

$process = Start-Process -FilePath $java `
    -ArgumentList $args `
    -WorkingDirectory $appHome `
    -WindowStyle Hidden `
    -RedirectStandardOutput $out `
    -RedirectStandardError $err `
    -PassThru

Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ASCII
Write-Host "[OK] Backend started. PID=$($process.Id), DB=$env:DB_NAME, PORT=$port"
