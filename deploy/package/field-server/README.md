# Y-ON field server package

이 패키지는 서버 PC에서 실행할 빌드 결과물만 포함합니다. Git 프로젝트 전체를 서버로 옮길 필요가 없습니다.

## Layout

```text
backend\erp-backend-1.0.0.jar
web\
config\backend.env.example
db\
scripts\
logs\
```

## Server PC first run

압축을 아래 경로에 풉니다.

```text
C:\y-on\yon-field-server
```

PostgreSQL은 16 설치를 권장합니다. 서버에 `postgresql-9.4`가 이미 있더라도 이 프로젝트용 DB로 쓰지 않는 것이 안전합니다.

중요: `admin / admin123`은 프로그램 로그인 계정입니다. PostgreSQL DB 비밀번호가 아닙니다.

Java 17도 필요합니다. 서버에서 `java.exe not found`가 나오면 아래 명령으로 설치하세요.

```powershell
winget install -e --id EclipseAdoptium.Temurin.17.JDK
```

Caddy도 필요합니다. 서버에서 `caddy.exe not found`가 나오면 아래 명령으로 설치하세요.

```powershell
winget install -e --id CaddyServer.Caddy
```

PostgreSQL 16 설치 중 `postgres` 비밀번호를 하나 정합니다. 그 비밀번호가 DB 접속 비밀번호입니다.

만약 기존 PostgreSQL 9.4가 5432 포트를 쓰고 있으면 PostgreSQL 16은 5433으로 설치하세요. 이 경우 아래 명령에 `-DbPort 5433`을 붙입니다.

테스트 DB를 초기화합니다. 실행하면 DB 비밀번호를 물어보고, `config\backend.env`도 자동으로 맞춥니다.

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\init-db.ps1
```

PostgreSQL 16을 5433 포트로 설치한 경우:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\init-db.ps1 -DbPort 5433
```

`config\backend.env`를 확인해야 하면 아래처럼 엽니다.

```powershell
notepad C:\y-on\yon-field-server\config\backend.env
```

필요하면 값은 아래 기준입니다.

```text
DB_NAME=yj_db_test
DB_USER=postgres
DB_PASSWORD=PostgreSQL 설치 때 정한 비밀번호
```

Windows 방화벽을 엽니다.

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\install-firewall-rule.ps1
```

서버를 시작합니다.

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\start-all.ps1
```

서버를 중지합니다.

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\stop-all.ps1
```

상태를 확인합니다.

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\health-check.ps1
```

## URLs

서버 PC 내부 확인:

```text
http://localhost:8080/#/login
```

외부 필드 테스트:

```text
https://test.yeokjeon.com/#/login
```

## Login account

```text
ID: admin
PW: admin123
```

## External routing

Cloudflare:

```text
DNS A record: test -> 203.234.249.145, Proxied
Origin Rule: Hostname equals test.yeokjeon.com, Destination Port = 8080
SSL/TLS mode: Flexible
```

The frontend calls `/api` on the same host. This means both local and external URLs use the same web gateway:

```text
http://localhost:8080/api
https://test.yeokjeon.com/api
```

FortiGate:

```text
203.234.249.145:8080 -> 192.168.30.30:8080
```

Kakao Developers JavaScript SDK domain:

```text
https://test.yeokjeon.com
```
