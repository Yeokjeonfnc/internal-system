# Windows server deployment

## Domain plan

- Field/development test: `test.yeokjeon.com`
- Production: `yeokjeon.com`
- Public server IP: `203.234.249.145`

Create these DNS records at WHOIS/DNS:

```text
test.yeokjeon.com  A  203.234.249.145
yeokjeon.com       A  203.234.249.145
```

## Ports

Open inbound ports on the server and router/firewall:

- `80/tcp`: Let's Encrypt HTTP validation and HTTP to HTTPS redirect
- `443/tcp`: HTTPS user traffic

Do not expose PostgreSQL `5432` to the public internet.

## Runtime layout

- Field backend: `127.0.0.1:3001`, DB `yj_db_test`
- Production backend: `127.0.0.1:3011`, DB `yj_db_prod`
- Public HTTPS: Caddy serves Flutter Web and proxies `/api/*` to the matching backend.

## First setup

1. Install Java 17, PostgreSQL, Flutter build dependencies, and Caddy.
2. Build backend:

```powershell
cd C:\y-on\internal-system\backend
$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot'
$env:Path="$env:JAVA_HOME\bin;C:\tmp\apache-maven-3.9.16\bin;$env:Path"
mvn -DskipTests package
```

3. Build frontend:

```powershell
cd C:\y-on\internal-system\app_flutter
flutter build web --no-pub --dart-define=KAKAO_MAP_JAVASCRIPT_KEY=3649c96a39bc8cff269119d8cffbe4e0
```

4. Create field backend env:

```powershell
Copy-Item C:\y-on\internal-system\deploy\field\backend.env.example C:\y-on\internal-system\deploy\field\backend.env
notepad C:\y-on\internal-system\deploy\field\backend.env
```

Set the real PostgreSQL password in `DB_PASSWORD`.

5. Start field backend and Caddy:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\internal-system\deploy\field\start-backend.ps1
powershell -ExecutionPolicy Bypass -File C:\y-on\internal-system\deploy\server\start-caddy.ps1
```

6. Test:

```text
https://test.yeokjeon.com/#/login
```

## Production later

When production data is ready:

1. Create `yj_db_prod`.
2. Copy `deploy\prod\backend.env.example` to `deploy\prod\backend.env`.
3. Set the real PostgreSQL password.
4. Start production backend:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\internal-system\deploy\prod\start-backend.ps1
```

Then test:

```text
https://yeokjeon.com/#/login
```
