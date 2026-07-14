param(
    [string]$SqlPath,
    [string]$PsqlPath,
    [switch]$StopApp
)

$ErrorActionPreference = 'Stop'

function Import-EnvFile {
    param([string]$Path)

    $config = @{}
    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        $name = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1).Trim()
        $config[$name] = $value
    }
    return $config
}

function Resolve-Psql {
    param([string]$ExplicitPath)

    if ($ExplicitPath -and (Test-Path -LiteralPath $ExplicitPath)) {
        return $ExplicitPath
    }

    $cmd = Get-Command psql.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $candidates = @(
        'C:\Program Files\PostgreSQL\16\bin\psql.exe',
        'C:\Program Files\PostgreSQL\15\bin\psql.exe',
        'C:\Program Files\PostgreSQL\14\bin\psql.exe'
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw 'psql.exe not found. Install PostgreSQL 16 or pass -PsqlPath "C:\Program Files\PostgreSQL\16\bin\psql.exe".'
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appHome = Split-Path -Parent $scriptDir
$envPath = Join-Path $appHome 'config\backend.env'
if (-not $SqlPath) {
    $SqlPath = Join-Path $appHome 'db\003_store_mst_real_stores.sql'
}

if (-not (Test-Path -LiteralPath $envPath)) {
    throw "Missing config: $envPath"
}
if (-not (Test-Path -LiteralPath $SqlPath)) {
    throw "Store SQL file not found: $SqlPath"
}

$config = Import-EnvFile -Path $envPath
$dbHost = $config['DB_HOST']
$dbPort = $config['DB_PORT']
$dbName = $config['DB_NAME']
$dbUser = $config['DB_USER']
$dbPassword = $config['DB_PASSWORD']

if (-not $dbHost) { $dbHost = 'localhost' }
if (-not $dbPort) { $dbPort = '5432' }
if (-not $dbName) { throw 'DB_NAME is required in backend.env.' }
if (-not $dbUser) { throw 'DB_USER is required in backend.env.' }
if (-not $dbPassword -or $dbPassword -eq 'CHANGE_ME') {
    $securePassword = Read-Host "PostgreSQL password for $dbUser" -AsSecureString
    $dbPassword = [System.Net.NetworkCredential]::new('', $securePassword).Password
}

$psql = Resolve-Psql -ExplicitPath $PsqlPath
$stopScript = Join-Path $scriptDir 'stop-all.ps1'
$startScript = Join-Path $scriptDir 'start-all.ps1'
$appStopped = $false

Write-Host "[INFO] SQL: $SqlPath"
Write-Host "[INFO] DB: $dbUser@$dbHost`:$dbPort/$dbName"
Write-Host "[INFO] psql: $psql"

try {
    if ($StopApp) {
        & $stopScript
        $appStopped = $true
    }

    $env:PGPASSWORD = $dbPassword
    $env:PGCLIENTENCODING = 'UTF8'

    & $psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -v ON_ERROR_STOP=1 -f $SqlPath
    if ($LASTEXITCODE -ne 0) {
        throw "Store import failed. psql exit code: $LASTEXITCODE"
    }

    $count = & $psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -t -A -c 'select count(*) from store_mst;'
    if ($LASTEXITCODE -ne 0) {
        throw "Store count check failed. psql exit code: $LASTEXITCODE"
    }

    Write-Host "[OK] store_mst count: $($count.Trim())"
    Write-Host '[OK] Real store data import completed.'
} finally {
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:\PGCLIENTENCODING -ErrorAction SilentlyContinue

    if ($StopApp -and $appStopped) {
        & $startScript
    }
}
