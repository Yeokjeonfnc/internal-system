# Test Environment

This folder contains local test-environment configuration.

- Test DB: `yj_db_test`
- Future production DB name: `yj_db_prod`
- Backend port: `3001`
- Frontend port: `3000`

Folder meaning:

- `deploy\db`: shared database scripts. This is not production itself.
- `deploy\test`: test-environment scripts and settings.
- `deploy\prod`: production-environment scripts and settings, to be added later.

Initialize the test DB:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\internal-system\deploy\test\init-db.ps1
```

Start the test backend:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\internal-system\deploy\test\start-backend.ps1
```

Stop the test backend:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\internal-system\deploy\test\stop-backend.ps1
```

Login accounts seeded for test:

- `admin / admin123`
- `admim / admin123`
- `svtest / admin123`
- `mgrtest / admin123`

