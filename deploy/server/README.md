# Windows server deployment

## Domain plan

- Field/development test: `on.yeokjeon.com`
- Production: `yeokjeon.com`
- Public server IP: `203.234.249.145`
- Current constraint: public `80/tcp` and `443/tcp` cannot be used by this server.

## Recommended access method

Use Cloudflare DNS proxy with an Origin Rule.

This keeps FortiGate inbound `80/443` untouched. Users access the service with normal HTTPS, and Cloudflare forwards `on.yeokjeon.com` traffic to the origin on port `8080`.

```text
https://on.yeokjeon.com/#/login
```

Do not create FortiGate VIPs for Y-ON `80` or `443`.
Do not expose PostgreSQL `5432` to the public internet.

## Runtime layout

- Field backend: `127.0.0.1:3001`, DB `yj_db_test`
- Production backend: `127.0.0.1:3011`, DB `yj_db_prod`
- Local field web gateway: `127.0.0.1:8080`
- Local production web gateway: `127.0.0.1:8180`
- Cloudflare Origin Rule routes `https://on.yeokjeon.com` to origin port `8080`.

## Field test account

현장 테스트 계정 ID는 `admin` 입니다. 비밀번호는 이 문서에 적지 않습니다 — 이 저장소와 배포 패키지는 서버 PC 에 그대로 놓이므로, 문서에 적힌 순간 서버에 접근 가능한 모두가 관리자 계정을 알게 됩니다.

초기 비밀번호는 `backend.env` 의 `DEFAULT_USER_PASSWORD`(미설정 시 `application.yml` 의 `auth.default-password` 기본값)로 정합니다. 값을 모르면 관리자에게 확인하세요. 틀린 값을 반복 입력하면 연속 실패 10회에서 계정이 10분간 잠깁니다(`LoginAttemptGuard`).

The test seed file `deploy\db\002_seed_test.sql` creates this account. The application treats `admin` as a super admin through `backend\src\main\resources\application.yml`.

## Kakao Maps domain settings

Add both domains to Kakao Developers > JavaScript SDK domain:

```text
https://on.yeokjeon.com
https://yeokjeon.com
```

## First setup for field test

1. Add `yeokjeon.com` to Cloudflare.
2. Change the WHOIS nameservers to the two nameservers Cloudflare gives you.
3. In Cloudflare DNS, add the field test record:

```text
Type: A
Name: on
IPv4 address: 203.234.249.145
Proxy status: Proxied
TTL: Auto
```

4. In Cloudflare, create an Origin Rule:

```text
Rules > Origin Rules > Create rule
Name: YON field test origin port
If incoming requests match: Hostname equals on.yeokjeon.com
Destination Port: Rewrite to 8080
```

5. In Cloudflare SSL/TLS, set encryption mode to `Flexible` for this field test setup, because the origin server listens with HTTP on port `8080`.

   주의(미해결): `Flexible` 은 Cloudflare→오리진 구간이 공인 인터넷을 평문 HTTP 로 지나갑니다. 로그인 비밀번호, Authorization 토큰(12시간 유효), 가맹점·점주 개인정보가 그 구간에서 읽힙니다. 현장 테스트 단계라 잠정 유지 중이며, 운영 전환 전에 오리진에 Cloudflare Origin CA 인증서를 붙이고 `Full (strict)` 로 올려야 합니다. 그때 `deploy\package\field-server\caddy\Caddyfile.http` 도 TLS 수신으로 함께 바꿔야 합니다.
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
flutter build web --no-pub --no-tree-shake-icons --pwa-strategy=none --dart-define=API_BASE_URL=https://on.yeokjeon.com/api --dart-define=KAKAO_MAP_JAVASCRIPT_KEY=3649c96a39bc8cff269119d8cffbe4e0
```

`--pwa-strategy=none` 과 `--no-tree-shake-icons` 는 빼면 안 됩니다. 이 절차가 `deploy\package\create-field-package.ps1` 과 갈라져 있어서, 예전에는 문서대로 빌드하면 서비스워커가 켜진 번들이 나갔습니다. 서비스워커가 한 번 잡히면 서버 파일은 새것인데 브라우저만 옛 앱 셸을 계속 실행해, 응답코드·Last-Modified 로는 배포 성공으로 보이는 형태로 배포가 실패합니다. 아이콘 쪽도 같은 이유입니다(트리셰이킹된 옛 부분폰트가 캐시되면 새 아이콘이 안 보임).

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
https://on.yeokjeon.com/#/login
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
