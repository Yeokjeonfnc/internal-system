# DB 백업 — pg_dump 커스텀 포맷(.dump)으로 backups\ 에 저장하고 보존 개수를 유지한다.
#
# 사용:
#   powershell -ExecutionPolicy Bypass -File scripts\backup-db.ps1            # 기본 보존 14개
#   powershell -ExecutionPolicy Bypass -File scripts\backup-db.ps1 -RetentionCount 30
#
# 복원(참고):
#   pg_restore -h 127.0.0.1 -p <port> -U postgres -d <db> --clean --if-exists <파일.dump>
param(
    [int]$RetentionCount = 14
)

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
    throw "$ExeName not found. Install PostgreSQL client tools first."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appHome = Split-Path -Parent $scriptDir
$envFile = Join-Path $appHome 'config\backend.env'
$backupDir = Join-Path $appHome 'backups'
$logFile = Join-Path $appHome 'logs\backup.log'

if (-not (Test-Path -LiteralPath $envFile)) {
    throw "Missing config: $envFile"
}
Import-EnvFile $envFile

New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $logFile) | Out-Null

$pgDump = Resolve-PgTool 'pg_dump.exe'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$file = Join-Path $backupDir "$($env:DB_NAME)-$stamp.dump"

$env:PGPASSWORD = $env:DB_PASSWORD
& $pgDump -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d $env:DB_NAME -Fc -f $file
$exit = $LASTEXITCODE
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
if ($exit -ne 0) {
    Add-Content -LiteralPath $logFile -Value "[$ts] FAIL db=$($env:DB_NAME) exit=$exit"
    throw "pg_dump failed with exit code $exit"
}

$sizeMb = [math]::Round((Get-Item -LiteralPath $file).Length / 1MB, 1)
Add-Content -LiteralPath $logFile -Value "[$ts] OK $file (${sizeMb}MB)"
Write-Host "[OK] Backup created: $file (${sizeMb}MB)"

# 보존 정책 — 최신 N개만 유지
$old = Get-ChildItem -Path $backupDir -Filter '*.dump' -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip $RetentionCount
foreach ($f in $old) {
    Remove-Item -LiteralPath $f.FullName -Force
    Add-Content -LiteralPath $logFile -Value "[$ts] PRUNE $($f.Name)"
    Write-Host "[INFO] Pruned old backup: $($f.Name)"
}
