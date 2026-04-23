# 역전 ERP Flutter — 프로젝트 구조 한눈에 보기

> `app_flutter` 기준. `build/`, `.dart_tool/`, 로컬 `flutter_sdk/` 등 생성·SDK 경로는 제외.

**유지보수 목표 구조·원칙·파일명 가이드**는 [`ARCHITECTURE_GUIDE.md`](ARCHITECTURE_GUIDE.md) 를 본다.

---

## 1. 디렉터리 트리

```
app_flutter/
├── analysis_options.yaml
├── pubspec.yaml
├── docs/
│   ├── PROJECT_STRUCTURE.md    ← 이 파일 (현재 트리·파일 설명)
│   └── ARCHITECTURE_GUIDE.md   ← 유지보수 최적화 목표 구조
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── data/
│   │   │   ├── mock_options.dart
│   │   │   └── mock/
│   │   │       ├── mock_documents.dart
│   │   │       ├── mock_founders.dart
│   │   │       ├── mock_history.dart
│   │   │       ├── mock_properties.dart
│   │   │       ├── mock_stores.dart
│   │   │       └── mock_store_detail_tabs.dart
│   │   ├── formatting/
│   │   │   └── display_date.dart
│   │   ├── layout/
│   │   │   ├── detail_screen_scaffold.dart
│   │   │   ├── erp_shell_layout.dart
│   │   │   └── erp_shell_tabs_provider.dart
│   │   ├── network/
│   │   │   └── dio_provider.dart
│   │   ├── router/
│   │   │   ├── app_route_def.dart
│   │   │   ├── app_router.dart
│   │   │   └── route_meta.dart
│   │   ├── state/
│   │   │   └── base_list_provider.dart
│   │   ├── theme/
│   │   │   ├── app_dimensions.dart
│   │   │   ├── app_theme.dart
│   │   │   ├── detail_palette.dart
│   │   │   └── shell_tab_chrome.dart
│   │   └── widgets/
│   │       └── common/
│   │           ├── common_active_filter_chips.dart
│   │           ├── common_detail_action_buttons.dart
│   │           ├── common_detail_button.dart
│   │           ├── common_filter_bar.dart
│   │           ├── common_filter_side_drawer.dart
│   │           ├── common_list_page_template.dart
│   │           ├── common_register_button.dart
│   │           ├── common_search_field_picker.dart
│   │           ├── common_search_filter_panel.dart
│   │           ├── data_table/
│   │           │   ├── common_erp_data_table.dart
│   │           │   └── common_erp_table_cells.dart
│   │           └── form/
│   │               ├── common_accent_outline_button.dart
│   │               ├── common_date_input_with_picker.dart
│   │               ├── common_form_field_block.dart
│   │               ├── common_form_row.dart
│   │               ├── common_labeled_form_row.dart
│   │               └── common_readonly_field.dart
│   └── features/
│       ├── dashboard/                          -------- 홈
│       │   ├── data/models/
│       │   │   ├── dashboard_kpi_model.dart
│       │   │   ├── dashboard_kpi_model.g.dart
│       │   │   ├── dashboard_summary_slot.dart
│       │   │   └── franchise_contract_card_data.dart
│       │   └── presentation/
│       │       ├── screens/dashboard_screen.dart
│       │       ├── view_models/dashboard_view_model.dart
│       │       └── widgets/
│       │           ├── franchise_contract_card.dart
│       │           └── kpi_card.dart
│       ├── founders/                      ------------ 예비창업자관리
│       │   ├── founder_controller.dart
│       │   ├── founder_detail_view.dart
│       │   ├── founder_list_view.dart
│       │   └── founder_model.dart
│       ├── properties/                     ---------------- 물건관리
│       │   ├── property_controller.dart
│       │   ├── property_detail_view.dart
│       │   ├── property_list_view.dart
│       │   ├── property_model.dart
│       │   └── property_register_view.dart
│       └── stores/                                 -------- 가맹점 관리
│           ├── store_controller.dart
│           ├── store_detail_tabs.dart
│           ├── store_detail_view.dart
│           ├── store_list_view.dart
│           └── store_model.dart
└── test/
    └── widget_test.dart
```

