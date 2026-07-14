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
Import-EnvFile (Join-Path $scriptDir 'backend.env')

if (-not (Test-Path -LiteralPath $env:JAR_PATH)) {
    throw "Backend jar not found: $env:JAR_PATH. Build it first with Maven."
}

New-Item -ItemType Directory -Force -Path $env:LOG_DIR | Out-Null

$existing = Get-NetTCPConnection -LocalPort ([int]$env:BACKEND_PORT) -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    throw "Port $env:BACKEND_PORT is already in use by PID $($existing.OwningProcess). Stop it first."
}

$java = Join-Path $env:JAVA_HOME 'bin\java.exe'
if (-not (Test-Path -LiteralPath $java)) {
    $java = (Get-Command java.exe -ErrorAction Stop).Source
}

$out = Join-Path $env:LOG_DIR 'backend.out.log'
$err = Join-Path $env:LOG_DIR 'backend.err.log'
$pidFile = Join-Path $env:LOG_DIR 'backend.pid'

$args = @(
    '-jar', $env:JAR_PATH,
    "--server.port=$env:BACKEND_PORT",
    "--spring.datasource.url=jdbc:postgresql://$env:DB_HOST`:$env:DB_PORT/$env:DB_NAME",
    "--spring.datasource.username=$env:DB_USER",
    "--spring.datasource.password=$env:DB_PASSWORD"
)

$process = Start-Process -FilePath $java `
    -ArgumentList $args `
    -WorkingDirectory (Split-Path -Parent $env:JAR_PATH) `
    -WindowStyle Hidden `
    -RedirectStandardOutput $out `
    -RedirectStandardError $err `
    -PassThru

Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ASCII
Write-Host "[OK] Test backend started. PID=$($process.Id), DB=$env:DB_NAME, PORT=$env:BACKEND_PORT"

