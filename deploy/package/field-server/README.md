# Y-ON field server package

This package contains only runtime files. It does not require the full Git repository.

## Layout

```text
backend\erp-backend-1.0.0.jar
web\
config\backend.env.example
scripts\
logs\
```

## First run on the server PC

Unzip this package to:

```text
C:\y-on\yon-field-server
```

Create the backend config:

```powershell
Copy-Item C:\y-on\yon-field-server\config\backend.env.example C:\y-on\yon-field-server\config\backend.env
notepad C:\y-on\yon-field-server\config\backend.env
```

Set the real PostgreSQL password:

```text
DB_PASSWORD=CHANGE_ME
```

Open Windows firewall for local field web gateway:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\install-firewall-rule.ps1
```

Start the server:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\start-all.ps1
```

Stop the server:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\stop-all.ps1
```

Health check:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\health-check.ps1
```

## URLs

Local server check:

```text
http://localhost:8080/#/login
```

External field test:

```text
https://test.yeokjeon.com/#/login
```

## Field test account

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

FortiGate:

```text
203.234.249.145:8080 -> 192.168.30.30:8080
```

Kakao Developers JavaScript SDK domain:

```text
https://test.yeokjeon.com
```
