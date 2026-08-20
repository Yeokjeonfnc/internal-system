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
        # backend.env 는 DB 접속·키 값만 담는 파일이다. SPRING_* 은 Spring 설정을 통째로
        # 갈아엎을 수 있어(대표적으로 SPRING_PROFILES_ACTIVE=dev 한 줄이면 JPA 가 운영
        # 테이블을 drop-create 한다) 이 파일에서 들어온 것은 무시한다.
        if ($name -like 'SPRING_*') {
            Write-Warning "[SKIP] Ignoring $name from backend.env. Spring settings are fixed by this script."
            return
        }
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

# 명령행 인자를 없앤 뒤로는 값이 비면 application.yml 의 기본값(localhost/빈 비밀번호)으로
# 조용히 붙어 버리므로, 여기서 먼저 끊어 원인이 드러나게 한다.
foreach ($required in @('DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD')) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($required))) {
        throw "Missing $required in $envFile."
    }
}

# DB 접속 정보는 환경변수로만 넘긴다. --spring.datasource.password 로 넘기면 같은 PC 의
# 다른 계정도 프로세스 명령행(Get-CimInstance Win32_Process)에서 운영 DB 비밀번호를
# 그대로 읽을 수 있다. application.yml 이 DB_URL/DB_USER/DB_PASSWORD 를 읽도록 되어 있다.
$env:DB_URL = "jdbc:postgresql://$env:DB_HOST`:$env:DB_PORT/$env:DB_NAME"

# 백엔드 로그는 롤링되는 파일(backend.log)에 남기고, 아래 backend.out.log 로 가는
# 콘솔 스트림은 WARN 이상만 받는다. backend.out.log 는 프로세스가 살아 있는 동안
# 회전되지 않아(아래 Rotate-Log 는 기동 시 1회) 무중단 운영에서 계속 커지기 때문이다.
$env:YON_LOG_FILE = Join-Path $logDir 'backend.log'
if (-not $env:LOG_CONSOLE_THRESHOLD) { $env:LOG_CONSOLE_THRESHOLD = 'WARN' }

# 현장 서버는 프로파일 없이(=application.yml 기본 섹션) 돈다. 상위 셸에 남아 있을 수 있는
# 값까지 확실히 끊는다.
if (Test-Path Env:SPRING_PROFILES_ACTIVE) { Remove-Item Env:SPRING_PROFILES_ACTIVE }

$args = @(
    '-jar', $jarPath,
    "--server.port=$port",
    # 명령행 인자는 Spring 설정 중 최우선순위다. 어떤 경로로든 dev 프로파일이 끼어들어도
    # 운영 테이블이 drop-create 되지 않도록 여기서 못을 박는다.
    '--spring.jpa.hibernate.ddl-auto=none'
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
