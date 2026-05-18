# 메뉴 권한 DB

PostgreSQL `yeokjeon_db` 에 순서대로 적용한다.

```bash
psql -U postgres -d yeokjeon_db -f 01_schema.sql
psql -U postgres -d yeokjeon_db -f 02_seed_menu_mst.sql
psql -U postgres -d yeokjeon_db -f 03_grant_all_to_admin.sql   # 선택
```

- `menu.permission.super-admin-user-ids` 에 등록된 ID(기본 `admin`)는 DB 행 없이도 전 메뉴 허용.
- 그 외 사용자는 `user_menu_auth` 리프 메뉴별 **조회·등록·수정·삭제** 플래그로 제어된다.
  - **조회** → 사이드바·화면 진입
  - **등록** → 목록 `+` 등록, `/new`·`/register` 경로
  - **수정** → 상세 **수정·저장** 버튼
  - **삭제** → 목록 삭제 버튼
- 로그인 응답 `menuPermissions` 에 네 가지 권한이 포함된다.
