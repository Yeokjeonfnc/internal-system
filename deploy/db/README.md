# DB Scripts

이 폴더는 Git에서 관리하는 DB 재현 기준입니다. 서버 PC의 실제 DB 비밀번호, 로컬 `backend.env`, 로그, dump 파일은 이 폴더에 넣지 않습니다.

## Files

```text
001_schema.sql
002_seed_test.sql
003_store_mst_real_stores.sql
DB_STRUCTURE_ALIGNMENT.md
DB_구조.xlsx
migrations\
README.md
```

- `001_schema.sql`: 빈 DB에 테이블, 시퀀스, 인덱스, 제약조건을 생성합니다.
- `002_seed_test.sql`: 테스트계 기본 데이터입니다. 로그인 계정 `admin / admin123`, 공통 코드, 사용자/부서 기본값을 포함합니다.
- `003_store_mst_real_stores.sql`: `매장정보.xlsx` 기준 실제 매장 데이터입니다. `store_mst`만 비우고 1,038건으로 교체합니다.
- `DB_STRUCTURE_ALIGNMENT.md`: `C:\y-on\DB_구조.xlsx`와 Git 기준 DB 파일의 정렬 기준 및 예외 사항입니다.
- `DB_구조.xlsx`: DB 설계 기준 엑셀 파일입니다.
- `migrations\`: 이미 만들어진 DB를 초기화하지 않고 보정할 때 쓰는 변경 SQL입니다.

## Apply Order

새 테스트 DB를 만들 때는 아래 순서로 적용합니다.

```text
1. 001_schema.sql
2. 002_seed_test.sql
3. 003_store_mst_real_stores.sql
```

`001_schema.sql`, `002_seed_test.sql`은 서버 패키지의 `scripts\init-db.ps1`에서 자동 적용합니다. 실제 매장 데이터는 서버 패키지의 `scripts\apply-real-stores.ps1`로 별도 적용합니다.

## Server Commands

서버 패키지 기준 경로:

```text
C:\y-on\yon-field-server
```

DB 초기화:

```powershell
powershell -ExecutionPolicy Bypass -File C:\y-on\yon-field-server\scripts\init-db.ps1 -DbPort 5433
```

실제 매장 데이터 적용:

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

이미 생성된 테스트 DB에 엑셀 기준 보정만 추가하려면 아래 마이그레이션을 적용합니다.

```powershell
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" `
  -h 127.0.0.1 `
  -p 5433 `
  -U postgres `
  -d yj_db_test `
  -v ON_ERROR_STOP=1 `
  -f C:\y-on\yon-field-server\db\migrations\20260529_align_dept_mst_with_db_structure.sql
```

## Notes

- 운영계 DB 이름은 향후 `yj_db_prod`를 사용합니다.
- 테스트계 DB 이름은 `yj_db_test`를 사용합니다.
- 실제 DB 비밀번호는 Git에 올리지 않습니다.
- `003_store_mst_real_stores.sql`은 실제 매장 정보가 포함된 데이터 파일입니다. 공개 저장소에는 올리지 말고, 사내 비공개 저장소에서만 관리해야 합니다.
