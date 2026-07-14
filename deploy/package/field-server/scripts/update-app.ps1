# 원커맨드 배포 — 릴리즈(zip 또는 폴더)로 backend·web을 교체하고 이력을 남긴다.
#
# 사용:
#   powershell -ExecutionPolicy Bypass -File scripts\update-app.ps1 -ReleasePath C:\y-on\release\yon-field-server-20260709-120000.zip
#   powershell -ExecutionPolicy Bypass -File scripts\update-app.ps1 -ReleasePath C:\y-on\release\yon-field-server-20260709-120000
#
# 동작: 정지 → 현재 backend/web 을 releases\backup-<ts>\ 로 보관 → 새 파일 반영
#       → 기동 → 헬스체크 → logs\deploy-history.log 에 감사 기록.
# 롤백: releases\backup-<ts>\ 의 backend/web 을 다시 복사 후 start-all.
param(
    [Parameter(Mandatory = $true)]
    [string]$ReleasePath,

    # 백업 보관 개수(기본 5)
    [int]$KeepBackups = 5
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appHome = Split-Path -Parent $scriptDir
$historyLog = Join-Path $appHome 'logs\deploy-history.log'
$releasesDir = Join-Path $appHome 'releases'

# 1) 릴리즈 소스 확보 (zip이면 임시 폴더에 풀기)
$sourceDir = $ReleasePath
$tempDir = $null
if (-not (Test-Path -LiteralPath $ReleasePath)) {
    throw "Release not found: $ReleasePath"
}
if ((Get-Item -LiteralPath $ReleasePath) -isnot [System.IO.DirectoryInfo]) {
    $tempDir = Join-Path $env:TEMP ("yon-update-" + (Get-Date -Format 'yyyyMMddHHmmss'))
    Write-Host "[1/6] Extracting zip -> $tempDir"
    Expand-Archive -LiteralPath $ReleasePath -DestinationPath $tempDir -Force
    $sourceDir = $tempDir
} else {
    Write-Host "[1/6] Using release folder: $sourceDir"
}

$newJar = Join-Path $sourceDir 'backend\erp-backend-1.0.0.jar'
$newWebIndex = Join-Path $sourceDir 'web\index.html'
if (-not (Test-Path -LiteralPath $newJar)) { throw "Release has no backend jar: $newJar" }
if (-not (Test-Path -LiteralPath $newWebIndex)) { throw "Release has no web build: $newWebIndex" }

# 2) 정지
Write-Host '[2/6] Stopping services...'
& (Join-Path $scriptDir 'stop-all.ps1')

# 3) 현재 버전 백업
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $releasesDir "backup-$stamp"
Write-Host "[3/6] Backing up current version -> $backupDir"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
if (Test-Path -LiteralPath (Join-Path $appHome 'backend')) {
    Copy-Item -Path (Join-Path $appHome 'backend') -Destination $backupDir -Recurse -Force
}
if (Test-Path -LiteralPath (Join-Path $appHome 'web')) {
    Move-Item -Path (Join-Path $appHome 'web') -Destination (Join-Path $backupDir 'web') -Force
}

# 4) 새 버전 반영 (backend jar + web + db 스크립트)
Write-Host '[4/6] Applying new version...'
New-Item -ItemType Directory -Force -Path (Join-Path $appHome 'backend') | Out-Null
Copy-Item -LiteralPath $newJar -Destination (Join-Path $appHome 'backend\erp-backend-1.0.0.jar') -Force
Copy-Item -Path (Join-Path $sourceDir 'web') -Destination (Join-Path $appHome 'web') -Recurse -Force
if (Test-Path -LiteralPath (Join-Path $sourceDir 'db')) {
    Copy-Item -Path (Join-Path $sourceDir 'db\*') -Destination (Join-Path $appHome 'db') -Recurse -Force
}

# 5) 기동 + 헬스체크
Write-Host '[5/6] Starting services...'
& (Join-Path $scriptDir 'start-all.ps1')
Start-Sleep -Seconds 8
& (Join-Path $scriptDir 'health-check.ps1')

# 6) 감사 기록 + 백업 보존 정책
$jarItem = Get-Item -LiteralPath (Join-Path $appHome 'backend\erp-backend-1.0.0.jar')
$jarHash = (Get-FileHash -LiteralPath $jarItem.FullName -Algorithm SHA256).Hash.Substring(0, 12)
$who = "$env:USERDOMAIN\$env:USERNAME"
$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $historyLog) | Out-Null
Add-Content -LiteralPath $historyLog -Value "[$ts] by=$who source=$ReleasePath jar=sha256:$jarHash($([math]::Round($jarItem.Length/1MB,1))MB) backup=$backupDir"
Write-Host "[6/6] Deploy recorded to logs\deploy-history.log"

$oldBackups = Get-ChildItem -Path $releasesDir -Directory -Filter 'backup-*' -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -Skip $KeepBackups
foreach ($b in $oldBackups) {
    Remove-Item -LiteralPath $b.FullName -Recurse -Force
    Write-Host "[INFO] Pruned old backup: $($b.Name)"
}

if ($tempDir -and (Test-Path -LiteralPath $tempDir)) {
    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host '[OK] Update complete.'
