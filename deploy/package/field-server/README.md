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

DB 폴더에는 아래 기준 파일이 포함됩니다.

```text
db\001_schema.sql
db\002_seed_test.sql
db\003_store_mst_real_stores.sql
db\migrations\
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

실제 매장 데이터 1,038건을 반영합니다. 이 작업은 `store_mst`만 비우고 다시 넣습니다. 사용자/부서/로그인 데이터는 변경하지 않습니다.

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\apply-real-stores.ps1 -StopApp
```

적용 확인:

```powershell
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" `
  -h 127.0.0.1 `
  -p 5433 `
  -U postgres `
  -d yj_db_test `
  -c "select count(*) from store_mst;"
```

정상값은 `1038`입니다.

이미 생성된 DB에 엑셀 기준 보정만 추가하려면 아래 마이그레이션을 실행합니다.

```powershell
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" `
  -h 127.0.0.1 `
  -p 5433 `
  -U postgres `
  -d yj_db_test `
  -v ON_ERROR_STOP=1 `
  -f C:\y-on\yon-field-server\db\migrations\20260529_align_dept_mst_with_db_structure.sql
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

## 운영·유지보수 명령

**통합 상태 점검** — 프로세스·포트·HTTP·DB·디스크·배포 버전·최근 오류를 한 화면에:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\status.ps1
```

**새 버전 배포(원커맨드)** — 정지→현재 버전 백업→교체→기동→헬스체크→`logs\deploy-history.log` 감사 기록:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\update-app.ps1 -ReleasePath C:\y-on\release\yon-field-server-<타임스탬프>.zip
```

롤백은 `releases\backup-<시각>\` 의 backend·web 폴더를 되돌려 넣고 `start-all.ps1` 을 실행하면 됩니다.

**DB 백업** — `backups\` 에 pg_dump(.dump) 저장, 기본 14개 보존, `logs\backup.log` 기록:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\backup-db.ps1
```

매일 03:00 자동 백업 등록/해제(관리자 PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\install-backup-task.ps1
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\uninstall-backup-task.ps1
```

DB 복원(참고):

```powershell
& "C:\Program Files\PostgreSQL\16\bin\pg_restore.exe" -h 127.0.0.1 -p 5433 -U postgres -d yj_db_test --clean --if-exists C:\y-on\yon-field-server\backups\<파일>.dump
```

**DB 유지보수** — VACUUM ANALYZE + 테이블 크기 상위 10개 리포트:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\db-maintenance.ps1
```

**로그(감사) 위치**

```text
logs\backend\backend.out.log(.타임스탬프)   백엔드 콘솔 — 재기동 시 자동 로테이션(최근 10개)
logs\caddy\access.log                        웹/API 접근 감사 로그(JSON, 자동 롤링) — Caddy 재시작 후 활성
logs\deploy-history.log                      배포 이력(누가·언제·어떤 JAR)
logs\backup.log                              DB 백업 이력
```

## URLs

서버 PC 내부 확인:

```text
http://localhost:8080/#/login
```

외부 필드 테스트:

```text
https://on.yeokjeon.com/#/login
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
Origin Rule: Hostname equals on.yeokjeon.com, Destination Port = 8080
SSL/TLS mode: Flexible
```

The frontend calls `/api` on the same host. This means both local and external URLs use the same web gateway:

```text
http://localhost:8080/api
https://on.yeokjeon.com/api
```

The app shell files are served with `Cache-Control: no-store` so browsers do not keep an old API base URL after a field package update.

FortiGate:

```text
203.234.249.145:8080 -> 192.168.30.30:8080
```

Kakao Developers JavaScript SDK domain:

```text
https://on.yeokjeon.com
```
