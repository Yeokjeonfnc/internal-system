# Windows server deployment

## Domain plan

- Field/development test: `test.yeokjeon.com`
- Production: `yeokjeon.com`
- Public server IP: `203.234.249.145`
- Current constraint: public `80/tcp` and `443/tcp` cannot be used by this server.

## Recommended access method

Use Cloudflare DNS proxy with an Origin Rule.

This keeps FortiGate inbound `80/443` untouched. Users access the service with normal HTTPS, and Cloudflare forwards `test.yeokjeon.com` traffic to the origin on port `8080`.

```text
https://test.yeokjeon.com/#/login
```

Do not create FortiGate VIPs for Y-ON `80` or `443`.
Do not expose PostgreSQL `5432` to the public internet.

## Runtime layout

- Field backend: `127.0.0.1:3001`, DB `yj_db_test`
- Production backend: `127.0.0.1:3011`, DB `yj_db_prod`
- Local field web gateway: `127.0.0.1:8080`
- Local production web gateway: `127.0.0.1:8180`
- Cloudflare Origin Rule routes `https://test.yeokjeon.com` to origin port `8080`.

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
3. In Cloudflare DNS, add the field test record:

```text
Type: A
Name: test
IPv4 address: 203.234.249.145
Proxy status: Proxied
TTL: Auto
```

4. In Cloudflare, create an Origin Rule:

```text
Rules > Origin Rules > Create rule
Name: YON field test origin port
If incoming requests match: Hostname equals test.yeokjeon.com
Destination Port: Rewrite to 8080
```

5. In Cloudflare SSL/TLS, set encryption mode to `Flexible` for this field test setup, because the origin server listens with HTTP on port `8080`.
6. On FortiGate, create only this VIP and policy:

```text
External: 203.234.249.145:8080
Internal: 192.168.30.30:8080
```

7. Install Java 17, PostgreSQL, Flutter build dependencies, and Caddy.
8. Build backend:

```powershell
cd C:\y-on\internal-system\backend
$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot'
$env:Path="$env:JAVA_HOME\bin;C:\tmp\apache-maven-3.9.16\bin;$env:Path"
mvn -DskipTests package
```

9. Build frontend:

```powershell
cd C:\y-on\internal-system\app_flutter
flutter build web --no-pub --dart-define=API_BASE_URL=https://test.yeokjeon.com/api --dart-define=KAKAO_MAP_JAVASCRIPT_KEY=3649c96a39bc8cff269119d8cffbe4e0
```

10. Create field backend env:

```powershell
Copy-Item C:\y-on\internal-system\deploy\field\backend.env.example C:\y-on\internal-system\deploy\field\backend.env
notepad C:\y-on\internal-system\deploy\field\backend.env
```

Set the real PostgreSQL password in `DB_PASSWORD`.

11. Start field backend and the local web gateway:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\internal-system\deploy\field\start-backend.ps1
powershell -ExecutionPolicy Bypass -File C:\y-on\internal-system\deploy\field\start-web.ps1
```

12. Test locally on the server:

```text
http://localhost:8080/#/login
```

13. Test from outside:

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
