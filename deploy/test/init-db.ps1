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
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..')
$dbDir = Join-Path $repoRoot 'deploy\db'

Import-EnvFile (Join-Path $scriptDir 'backend.env')

$psql = 'C:\Program Files\PostgreSQL\17\bin\psql.exe'
if (-not (Test-Path -LiteralPath $psql)) {
    $psql = (Get-Command psql.exe -ErrorAction Stop).Source
}

$env:PGPASSWORD = $env:DB_PASSWORD

Write-Host "[INFO] Recreating test database: $env:DB_NAME"
& $psql -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS $env:DB_NAME WITH (FORCE);"
& $psql -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE $env:DB_NAME ENCODING 'UTF8' TEMPLATE template0;"

Write-Host "[INFO] Applying schema and test seed"
& $psql -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d $env:DB_NAME -v ON_ERROR_STOP=1 -f (Join-Path $dbDir '001_schema.sql')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $psql -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d $env:DB_NAME -v ON_ERROR_STOP=1 -f (Join-Path $dbDir '002_seed_test.sql')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[OK] Test database initialized: $env:DB_NAME"
