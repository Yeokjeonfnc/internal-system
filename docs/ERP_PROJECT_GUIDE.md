# 역전 ERP — 규칙·매핑 한 장

갱신: 2026-05-11. **이 파일이** 백엔드·Flutter 공통의 **고정 규칙·도메인 매핑·영속 경로** 집약본이다. (과거 `docs/refactoring/*`, `REFACTOR_CHECKLIST.md`, `app_flutter/docs/ARCHITECTURE_GUIDE.md` 등은 제거됨.)

---

## 1. 고정 의사결정

| 항목 | 규칙 |
|------|------|
| DB 컬럼 | `snake_case`. 엔티티는 `@Column(name = "...")`로 고정. |
| REST JSON | DTO 필드 기준 `camelCase`. 레거시 오타(예: `adressDetail`)는 **API·앱이 동일하게** 유지할 때만 예외. |
| Dart | `@JsonKey(name: …)` 또는 `*ApiJsonKeys` / `jsonKey*`로 백엔드 키와 정렬. 화면(`*_view`)은 가능한 한 **모델만** 참조. |
| 조회 SQL | **MyBatis** `mapper/**/*.xml` + `@Mapper` 인터페이스. 서비스에 `JdbcTemplate`/인라인 SQL 없음. |
| CUD·단건 | Spring Data JPA Repository + 엔티티(목록·집계·복잡 조인은 MyBatis). |
| PostgreSQL `TIMESTAMPTZ` | MyBatis `LocalDateTime` 매핑 시 XML에서 `CAST(... AS TIMESTAMP)` 또는 `databaseId="postgresql"` 분기(`AT TIME ZONE` 등). |
| Flutter UI(목록·필터·테이블·상세) | `.cursor/rules/flutter-erp-ui-consistency.mdc` — `ListPageTemplate`, `AppDimensions`, `SearchFilterStackedItems`, `ErpDataTable` 등 **공통 위젯·토큰** 재사용. 화면별 `textScaler` 덮어쓰기 금지. |

---

## 2. 네이밍 (요약)

**Java:** 서비스 공개 메서드 `list…`, `one`, `create`, `update`, `remove`, 목적형 `listByStore` 등. Repository는 `findBy…` 파생 유지, 비즈니스 의미는 서비스명으로.

**HTTP:** 동작이 경로에서 읽히게 (`GET /activities/list/by-store` 등). 레거시 단일 `GET /activities?…` 분기 엔드포인트는 제거 — 앱은 `/activities/list/*`만 사용.

**Dart:** API는 `fetch` + 목적(`fetchDraftRows`, …). JSON 문자열 키는 `*ApiJsonKeys` / `jsonKey*` 한곳에 모음.

---

## 3. 백엔드 패키지 (`com.yeokjeon.erp.*`)

| 그룹 | 책임 | 진입 |
|------|------|------|
| **active** | 활동·체크리스트·알림 | `ActController` — `/activities`, `/checklists`, `/notifications`; `ActService`; `mapper/ActMstMapper` + `mapper/active/ActMstMapper.xml`; `ActRepository`, `ActNotifRepository`; `entity`(`ActActive`, `ActNotif` 등) |
| **development** | 창업자·물건·지오코딩 | `DevController` — `/partners`, `/properties`; `DevService`, `AddressGeocodingService`; `DevMstMapper` + `mapper/development/DevMstMapper.xml`; `PartnerRepository`, `PropertyRepository` |
| **master** | 사원·부서 | `MstController`; `MstService`; `DeptMstMapper` + `mapper/master/DeptMstMapper.xml`, `MstUserMapper` + `mapper/master/MstUserMapper.xml`; `MstUserRepository` |
| **franchise** | 가맹점 | `StrController`; `StrService`; `StoreMstMapper` + `mapper/franchise/StoreMstMapper.xml`, `StoreHistoryMapper` + `StoreHistoryMapper.xml`; `StoreRepository` |
| **common** | 공통코드 | `CommonCodeController`, `CommonCodeService`, `CodeMstMapper` + `mapper/common/CodeMstMapper.xml` |
| **auth** | 인증 | `AuthController`, `AuthService`, `AuthProfileMapper` + `mapper/auth/AuthProfileMapper.xml` |

---

## 4. Flutter — 메뉴 코드 ↔ 폴더

| 메뉴 | 코드 | 위치 |
|------|------|------|
| 활동현황 | `act001` | `lib/pages/active/act001/` + 공용 `lib/pages/active/activity_*.dart`, `activity_hub_view.dart` |
| 활동관리 | `act002` | `lib/pages/active/act002/`; 다이얼로그 `lib/pages/active/dialogs/` |
| 활동관리결재 | `act003` | `lib/pages/active/act003/`; 탭·경로 `activity_routes.dart`, `app_router` |
| 가맹점 | `str001` | `lib/pages/franchise/str001/` |
| 창업자 / 물건 / 기타 | `dev001` `dev002` `mst001`–`mst004` `dev003` | `lib/pages/development/`, `lib/pages/master/`; 조회 다이얼로그는 각 그룹 `dialogs/` |
| 대시보드 | `dsh001` | `lib/pages/dashboard/dsh001/` |

**파일 접미사:** `*_view.dart` 화면, `*_api.dart` HTTP, `*_model.dart` / `*.g.dart`, `*_provider.dart` / `*_controller.dart`. **다이얼로그**는 메뉴 폴더 안이 아니라 **`pages/{active|development|master}/dialogs/`**.