---

## 2. 역할 구분 (한 줄)

| 구역 | 역할 |
|------|------|
| **`lib/core`** | 라우터·테마·공통 위젯·목 데이터·네트워크 준비 등 **도메인과 무관한 뼈대**. |
| **`lib/features`** | 대시보드·가맹점·예비창업자·물건 등 **업무별 화면·모델·상태**. |
| **`lib/main.dart`** | 앱 진입점. |
| **`test`** | 위젯/단위 테스트. |

---

## 3. 파일별 내용

### 루트·설정

| 파일 | 내용 |
|------|------|
| `pubspec.yaml` | 패키지명, 의존성(go_router, riverpod, google_fonts 등), 에셋. |
| `analysis_options.yaml` | 린트·분석기 옵션. |

### `lib/`

| 파일 | 내용 |
|------|------|
| `main.dart` | `ProviderScope`, `MaterialApp.router`, `appRouter` 연결. |

### `lib/core/data/`

| 파일 | 내용 |
|------|------|
| `mock_options.dart` | 목록·필터용 **고정 드롭다운 문자열**(지역·가맹구분·창업자 구분 등, API 전 mock). |
| `mock/mock_stores.dart` | 가맹점 **목 데이터**. |
| `mock/mock_founders.dart` | 예비창업자 **목 데이터**. |
| `mock/mock_properties.dart` | 물건 **목 데이터**. |
| `mock/mock_documents.dart` | 가맹점 문서 탭 **목 문서**. |
| `mock/mock_history.dart` | 가맹점 이력 탭 **목 이력**. |
| `mock/mock_store_detail_tabs.dart` | 가맹점 상세 **탭 구성 목 데이터**. |

### `lib/core/formatting/`

| 파일 | 내용 |
|------|------|
| `display_date.dart` | 날짜 **표시/포맷** 유틸. |

### `lib/core/layout/`

| 파일 | 내용 |
|------|------|
| `erp_shell_layout.dart` | 사이드바·**멀티 탭**·빨간 배너·본문 **셸**. |
| `erp_shell_tabs_provider.dart` | 열린 탭 **목록·동기화·닫기** Riverpod. |
| `detail_screen_scaffold.dart` | 상세 화면 **공통 스캐폴드**. |

### `lib/core/network/`

| 파일 | 내용 |
|------|------|
| `dio_provider.dart` | Dio **프로바이더**(HTTP 클라이언트 주입용). |

### `lib/core/router/`

| 파일 | 내용 |
|------|------|
| `app_route_def.dart` | 라우트 **한 줄 정의**(name, path, title, pageBuilder…). |
| `app_router.dart` | `GoRouter`, `ShellRoute`, 라우트 목록. |
| `route_meta.dart` | 경로→**배너 메타**, 뒤로가기 **부모 경로**. |

### `lib/core/state/`

| 파일 | 내용 |
|------|------|
| `base_list_provider.dart` | 목록 **필터+규칙 필터링** 베이스 Notifier. |

### `lib/core/theme/`

| 파일 | 내용 |
|------|------|
| `app_theme.dart` | `ThemeData`, 브랜드색·사이드바·폰트. |
| `app_dimensions.dart` | 카드·테이블·패딩 등 **크기 상수**. |
| `detail_palette.dart` | 상세/폼용 **색·스타일** 팔레트. |
| `shell_tab_chrome.dart` | 상단 **탭 바** 전용 색·그라데이션. |

### `lib/core/widgets/common/`

여러 도메인에서 재사용하는 **공통 UI**만 둔다. 파일명은 `common_` 접두로 통일.

