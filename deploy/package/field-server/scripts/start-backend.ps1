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

function Resolve-Java {
    if ($env:JAVA_HOME) {
        $candidate = Join-Path $env:JAVA_HOME 'bin\java.exe'
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    $cmd = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $roots = @(
        'C:\Program Files\Eclipse Adoptium',
        'C:\Program Files\Java',
        'C:\Program Files\Microsoft'
    )
    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }
        $found = Get-ChildItem -LiteralPath $root -Recurse -Filter java.exe -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\bin\\java\.exe$' } |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($found) {
            return $found.FullName
        }
    }

    throw 'java.exe not found. Install Java 17, then run this script again. Recommended: winget install -e --id EclipseAdoptium.Temurin.17.JDK'
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

$java = Resolve-Java

$out = Join-Path $logDir 'backend.out.log'
$err = Join-Path $logDir 'backend.err.log'

# 기동할 때 이전 로그를 타임스탬프로 밀어 두고(감사·장애분석용), 오래된 것은 정리한다.
function Rotate-Log {
    param([string]$Path, [int]$Keep = 10)
    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path
        if ($item.Length -gt 0) {
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            Move-Item -LiteralPath $Path -Destination "$Path.$stamp" -Force
        }
    }
    $leaf = Split-Path -Leaf $Path
    Get-ChildItem -Path (Split-Path -Parent $Path) -Filter "$leaf.*" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip $Keep |
        Remove-Item -Force -ErrorAction SilentlyContinue
}
Rotate-Log -Path $out
Rotate-Log -Path $err

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