**활동 라우트 상수(앱 셸·라우터):** `package:app_flutter/pages/active/activity_routes.dart`.

---

## 5. 도메인 ↔ DTO·Dart 키 파일 (색인)

| 도메인 | 백엔드 | Dart |
|--------|--------|------|
| 활동 `act001`–`act003` | `active/dto/*`, `ActService`, `ActMstMapper.xml` | `core/active_mst/active_mst_api_json_keys.dart`, `active_mst_api_paths.dart` |
| 체크리스트 마스터 | `ChkMstResponseDto`, `ChkMstWriteRequestDto` | `core/checklist/chk_mst_api_json_keys.dart` |
| 알림 | `NotifMstDto` | `core/notifications/notif_mst_api_json_keys.dart`, `notif_api_paths.dart` |
| 가맹점 | `StoreMstDto`, `StrService`, Store/History Mapper | `core/store_mst/*` |
| 창업자 / 물건 | `PartnerMstDto`, `PropertyMstDto`, `DevService` | `core/partner_mst/*`, `core/property_mst/*` |
| 사원 / 부서 | `UserMstDto`, `MstService`, MstUser/Dept Mapper | `core/user_mst/*`, `core/dept/*` |
| 공통코드 | `CodeMstDto`, `CommonCodeService` | `core/api/code_option.dart`(`CodeMstApiJsonKeys`) |
| 인증 | `AuthProfileDto`, `AuthService` | `core/auth/*` |
| 대시보드 KPI | 백엔드 KPI DTO | `pages/dashboard/dsh001/dsh001_kpi_json_keys.dart` |

저장 본문·payload 색인은 위 `lib/core/**`의 `*_write_payload.dart`, `*_api_json_keys.dart`가 진실.

---

## 6. 핵심 테이블 ↔ 영속

| DB 테이블 | Java 엔티티(주) | 조회(MyBatis) | CUD·단건(JPA 등) |
|-----------|-----------------|----------------|-------------------|
| `active_mst` | `ActActive` | `ActMstMapper` | `ActRepository` |
| `notif_mst` | `ActNotif` | `ActMstMapper`(목록·미읽음·결재일·`appr_yn` UPDATE) | `ActNotifRepository` |
| `chk_mst` / `chk_result_dtl` | — | `ActMstMapper` | `ActService` 트랜잭션 |
| `store_mst` | `Store` | `StoreMstMapper` | `StoreRepository` |
| `store_history` | JDBC/DTO 행 | `StoreHistoryMapper` | `StrService` + `EntityManager` |
| `partner_mst` / `property_mst` | `Partner` / `Property` | `DevMstMapper` | 각 Repository |
| `user_mst` | `MstUser` | `MstUserMapper`, `AuthProfileMapper` | `MstUserRepository` |
| `dept_mst` | DTO 위주 | `DeptMstMapper` | `MstService` |
| `code_mst` | (엔티티 없음) | `CodeMstMapper` | `CommonCodeService` |

---

## 7. MyBatis Mapper 한눈에

| Mapper 인터페이스 | XML |
|-------------------|-----|
| `common.mapper.CodeMstMapper` | `mapper/common/CodeMstMapper.xml` |
| `auth.mapper.AuthProfileMapper` | `mapper/auth/AuthProfileMapper.xml` |
| `master.mapper.DeptMstMapper` | `mapper/master/DeptMstMapper.xml` |
| `master.mapper.MstUserMapper` | `mapper/master/MstUserMapper.xml` |
| `franchise.mapper.StoreMstMapper` | `mapper/franchise/StoreMstMapper.xml` |
| `franchise.mapper.StoreHistoryMapper` | `mapper/franchise/StoreHistoryMapper.xml` |
| `active.mapper.ActMstMapper` | `mapper/active/ActMstMapper.xml` |
| `development.mapper.DevMstMapper` | `mapper/development/DevMstMapper.xml` |

---

## 8. 활동 목록 HTTP → `ActService`

| `GET` 경로 | 메서드 |
|------------|--------|
| `/activities/list/all` | `listAll` |
| `/activities/list/by-store` | `listByStore` |
| `/activities/list/by-appr-note` | `listBySvAppr` |
| `/activities/list/by-suggestions` | `listBySuggestions` |
| `/activities/list/by-check` | `listByChkYn` |
| `/activities/list/by-status` | `listByStatus` |

상세·단건·체크·CUD·알림 등 나머지 HTTP 매핑은 `ActController` ↔ `ActService` 소스와 `ActMstMapper.xml`을 본다.

---

## 9. CI·스크립트

- **CI:** `.github/workflows/ci.yml` — `mvn test`, `dart analyze`(또는 프로젝트와 동일 명령).
- **목록 화면 셸 점검:** `scripts/check_list_page_template.ps1` — 예외 패턴은 스크립트 내 주석·본 문서 §4와 맞출 것.

---

## 10. 최소 회귀(수동, DB·앱 기동 후)

**API:** `GET /api/codes?grpCd=…`, `POST /api/auth/login`, `GET /api/stores`, `GET /api/activities/list/all`(또는 메뉴에서 쓰는 list 경로), `GET /api/users`.

**Flutter:** 가맹점 목록·필터, 활동관리 임시보관/등록 탭 조회, 공통코드 드롭다운, 사원 목록.

실패 시 **§3·§6·§8**과 해당 Mapper XML에서 HTTP → 서비스 → SQL 경로를 추적한다.
