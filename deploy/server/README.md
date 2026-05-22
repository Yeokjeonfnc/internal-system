# Windows server deployment

## Domain plan

- Field/development test: `test.yeokjeon.com`
- Production: `yeokjeon.com`
- Public server IP: `203.234.249.145`
- Current constraint: public `80/tcp` and `443/tcp` cannot be used by this server.

## Recommended access method

Use Cloudflare Tunnel.

This keeps FortiGate inbound `80/443` untouched. The Windows server opens an outbound tunnel to Cloudflare, and users still access the service with normal HTTPS:

```text
https://test.yeokjeon.com/#/login
https://yeokjeon.com/#/login
```

Do not create FortiGate VIPs for Y-ON `80` or `443`.
Do not expose PostgreSQL `5432` to the public internet.

## Runtime layout

- Field backend: `127.0.0.1:3001`, DB `yj_db_test`
- Production backend: `127.0.0.1:3011`, DB `yj_db_prod`
- Local field web gateway: `127.0.0.1:8080`
- Local production web gateway: `127.0.0.1:8180`
- Cloudflare Tunnel routes public HTTPS hostnames to the local web gateways.

## Field test account

Use this account for field testing:

```text
ID: admin
PW: admin123
```

The test seed file `deploy\db\002_seed_test.sql` creates this account. The application treats `admin` as a super admin through `backend\src\main\resources\application.yml`.

## Kakao Maps domain settings

Add both domains to Kakao Developers > JavaScript SDK domain:

```text
https://test.yeokjeon.com
https://yeokjeon.com
```

## First setup for field test

1. Add `yeokjeon.com` to Cloudflare.
2. Change the WHOIS nameservers to the two nameservers Cloudflare gives you.
3. In Cloudflare Zero Trust, create a Cloudflare Tunnel for the Windows server.
4. Install `cloudflared` as a Windows service with the token shown by Cloudflare.
5. Add a Public Hostname:

```text
Hostname: test.yeokjeon.com
Service:  http://localhost:8080
```

Later, for production, add:

```text
Hostname: yeokjeon.com
Service:  http://localhost:8180
```

6. Install Java 17, PostgreSQL, Flutter build dependencies, Caddy, and cloudflared.
7. Build backend:

```powershell
cd C:\y-on\internal-system\backend
$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot'
$env:Path="$env:JAVA_HOME\bin;C:\tmp\apache-maven-3.9.16\bin;$env:Path"
mvn -DskipTests package
```

8. Build frontend:

```powershell
cd C:\y-on\internal-system\app_flutter
flutter build web --no-pub --dart-define=KAKAO_MAP_JAVASCRIPT_KEY=3649c96a39bc8cff269119d8cffbe4e0
```

9. Create field backend env:

```powershell
Copy-Item C:\y-on\internal-system\deploy\field\backend.env.example C:\y-on\internal-system\deploy\field\backend.env
notepad C:\y-on\internal-system\deploy\field\backend.env
```

Set the real PostgreSQL password in `DB_PASSWORD`.

10. Start field backend and the local tunnel gateway:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\internal-system\deploy\field\start-backend.ps1
powershell -ExecutionPolicy Bypass -File C:\y-on\internal-system\deploy\server\start-caddy-tunnel.ps1
```

11. Test locally on the server:

```text
http://localhost:8080/#/login
```

12. Test from outside:

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
