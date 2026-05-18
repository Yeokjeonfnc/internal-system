# 역전 F&C — Flutter ERP 클라이언트 (`app_flutter`)

> 저장소 전체 개요·백엔드·DB·실행 방법은 **[루트 `README.md`](../README.md)** 를 참고하세요.

(주)역전에프앤씨 내부용 ERP의 **웹·데스크톱 우선** Flutter 애플리케이션입니다. Spring Boot 백엔드 REST API와 통신하며, 대시보드·가맹점·창업자·물건·활동·마스터 등 메뉴를 제공합니다.

저장소 전체 규칙·도메인 매핑·백엔드 패키지 대응은 **[`docs/ERP_PROJECT_GUIDE.md`](../docs/ERP_PROJECT_GUIDE.md)** 를 기준으로 합니다.

---

## 1. 기술 스택

| 구분 | 내용 |
|------|------|
| 언어 / SDK | Dart **^3.11.1** (Flutter stable 권장) |
| UI | Flutter Material 3, `google_fonts` |
| 상태·DI | **flutter_riverpod** (`Notifier` / `FutureProvider` 등) |
| 라우팅 | **go_router** (`MaterialApp.router`, `app_router.dart`) |
| HTTP | **dio** (`ApiClient`, `BaseRepository` 패턴) |
| JSON | **json_annotation** + **json_serializable** (`*.g.dart` 생성) |
| 인증 UI 연동 | `provider` 패키지의 `ChangeNotifierProvider` + `AuthProvider` (기존 레이어와 병행) |

---

## 2. 저장소에서의 위치

```
yeokjeon/
├── backend/              # Spring Boot API
├── app_flutter/          # 본 프로젝트 (이 README)
├── docs/
│   └── ERP_PROJECT_GUIDE.md
└── .github/workflows/ci.yml
```

CI(`.github/workflows/ci.yml`)는 `backend` Maven 테스트와 `app_flutter`의 **`dart analyze`** 를 실행합니다.

---

## 3. 아키텍처 개요

### 3.1 디렉터리 역할

| 경로 | 역할 |
|------|------|
| `lib/main.dart` | `ProviderScope` + `MaterialApp.router` 진입 |
| `lib/core/` | 공통 테마·라우터·API·레이아웃·위젯·도메인별 `*_api_json_keys` / `*_write_request` |
| `lib/pages/` | 화면별 기능 모듈 (도메인 하위 폴더) |
| `lib/pages/active/` | 활동 허브·`act001`~`act003`·공용 `activity_*.dart` |
| `lib/pages/franchise/str001/` | 가맹점 목록·상세·등록 |
| `lib/pages/development/` | 창업자(`dev001`)·물건(`dev002`)·기타(`dev003`) |
| `lib/pages/master/` | 사원·부서·메뉴권한·체크리스트 마스터 등 |
| `lib/pages/dashboard/dsh001/` | 대시보드 KPI·요약 카드 |

### 3.2 화면 모듈 네이밍 (메뉴별)

| 접미사 | 용도 |
|--------|------|
| `*_view.dart` | 화면·위젯 트리 |
| `*_controller.dart` / `*_provider.dart` | Riverpod Provider·Notifier (목록+필터는 `BaseListNotifier` 패턴) |
| `*_api.dart` | Dio 호출·엔드포인트 |
| `*_model.dart` / `*.g.dart` | DTO 역직렬화 |
| `*_filter.dart` | 목록 필터 상태 모델 |

다이얼로그는 `pages/{active|development|master}/dialogs/` 등 메뉴 그룹별 `dialogs/` 에 둡니다.

### 3.3 목록 화면 공통 패턴

- **셸**: `ListPageTemplate` (`core/widgets/common/common_list_page_template.dart`)
- **필터·검색 UI**: `SearchFilterStackedItems`, `CommonSearchFieldId` (`core/search/common_search_field_catalog.dart`)
- **테이블**: `ErpDataTable` + `ErpTableHeaderCell` / `ErpTableBodyCell`
- **필터 규칙**: `ListFilterRule` 리스트 (`core/state/base_list_provider.dart`의 `RuleListNotifier`)

UI 토큰·금지 사항(예: 화면별 `textScaler` 조작)은 워크스페이스 규칙 **`.cursor/rules/flutter-erp-ui-consistency.mdc`** 와 가맹점 목록(`str001_view`) 구현을 참고합니다.

### 3.4 API 기준 URL

개발 기본값은 `lib/core/api/api_client.dart` 의 Dio `baseUrl` (**`http://localhost:3001/api`**) 입니다. 백엔드 기동 포트와 맞출 것.

---

## 4. 최근·주요 공통 개발 요소 (요약)

| 항목 | 파일 / 설명 |
|------|-------------|
| 검색 필터 다중 선택 | `core/widgets/common/common_search_filter_multi_select.dart` — 트리거 필드, 다이얼로그 본문, `showSearchFilterMultiPickDialog` / **`showSearchFilterMultiPickDialogWithRef`** (Riverpod 연동), 요약 문자열 `searchFilterMultiSelectSummary` · `searchFilterMultiSelectSummarySortedPreview` |
| 지역 필터 | 가맹점(`str001`)·예비창업자(`dev001`)는 공통 위젯 + `regionNamesProvider`(공통코드 grp 20) 기반; 목록 규칙에서 코드↔명 매칭 시 `partnerCodeOptionsProvider(20)` 등 활용 |
| 스크롤바 | `Scrollbar` + `ListView`/`ScrollView` 조합 시 **동일 `ScrollController`** 를 넘기고, 웹에서는 `primary: false` 명시 패턴 유지 |

---

## 5. 실행 방법

### 5.1 권장 (Windows 배치)

저장소 루트의 **`run_flutter_web.bat`** 실행 → Chrome 대상, 기본 웹 포트 `3000`(사용 중이면 `3001` 등), `--release` 모드.

### 5.2 수동 (예시)

```bat
cd /d C:\path\to\yeokjeon\app_flutter
flutter pub get
flutter run -d chrome --web-port 3000
```

Windows 데스크톱 등 다른 디바이스는 `flutter devices` 후 `-d` 로 지정합니다.

### 5.3 정적 분석 (CI와 동일)

```bat
cd app_flutter
dart analyze
```

---

## 6. 코드 생성 (JSON)

모델 수정 후:

```bat
cd app_flutter
dart run build_runner build --delete-conflicting-outputs
```

---

## 7. 관련 문서

| 문서 | 내용 |
|------|------|
| [`docs/ERP_PROJECT_GUIDE.md`](../docs/ERP_PROJECT_GUIDE.md) | 백엔드·Flutter 공통 규칙, 메뉴 코드↔폴더, DTO↔Dart 키 색인 |
| [`.cursor/rules/flutter-erp-ui-consistency.mdc`](../.cursor/rules/flutter-erp-ui-consistency.mdc) | 목록·필터·테이블·상세 UI 통일 규칙 |

---

## 8. 라이선스

내부 전용 프로젝트입니다. `pubspec.yaml` 의 `publish_to: 'none'` 과 동일하게 외부 배포를 전제로 하지 않습니다.