| 파일 | 내용 |
|------|------|
| `common_filter_bar.dart` | 목록용 **2열 필터 바** 슬롯(`FilterTextSlot` 등). |
| `common_list_page_template.dart` | 목록 **카드 셸**(칩·필터 시트·건수·테이블). |
| `common_filter_side_drawer.dart` | 우측 **필터 슬라이드 시트**(`showListFilterEndSheet`). |
| `common_search_filter_panel.dart` | 검색 필터 **행 UI** + 공통 텍스트 상수. |
| `common_search_field_picker.dart` | 필터 시트에서 검색 항목 **토글** UI. |
| `common_active_filter_chips.dart` | 적용 조건 **칩** 바. |
| `common_detail_button.dart` | 테이블 **상세보기** 버튼. |
| `common_detail_action_buttons.dart` | 상세 **수정·저장·취소** 등. |
| `common_register_button.dart` | **등록** 버튼. |
| `data_table/common_erp_data_table.dart` | 스크롤·테두리 있는 **테이블 래퍼**. |
| `data_table/common_erp_table_cells.dart` | 테이블 **헤더/바디 셀**. |
| `form/common_form_row.dart` | 폼 **2·3열 가로 배치** 행. |
| `form/common_labeled_form_row.dart` | 라벨 폭 고정 **라벨 행**. |
| `form/common_form_field_block.dart` | 폼 **블록** 래퍼. |
| `form/common_readonly_field.dart` | **읽기 전용** 필드. |
| `form/common_date_input_with_picker.dart` | 날짜 + **피커**. |
| `form/common_accent_outline_button.dart` | 액센트 **아웃라인 버튼**. |

### `lib/features/dashboard/`

| 파일 | 내용 |
|------|------|
| `data/models/dashboard_kpi_model.dart` | KPI **모델**. |
| `data/models/dashboard_kpi_model.g.dart` | JSON 직렬화 **생성 코드**. |
| `data/models/dashboard_summary_slot.dart` | 요약 슬롯 **모델**. |
| `data/models/franchise_contract_card_data.dart` | 가맹 계약 카드 **데이터**. |
| `presentation/screens/dashboard_screen.dart` | **대시보드 화면**. |
| `presentation/view_models/dashboard_view_model.dart` | 대시보드 **뷰모델**. |
| `presentation/widgets/kpi_card.dart` | **KPI 카드** UI. |
| `presentation/widgets/franchise_contract_card.dart` | **가맹 계약 카드** UI. |

### `lib/features/founders/`

| 파일 | 내용 |
|------|------|
| `founder_model.dart` | **엔티티·enum**. |
| `founder_controller.dart` | **목 Repository** + 목록 **필터 Notifier**. |
| `founder_list_view.dart` | **목록** 화면. |
| `founder_detail_view.dart` | **상세** + **등록** (`FounderRegisterView`) 화면. |

### `lib/features/properties/`

| 파일 | 내용 |
|------|------|
| `property_model.dart` | **엔티티·enum**. |
| `property_controller.dart` | **목 Repository** + 목록 **필터 Notifier**. |
| `property_list_view.dart` | **목록** 화면. |
| `property_detail_view.dart` | **상세** 화면. |
| `property_register_view.dart` | **등록** 화면. |

### `lib/features/stores/`

| 파일 | 내용 |
|------|------|
| `store_model.dart` | **엔티티·계약 상태 enum**. |
| `store_controller.dart` | 가맹점·브랜드·문서 **목 데이터** + 목록 **필터 Notifier**. |
| `store_list_view.dart` | **목록** 화면. |
| `store_detail_view.dart` | 상세 **라우트 진입**·탭 패널 연결. |
| `store_detail_tabs.dart` | 상세 **탭·문서 UI·공통 블록·패널** 통합. |

### `test/`

| 파일 | 내용 |
|------|------|
| `widget_test.dart` | 앱 **위젯 테스트**(예: 대시보드 렌더). |

---

## 4. 유지보수 시 참고

- 라우트·배너 제목·부모 경로: `app_route_def.dart` + `route_meta.dart` + `app_router.dart`.
- 목록 필터 UI 패턴: `common/common_list_page_template.dart` + `common/common_filter_bar.dart` + `common/common_filter_side_drawer.dart`.
- 브랜드 색·폰트: `app_colors.dart` / 상세 폼 톤: `form_style_palette.dart` / 탭 바만: `shell_tab_chrome.dart`.
- 새 목록 도메인: `features/<이름>/` 에 `*_model`, `*_controller`(Repository+필터), `*_list_view`, `*_detail_view` 패턴 권장.
