# DB 유지보수 — VACUUM ANALYZE 실행 + 테이블 크기 상위 10개 리포트.
#
# 사용: powershell -ExecutionPolicy Bypass -File scripts\db-maintenance.ps1
$ErrorActionPreference = 'Stop'

function Import-EnvFile {
    param([string]$Path)
    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        Set-Item -Path ("Env:" + $line.Substring(0, $idx).Trim()) -Value $line.Substring($idx + 1).Trim()
    }
}

function Resolve-PgTool {
    param([string]$ExeName)
    $cmd = Get-Command $ExeName -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $roots = Get-ChildItem -Path 'C:\Program Files\PostgreSQL' -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending
    foreach ($root in $roots) {
        $candidate = Join-Path $root.FullName "bin\$ExeName"
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    throw "$ExeName not found."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appHome = Split-Path -Parent $scriptDir
$envFile = Join-Path $appHome 'config\backend.env'
$logFile = Join-Path $appHome 'logs\db-maintenance.log'

if (-not (Test-Path -LiteralPath $envFile)) { throw "Missing config: $envFile" }
Import-EnvFile $envFile
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $logFile) | Out-Null

$psql = Resolve-PgTool 'psql.exe'
$env:PGPASSWORD = $env:DB_PASSWORD

Write-Host "[1/2] VACUUM ANALYZE ($($env:DB_NAME))..."
& $psql -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d $env:DB_NAME -c 'VACUUM ANALYZE;'
$exit = $LASTEXITCODE

$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
if ($exit -ne 0) {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    Add-Content -LiteralPath $logFile -Value "[$ts] FAIL vacuum exit=$exit"
    throw "VACUUM failed with exit code $exit"
}
Add-Content -LiteralPath $logFile -Value "[$ts] OK vacuum analyze"

Write-Host '[2/2] Table sizes (top 10):'
$sizeSql = @"
SELECT relname AS table, pg_size_pretty(pg_total_relation_size(relid)) AS total,
       n_live_tup AS rows
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;
"@
& $psql -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d $env:DB_NAME -c $sizeSql
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Write-Host '[OK] Maintenance complete.'
