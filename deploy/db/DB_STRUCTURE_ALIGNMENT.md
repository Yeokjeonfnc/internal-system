# DB Structure Alignment

기준 파일:

```text
C:\y-on\DB_구조.xlsx
```

Git 기준 DB 파일:

```text
deploy\db\001_schema.sql
deploy\db\002_seed_test.sql
deploy\db\003_store_mst_real_stores.sql
```

## 기준

`DB_구조.xlsx`에는 아래 기본 테이블이 정의되어 있습니다.

```text
store_mst
active_mst
chk_mst
chk_result_dtl
code_mst
user_mst
dept_mst
notif_mst
partner_mst
property_mst
sale_zone_mst
store_history
```

`DB_구조.xlsx`에는 앱 실행에 필요한 확장 테이블도 함께 반영했습니다.

## App Extensions

현재 앱 권한/메뉴 동작에 필요한 테이블입니다.

```text
menu_mst
user_menu_auth
```

화면 정렬과 공통 코드 관리에 필요한 추가 컬럼입니다.

```text
code_mst.sort_order
```

## Applied Adjustments

엑셀 기준과 맞추기 위해 아래 컬럼을 `dept_mst`에 반영했습니다.

```text
dept_type
use_yn
create_dt
```

`002_seed_test.sql`의 기본 부서 데이터도 위 컬럼을 포함하도록 맞췄습니다.

이미 생성된 DB를 초기화하지 않고 보정할 수 있도록 아래 마이그레이션도 추가했습니다.

```text
deploy\db\migrations\20260529_align_dept_mst_with_db_structure.sql
```

## Normalized Names

기존 엑셀에는 `sale_zone_mst.creadted_at`으로 적혀 있었으나 오탈자로 판단하여 `created_at`으로 수정했습니다.

```text
Before: creadted_at
After:  created_at
```

## Real Store Data

실제 매장 데이터는 `003_store_mst_real_stores.sql`에 분리했습니다.

- 기준 원본: `C:\y-on\매장정보.xlsx`
- 대상 테이블: `store_mst`
- 적용 방식: `store_mst`만 `TRUNCATE` 후 1,038건 삽입

적용 스크립트:

```text
deploy\package\field-server\scripts\apply-real-stores.ps1
```
