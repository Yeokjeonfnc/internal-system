# Deployment Layout

이 폴더는 서버/DB 구성을 Git에서 재현하기 위한 기준입니다.

## Active Folders

```text
deploy
├─ db
│  ├─ 001_schema.sql
│  ├─ 002_seed_test.sql
│  ├─ 003_store_mst_real_stores.sql
│  ├─ DB_STRUCTURE_ALIGNMENT.md
│  ├─ DB_구조.xlsx
│  ├─ migrations
│  └─ README.md
└─ package
   ├─ create-field-package.ps1
   └─ field-server
      ├─ backend
      ├─ web
      ├─ config
      ├─ db
      ├─ caddy
      ├─ scripts
      └─ README.md
```

- `deploy\db`: DB 구조, 기본 테스트 데이터, 실제 매장 데이터 기준 파일입니다.
- `deploy\package\create-field-package.ps1`: 백엔드 JAR와 Flutter Web 빌드 결과를 서버 배포 ZIP으로 묶습니다.
- `deploy\package\field-server`: 서버 PC에 배포되는 실행 패키지 템플릿입니다.

## Server Package Flow

개발 PC에서:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\internal-system\deploy\package\create-field-package.ps1 -Build
```

결과:

```text
C:\y-on\release\yon-field-server-YYYYMMDD-HHMMSS.zip
```

서버 PC에서:

```text
C:\y-on\yon-field-server
```

위 경로에 압축을 풀고 `config\backend.env`를 서버 환경에 맞게 생성합니다.

## Database Flow

초기 DB:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\init-db.ps1 -DbPort 5433
```

실제 매장 데이터:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\apply-real-stores.ps1 -StopApp
```

## Do Not Commit

아래 파일은 Git에 올리지 않습니다.

```text
*.env
logs\
*.log
*.pid
*.dump
*.backup
```

특히 아래 파일은 서버 PC 로컬 파일입니다.

```text
C:\y-on\yon-field-server\config\backend.env
```

비밀번호는 `backend.env.example`에 넣지 않고 `CHANGE_ME` 형태로만 관리합니다.

## Data Warning

`deploy\db\003_store_mst_real_stores.sql`은 실제 매장 정보를 포함합니다. 공개 GitHub 저장소에는 올리면 안 됩니다. 사내 비공개 저장소에서만 관리하세요.
