# 통합 상태 점검 — 프로세스·포트·HTTP·DB·디스크·배포 버전·최근 오류를 한 번에 본다.
#
# 사용: powershell -ExecutionPolicy Bypass -File scripts\status.ps1
$ErrorActionPreference = 'Continue'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appHome = Split-Path -Parent $scriptDir
$envFile = Join-Path $appHome 'config\backend.env'

$backendPort = 3001
$dbHost = '127.0.0.1'; $dbPort = '5432'; $dbName = ''; $dbUser = ''; $dbPassword = ''
if (Test-Path -LiteralPath $envFile) {
    Get-Content -LiteralPath $envFile | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        $name = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1).Trim()
        switch ($name) {
            'BACKEND_PORT' { $backendPort = [int]$value }
            'DB_HOST' { $dbHost = $value }
            'DB_PORT' { $dbPort = $value }
            'DB_NAME' { $dbName = $value }
            'DB_USER' { $dbUser = $value }
            'DB_PASSWORD' { $dbPassword = $value }
        }
    }
}

function Show-Process {
    param([string]$Name, [string]$PidFile, [int]$Port)
    $state = 'STOPPED'
    $pidText = '-'
    if (Test-Path -LiteralPath $PidFile) {
        $pidValue = (Get-Content -LiteralPath $PidFile -Raw).Trim()
        if ($pidValue) {
            $proc = Get-Process -Id ([int]$pidValue) -ErrorAction SilentlyContinue
            if ($proc) { $state = 'RUNNING'; $pidText = $pidValue }
        }
    }
    $listen = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    $portText = 'closed'
    if ($listen) { $portText = 'LISTEN' }
    Write-Host ("{0,-8} {1,-8} PID={2,-7} port {3}={4}" -f $Name, $state, $pidText, $Port, $portText)
}

function Show-Http {
    param([string]$Name, [string]$Url)
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 8
        $sw.Stop()
        Write-Host ("HTTP     [OK]   {0} -> {1} ({2}ms)" -f $Name, $r.StatusCode, $sw.ElapsedMilliseconds)
    } catch {
        $status = ''
        if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
        Write-Host ("HTTP     [FAIL] {0} -> {1} {2}" -f $Name, $status, $_.Exception.Message)
    }
}

Write-Host '================ Y-ON Field Server Status ================'
Write-Host ("Time: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Host ''

# 1) 프로세스/포트
Show-Process -Name 'Backend' -PidFile (Join-Path $appHome 'logs\backend\backend.pid') -Port $backendPort
Show-Process -Name 'Web' -PidFile (Join-Path $appHome 'logs\web\web.pid') -Port 8080
Write-Host ''

# 2) HTTP 헬스
Show-Http -Name 'Web /' -Url 'http://127.0.0.1:8080/'
Show-Http -Name 'API codes' -Url "http://127.0.0.1:$backendPort/api/codes?grpCd=10"
Write-Host ''

# 3) DB 연결
$psql = $null
$cmd = Get-Command psql.exe -ErrorAction SilentlyContinue
if ($cmd) { $psql = $cmd.Source }
if (-not $psql) {
    $roots = Get-ChildItem -Path 'C:\Program Files\PostgreSQL' -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending
    foreach ($root in $roots) {
        $candidate = Join-Path $root.FullName 'bin\psql.exe'
        if (Test-Path -LiteralPath $candidate) { $psql = $candidate; break }
    }
}
if ($psql -and $dbName) {
    $env:PGPASSWORD = $dbPassword
    $null = & $psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -t -A -c 'SELECT 1;' 2>$null
    $dbOk = ($LASTEXITCODE -eq 0)
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    if ($dbOk) {
        Write-Host ("DB       [OK]   {0}@{1}:{2}/{3}" -f $dbUser, $dbHost, $dbPort, $dbName)
    } else {
        Write-Host ("DB       [FAIL] {0}@{1}:{2}/{3}" -f $dbUser, $dbHost, $dbPort, $dbName)
    }
} else {
    Write-Host 'DB       [SKIP] psql not found or config missing'
}
Write-Host ''

# 4) 배포 버전(파일 시각) — 어떤 빌드가 돌고 있는지 즉시 확인
$jar = Join-Path $appHome 'backend\erp-backend-1.0.0.jar'
if (Test-Path -LiteralPath $jar) {
    $j = Get-Item -LiteralPath $jar
    Write-Host ("Deploy   backend jar : {0:yyyy-MM-dd HH:mm} ({1:N1}MB)" -f $j.LastWriteTime, ($j.Length / 1MB))
}
$idx = Join-Path $appHome 'web\index.html'
if (Test-Path -LiteralPath $idx) {
    $w = Get-Item -LiteralPath $idx
    Write-Host ("Deploy   web build   : {0:yyyy-MM-dd HH:mm}" -f $w.LastWriteTime)
}
$hist = Join-Path $appHome 'logs\deploy-history.log'
if (Test-Path -LiteralPath $hist) {
    $last = Get-Content -LiteralPath $hist -Tail 1
    Write-Host ("Deploy   last deploy : {0}" -f $last)
}
Write-Host ''

# 5) 디스크·백업
$drive = (Get-Item -LiteralPath $appHome).PSDrive
Write-Host ("Disk     {0}: free {1:N1}GB / used {2:N1}GB" -f $drive.Name, ($drive.Free / 1GB), ($drive.Used / 1GB))
$backupDir = Join-Path $appHome 'backups'
if (Test-Path -LiteralPath $backupDir) {
    $lastBackup = Get-ChildItem -Path $backupDir -Filter '*.dump' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($lastBackup) {
        Write-Host ("Backup   last: {0} ({1:yyyy-MM-dd HH:mm})" -f $lastBackup.Name, $lastBackup.LastWriteTime)
    } else {
        Write-Host 'Backup   (없음) — scripts\backup-db.ps1 실행 권장'
    }
} else {
    Write-Host 'Backup   (없음) — scripts\backup-db.ps1 실행 권장'
}
Write-Host ''

# 6) 최근 백엔드 오류
$errLog = Join-Path $appHome 'logs\backend\backend.err.log'
if (Test-Path -LiteralPath $errLog) {
    $tail = Get-Content -LiteralPath $errLog -Tail 3 -ErrorAction SilentlyContinue
    if ($tail) {
        Write-Host 'Recent backend.err.log:'
        $tail | ForEach-Object { Write-Host ("  " + $_) }
    }
}
Write-Host '=========================================================='
