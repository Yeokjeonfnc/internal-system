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

# 명령행 인자를 없앤 뒤로는 값이 비면 application.yml 의 기본값(localhost/빈 비밀번호)으로
# 조용히 붙어 버리므로, 여기서 먼저 끊어 원인이 드러나게 한다.
foreach ($required in @('DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD')) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($required))) {
        throw "Missing $required in backend.env."
    }
}

# DB 접속 정보는 환경변수로만 넘긴다. --spring.datasource.password 로 넘기면 같은 PC 의
# 다른 계정도 프로세스 명령행에서 DB 비밀번호를 읽을 수 있다(Get-CimInstance Win32_Process).
$env:DB_URL = "jdbc:postgresql://$env:DB_HOST`:$env:DB_PORT/$env:DB_NAME"

$args = @(
    '-jar', $env:JAR_PATH,
    "--server.port=$env:BACKEND_PORT",
    # dev 프로파일이 어떤 경로로든 끼어들어도 JPA 가 테이블을 drop-create 하지 못하게 못을 박는다.
    '--spring.jpa.hibernate.ddl-auto=none'
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

