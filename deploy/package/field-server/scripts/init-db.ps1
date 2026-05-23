param(
    [string]$DbName = 'yj_db_test',
    [string]$DbUser = 'postgres',
    [string]$DbPassword,
    [string]$DbHost = 'localhost',
    [int]$DbPort = 5432,
    [string]$PsqlPath,
    [switch]$SkipBackendEnvUpdate
)

$ErrorActionPreference = 'Stop'

function Set-EnvValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value
    )

    $lines = @()
    if (Test-Path -LiteralPath $Path) {
        $lines = @(Get-Content -LiteralPath $Path)
    }

    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\s*$([regex]::Escape($Name))\s*=") {
            $lines[$i] = "$Name=$Value"
            $found = $true
        }
    }

    if (-not $found) {
        $lines += "$Name=$Value"
    }

    Set-Content -LiteralPath $Path -Value $lines -Encoding ASCII
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appHome = Split-Path -Parent $scriptDir
$dbDir = Join-Path $appHome 'db'
$schemaPath = Join-Path $dbDir '001_schema.sql'
$seedPath = Join-Path $dbDir '002_seed_test.sql'
$configDir = Join-Path $appHome 'config'
$envExamplePath = Join-Path $configDir 'backend.env.example'
$envPath = Join-Path $configDir 'backend.env'

if (-not $DbPassword) {
    $securePassword = Read-Host 'PostgreSQL postgres password' -AsSecureString
    $DbPassword = [System.Net.NetworkCredential]::new('', $securePassword).Password
}
if ([string]::IsNullOrWhiteSpace($DbPassword)) {
    throw 'PostgreSQL password is required.'
}
if (-not (Test-Path -LiteralPath $schemaPath)) {
    throw "Schema file not found: $schemaPath"
}
if (-not (Test-Path -LiteralPath $seedPath)) {
    throw "Seed file not found: $seedPath"
}

if (-not $PsqlPath) {
    $cmd = Get-Command psql.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        $PsqlPath = $cmd.Source
    } else {
        $candidates = @(
            'C:\Program Files\PostgreSQL\16\bin\psql.exe',
            'C:\Program Files\PostgreSQL\15\bin\psql.exe',
            'C:\Program Files\PostgreSQL\14\bin\psql.exe'
        )
        foreach ($candidate in $candidates) {
            if (Test-Path -LiteralPath $candidate) {
                $PsqlPath = $candidate
                break
            }
        }
    }
}

if (-not $PsqlPath -or -not (Test-Path -LiteralPath $PsqlPath)) {
    throw 'psql.exe not found. Install PostgreSQL 16 or pass -PsqlPath "C:\Program Files\PostgreSQL\16\bin\psql.exe".'
}

$createdbPath = Join-Path (Split-Path -Parent $PsqlPath) 'createdb.exe'
$env:PGPASSWORD = $DbPassword

try {
    $versionNum = & $PsqlPath -h $DbHost -p $DbPort -U $DbUser -d postgres -t -A -c 'SHOW server_version_num;'
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not connect to PostgreSQL. Check DbUser/DbPassword/DbHost/DbPort.'
    }
    $version = [int]($versionNum.Trim())
    if ($version -lt 120000) {
        throw "PostgreSQL version is too old: $versionNum. Install PostgreSQL 16 for this project."
    }

    $exists = & $PsqlPath -h $DbHost -p $DbPort -U $DbUser -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname = '$DbName';"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to check database: $DbName"
    }
    $existsValue = if ($null -eq $exists) { '' } else { "$exists".Trim() }
    if ($existsValue -ne '1') {
        if (Test-Path -LiteralPath $createdbPath) {
            & $createdbPath -h $DbHost -p $DbPort -U $DbUser -E UTF8 $DbName
        } else {
            & $PsqlPath -h $DbHost -p $DbPort -U $DbUser -d postgres -c "CREATE DATABASE $DbName WITH ENCODING 'UTF8';"
        }
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create database: $DbName"
        }
        Write-Host "[OK] Database created: $DbName"
    } else {
        Write-Host "[INFO] Database already exists: $DbName"
    }

    & $PsqlPath -h $DbHost -p $DbPort -U $DbUser -d $DbName -f $schemaPath
    if ($LASTEXITCODE -ne 0) {
        throw 'Schema import failed.'
    }

    & $PsqlPath -h $DbHost -p $DbPort -U $DbUser -d $DbName -f $seedPath
    if ($LASTEXITCODE -ne 0) {
        throw 'Seed import failed.'
    }

    Write-Host "[OK] Database initialized: $DbName"
    if (-not $SkipBackendEnvUpdate) {
        if (-not (Test-Path -LiteralPath $envPath)) {
            Copy-Item -LiteralPath $envExamplePath -Destination $envPath -Force
        }
        Set-EnvValue -Path $envPath -Name 'DB_HOST' -Value $DbHost
        Set-EnvValue -Path $envPath -Name 'DB_PORT' -Value $DbPort
        Set-EnvValue -Path $envPath -Name 'DB_NAME' -Value $DbName
        Set-EnvValue -Path $envPath -Name 'DB_USER' -Value $DbUser
        Set-EnvValue -Path $envPath -Name 'DB_PASSWORD' -Value $DbPassword
        Write-Host "[OK] Backend config updated: $envPath"
    }
    Write-Host "[OK] App login account: admin / admin123"
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
