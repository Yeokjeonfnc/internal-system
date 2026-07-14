# 역전 F&C ERP (Yeokjeon)

(주)역전에프앤씨 내부용 **가맹·창업·활동·마스터** 통합 ERP입니다.  
**Spring Boot REST API**(`backend`)와 **Flutter 웹/데스크톱 클라이언트**(`app_flutter`)로 구성된 모노레포입니다.

| 구분 | 설명 |
|------|------|
| 용도 | 가맹점·예비창업자·물건·활동(방문·결재)·사원/부서·체크리스트·대시보드 |
| 사용자 | 내부 직원 (SV, 본사 관리자 등) |
| 배포 형태 | 사내 전용 (`publish_to: none`, 외부 배포 비대상) |

---

## 목차

1. [저장소 구조](#1-저장소-구조)
2. [기술 스택](#2-기술-스택)
3. [사전 요구 사항](#3-사전-요구-사항)
4. [빠른 시작](#4-빠른-시작)
5. [실행 방법](#5-실행-방법)
6. [주요 기능·메뉴](#6-주요-기능메뉴)
7. [아키텍처](#7-아키텍처)
8. [API 개요](#8-api-개요)
9. [개발 규칙](#9-개발-규칙)
10. [CI·품질](#10-ci품질)
11. [문서·스크립트](#11-문서스크립트)
12. [보안·운영 주의](#12-보안운영-주의)

---

## 1. 저장소 구조

```
yeokjeon/
├── backend/                 # Spring Boot 3.2 + PostgreSQL + MyBatis/JPA
│   ├── src/main/java/     # com.yeokjeon.erp.*
│   └── src/main/resources/
│       ├── application.yml
│       └── mapper/          # MyBatis XML (도메인별 하위 폴더)
├── app_flutter/             # Flutter 클라이언트 (웹·Windows 우선)
│   └── lib/
│       ├── core/            # 테마, API, 라우터, 공통 위젯
│       └── pages/           # 화면 모듈 (메뉴 코드별 폴더)
├── docs/
│   └── ERP_PROJECT_GUIDE.md # 규칙·매핑·테이블 색인 (개발 시 필수 참고)
├── scripts/                 # 점검 스크립트 등
├── .github/workflows/ci.yml
├── run_flutter_web.bat      # Windows 웹 실행 (로컬 경로 기준)
└── README.md                # 본 문서
```

`flutter_sdk/`는 로컬 Flutter SDK 복사본일 수 있으며 **Git 추적 대상이 아닙니다** (`.gitignore`).

---

## 2. 기술 스택

### 백엔드 (`backend`)

| 항목 | 버전·도구 |
|------|-----------|
| Java | 17 |
| 프레임워크 | Spring Boot **3.2.5** |
| DB | **PostgreSQL** |
| ORM | Spring Data JPA (CUD·단건) |
| SQL | **MyBatis 3** (`mapper/**/*.xml`, 복잡 조회·집계) |
| 빌드 | Maven |
| API | REST JSON (`camelCase`), 컨텍스트 경로 `/api` |
| 기본 포트 | **3001** |

### 프론트엔드 (`app_flutter`)

| 항목 | 버전·도구 |
|------|-----------|
| Dart SDK | **^3.11.1** (Flutter stable 권장) |
| UI | Flutter Material 3, `google_fonts` (Noto Sans KR) |
| 상태 관리 | **flutter_riverpod** + 일부 `provider` (`AuthProvider`) |
| 라우팅 | **go_router** |
| HTTP | **dio** (`ApiClient` 싱글톤) |
| JSON | `json_annotation` + `json_serializable` |
| 대상 플랫폼 | **Chrome(웹)**, Windows 데스크톱 (Android/iOS 설정 포함) |

### 연동

- 클라이언트 기본 API URL: `http://localhost:3001/api` (`lib/core/api/api_client.dart`)
- 웹 앱 기본 포트: **3000** (`run_flutter_web.bat`, 점유 시 3001)

---

## 3. 사전 요구 사항

| 도구 | 용도 |
|------|------|
| **JDK 17** | 백엔드 빌드·실행 |
| **Maven 3.8+** | `backend` 테스트·패키징 |
| **PostgreSQL** | 운영 DB (`yeokjeon_db` 등, 스키마는 기존 DB 기준) |
| **Flutter stable** | `app_flutter` 빌드·실행 |
| **Chrome** | 웹 UI 개발 시 권장 |

---

## 4. 빠른 시작

### 4.1 데이터베이스

1. PostgreSQL에 데이터베이스 생성 (예: `yeokjeon_db`).
2. `backend/src/main/resources/application.yml`에서 접속 정보 설정.  
   **비밀번호·API 키는 저장소에 커밋하지 말고**, 로컬 전용 설정 또는 환경 변수로 분리하는 것을 권장합니다.

```yaml
# 예시 (값은 환경에 맞게 변경)
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/yeokjeon_db
    username: postgres
    password: ${DB_PASSWORD}
```

### 4.2 백엔드

```bash
cd backend
mvn spring-boot:run
```

- 헬스 확인: `http://localhost:3001/api/codes?grpCd=10` (공통코드)
- 프로필: `dev`(ddl-auto create-drop), `prod`(validate) — `application.yml` 하단 참고

### 4.3 Flutter 클라이언트

```bash
cd app_flutter
flutter pub get
cp dart_defines.local.example.json dart_defines.local.json   # Windows: copy dart_defines.local.example.json dart_defines.local.json
flutter run -d chrome --web-port 3000 --dart-define-from-file=dart_defines.local.json
```

`/sales-areas/search` 지도는 **`KAKAO_MAP_JAVASCRIPT_KEY`** 가 컴파일 시 필요합니다. 서버는 `flutter build web --dart-define=...` 로 포함되고, 로컬은 `dart_defines.local.json`(git 제외)으로 맞춥니다. 루트 `run_flutter_web.bat` 이 파일이 있으면 자동 적용합니다.

웹에서 `Too many active WebGL contexts` 가 나오면 **Chrome의 localhost 탭을 모두 닫은 뒤** 앱을 완전히 재실행하세요(Hot Restart만으로는 WebGL 컨텍스트가 남을 수 있음).

Windows에서는 저장소 루트의 `run_flutter_web.bat`을 사용할 수 있습니다.  
(스크립트 내 `PROJECT_DIR`, Puro/Flutter 경로는 **본인 PC 경로**에 맞게 수정하세요.)

### 4.4 로그인

- `POST /api/auth/login` — 앱 로그인 화면에서 사용
- 이후 목록·상세 API는 세션/헤더 정책에 따라 `AuthProvider`와 연동

---

## 5. 실행 방법

### 백엔드

| 명령 | 설명 |
|------|------|
| `mvn spring-boot:run` | 개발 서버 기동 (포트 3001) |
| `mvn test` | 단위·통합 테스트 (CI와 동일) |
| `mvn -DskipTests package` | JAR 패키징 |

### Flutter

| 명령 | 설명 |
|------|------|
| `flutter pub get` | 의존성 설치 |
| `flutter run -d chrome` | 웹 실행 |
| `flutter run -d windows` | Windows 데스크톱 |
| `dart analyze` | 정적 분석 (CI) |
| `dart run build_runner build --delete-conflicting-outputs` | `*.g.dart` 재생성 |

### 동시 기동 순서 (권장)

1. PostgreSQL 기동  
2. `backend` → `http://localhost:3001/api`  
3. `app_flutter` → `http://localhost:3000` (또는 3001)

---

## 6. 주요 기능·메뉴

사이드바·라우트·폴더명은 **메뉴 코드**로 맞춥니다 (`lib/core/menu/menu_codes.dart`).

| 메뉴 (UI) | 코드 | Flutter 경로 | 백엔드 도메인 |
|-----------|------|--------------|---------------|
| 대시보드 | `dsh001` | `pages/dashboard/dsh001/` | 알림·가맹·활동 요약 (화면에서 API 조합) |
| 가맹점 관리 | `str001` | `pages/franchise/str001/` | `franchise` — `/stores` |
| 예비창업자 | `dev001` | `pages/development/dev001/` | `development` — `/partners` |
| 물건 관리 | `dev002` | `pages/development/dev002/` | `/properties` |
| 영업지역 | `dev003` | `pages/development/dev003/` | `/sales-areas` |
| 활동현황 | `act001` | `pages/active/act001/` | `/activities/status/*` |
| 활동관리 | `act002` | `pages/active/act002/` | `/activities/list/*`, 등록·수정 |
| 활동관리결재 | `act003` | `pages/active/act003/` | 결재·알림·지시사항 |
| 사원·부서·권한·체크리스트 | `mst001`~`mst004` | `pages/master/` | `master`, `active`(체크리스트) |

**활동 허브**는 `activity_hub_view.dart`, 경로 상수는 `pages/active/shared/activity_routes.dart`를 참고합니다.

### 대시보드 (`dsh001`)

- 최근 결재 알림, 이번 달 가맹점 지표, 결재 대기 활동, 달력
- 다크 톤 KPI 카드 UI (`dsh001_screen.dart`)

### 활동 (`active`)

- **현황**: 담당자별·가맹점별 기간별 방문/활동 수 피벗
- **관리**: 방문 등록, 임시보관, 체크리스트, 가맹점별 이력
- **결재**: PENDING/APPROVED, 알림(`notif_mst`), 다인 결재선(CSV `appr_id`)

### 가맹점 (`franchise`)

- 목록·검색·상세 탭·등록, 변경 이력(`store_history`)
- 브랜드·지역·상태 등 공통코드(`code_mst`) 연동

---

## 7. 아키텍처

### 7.1 백엔드 패키지

```
com.yeokjeon.erp
├── active      # 활동·체크리스트·알림 (ActController, ActMstMapper)
├── franchise   # 가맹점 (StrController, StoreMstMapper)
├── development # 창업자·물건·지오코딩 (DevController)
├── master      # 사원·부서 (MstController)
├── auth        # 로그인·프로필 (AuthController)
└── common      # 공통코드 (CommonCodeController)
```

**역할 분리**

| 작업 | 담당 |
|------|------|
| 목록·집계·복잡 JOIN | MyBatis XML |
| 단건 조회·INSERT/UPDATE/DELETE | JPA Repository + Entity |
| 비즈니스 규칙 | `*Service` |
| HTTP 입출력 | `*Controller` + DTO |

### 7.2 Flutter 레이어

```
lib/
├── main.dart              # ProviderScope + MaterialApp.router
├── core/
│   ├── api/               # ApiClient, Dio
│   ├── auth/              # 로그인·AuthProvider
│   ├── router/            # go_router 정의
│   ├── theme/             # AppTheme, AppDimensions
│   ├── widgets/common/    # ListPageTemplate, ErpDataTable, 필터 패널
│   └── {domain}_mst/      # API JSON 키·경로·write_request
└── pages/{domain}/{code}/ # *_view, *_api, *_model, *_provider
```

**화면 파일 접미사**

| 접미사 | 역할 |
|--------|------|
| `*_view.dart` | UI 위젯 트리 |
| `*_api.dart` | REST 호출 |
| `*_model.dart` / `*.g.dart` | DTO |
| `*_provider.dart` / `*_controller.dart` | Riverpod 상태 |
| `*_filter.dart` | 목록 필터 모델 |

다이얼로그는 `pages/{active|development|master}/dialogs/`에 둡니다.

### 7.3 목록 화면 공통 UI

가맹점·활동 등 **목록/검색/테이블** 화면은 아래를 재사용합니다 (임의 레이아웃·`textScaler` 조작 금지).

- `ListPageTemplate`
- `SearchFilterStackedItems` + `CommonSearchFieldId`
- `ErpDataTable` + `ErpTableHeaderCell` / `ErpTableBodyCell`
- 참고 구현: `str001_view.dart`, `act002_view_manage.dart`

상세 규칙: `.cursor/rules/flutter-erp-ui-consistency.mdc`

---

## 8. API 개요

모든 경로는 **`/api` 접두사** 아래입니다 (`server.servlet.context-path`).

| 영역 | 대표 경로 |
|------|-----------|
| 인증 | `POST /auth/login`, `GET /auth/profile` |
| 공통코드 | `GET /codes?grpCd=` |
| 가맹점 | `GET/POST/PUT/DELETE /stores`, `GET /stores/{storeIdx}/histories` |
| 창업자 | `/partners` |
| 물건 | `/properties` |
| 활동 목록 | `GET /activities/list/all`, `.../by-store`, `.../by-status` 등 |
| 활동 현황 | `GET /activities/status/by-store`, `.../by-assignee` |
| 활동 CUD | `GET/POST/PUT /activities/{actIdx}` |
| 체크리스트 | `GET /checklists`, 마스터 CRUD |
| 알림 | `GET /notifications`, `GET /notifications/unread-count` |
| 사원·부서 | `GET /users`, `GET /dept/list` |

응답 래퍼·에러 형식은 `ApiResponse` 패턴을 따릅니다.  
활동 목록 HTTP ↔ `ActService` 매핑 전체는 `docs/ERP_PROJECT_GUIDE.md` §8을 참고하세요.

---

## 9. 개발 규칙

### 9.1 네이밍·데이터

| 계층 | 규칙 |
|------|------|
| DB 컬럼 | `snake_case` |
| REST JSON | `camelCase` (DTO 기준) |
| Dart | `*ApiJsonKeys`에 키 집약, 화면은 모델 우선 참조 |
| Java 서비스 | `list*`, `one`, `create`, `update`, `remove` |
| Dart API | `fetch*` + 목적 (`fetchDraftRows` 등) |

### 9.2 새 화면 추가 시

1. `menu_codes.dart`와 폴더 `pages/.../{code}/` 생성  
2. `app_router.dart`에 `AppRouteDef` 등록  
3. 목록이면 `ListPageTemplate` + 공통 필터/테이블 패턴 준수  
4. 백엔드는 Controller → Service → Mapper/Repository 경로 유지  
5. `dart analyze` 및 `mvn test` 통과 확인  

### 9.3 JSON 코드 생성 (Flutter)

```bash
cd app_flutter
dart run build_runner build --delete-conflicting-outputs
```

---

## 10. CI·품질

GitHub Actions (`.github/workflows/ci.yml`):

| Job | 작업 |
|-----|------|
| `backend` | `mvn -B test` (Java 17) |
| `flutter` | `flutter pub get` → `dart analyze` |

로컬에서 PR 전 동일 명령 실행을 권장합니다.

---

## 11. 문서·스크립트

| 경로 | 내용 |
|------|------|
| [`docs/ERP_PROJECT_GUIDE.md`](docs/ERP_PROJECT_GUIDE.md) | **핵심** — 테이블↔엔티티, Mapper XML 목록, 활동 API 매핑, 회귀 체크리스트 |
| [`app_flutter/README.md`](app_flutter/README.md) | Flutter 클라이언트 전용 요약 |
| [`.cursor/rules/flutter-erp-ui-consistency.mdc`](.cursor/rules/flutter-erp-ui-consistency.mdc) | UI 통일 규칙 (에이전트·개발자 공통) |
| [`scripts/check_list_page_template.ps1`](scripts/check_list_page_template.ps1) | 목록 셸(`ListPageTemplate`) 사용 점검 |

---

## 12. 보안·운영 주의

- **내부 전용** 소프트웨어입니다. 저장소·이슈에 DB 비밀번호, Kakao REST API 키 등을 올리지 마세요.
- `application.yml`의 민감 값은 `spring.config.import`, 환경 변수, 또는 **gitignore된** `application-local.yml`로 분리하는 것을 권장합니다.
- `dev` 프로필의 `ddl-auto: create-drop`은 **개발 DB 전용**입니다. 운영 DB에 사용하지 마세요.
- 활동 데이터의 `store_idx`는 유효한 가맹점(>0)만 허용합니다. 레거시 `0` 데이터는 DB에서 정정이 필요할 수 있습니다.

---

## 라이선스

(주)역전에프앤씨 **내부 전용** 프로젝트입니다. 무단 복제·외부 배포를 금합니다.

---

## 문의·이슈

기능·버그·DB 이슈는 팀 내부 이슈 트래커 또는 담당 개발자에게 문의하세요.  
아키텍처·매핑 변경 시 **`docs/ERP_PROJECT_GUIDE.md`를 함께 갱신**해 주세요.
