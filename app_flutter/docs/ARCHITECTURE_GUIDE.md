# 역전 ERP 프로젝트 구조 (유지보수 최적화 버전)

## 원칙

1. 모든 파일은 **한글 주석**으로 역할을 명시한다.
2. 작은 조각 위젯은 **별도 파일로 만들지 않고** 메인 파일 하단에 `part` 또는 같은 파일 하단 private 클래스로 포함한다.
3. 파일명은 직관적인 **역할** 위주로 명명한다.

---

## 1. 공통 뼈대 (`lib/core`)

앱 전체의 디자인과 공통 기능을 담당한다.

### 레이아웃 (`layout/`)

| 목표 파일명 | 역할 |
|-------------|------|
| **`main_frame_layout.dart`** | 사이드바 + 상단 탭이 포함된 앱의 **메인 껍데기**. |
| **`tab_manager_provider.dart`** | 상단 멀티 탭(열린 화면) **생성·동기화·삭제** 로직. |

### 테마 및 스타일 (`theme/`)

| 목표 파일명 | 역할 |
|-------------|------|
| **`app_theme.dart`** | 역전 F&C 브랜드 컬러 및 전체 글꼴·`ThemeData` 설정. |
| **`form_style_palette.dart`** | 입력창·상세 페이지 등 **폼/상세 전용** 색·간격 팔레트. |

### 공통 위젯 (`widgets/common/`)

| 목표 파일명 | 역할 |
|-------------|------|
| **`common_list_page_template.dart`** | 가맹점·물건·예비창업자 등 **모든 목록 페이지**의 기본 틀(칩·필터·건수·테이블). |
| **`common_filter_bar.dart`** 등 | 상단 **검색/필터** 슬롯(`CommonFilterBar` + `SearchFilterPanel`). |
| **`common_filter_side_drawer.dart`** | 우측에서 나오는 **상세 필터** 슬라이드(시트). |
| **`common_active_filter_chips.dart`** | 현재 적용된 필터 조건 **칩 리스트**. |
| **`common/data_table/common_erp_*.dart`** | 공통 **리스트 테이블**(스크롤·헤더·셀 스타일). |

---

## 2. 주요 기능 (`lib/features`)

업무별 화면. **한 폴더당 파일은 4개 내외**로 묶는 것을 목표로 한다.

### 가맹점 관리 (`stores/`)

| 목표 파일명 | 역할 |
|-------------|------|
| **`store_list_view.dart`** | 가맹점 **목록** 메인 화면. |
| **`store_detail_view.dart`** | 가맹점 상세 **라우트 진입·전체 뼈대**. |
| **`store_detail_tabs.dart`** | 상세 안의 탭(기본·계약·문서·이력 등) **통합** — 작은 탭 위젯은 이 파일 하단 private. |
| **`store_controller.dart`** | 가맹점 **데이터 조회·필터·상태** (Repository + Provider 역할 통합 시 이 이름). |

### 예비창업자 관리 (`founders/`)

| 목표 파일명 | 역할 |
|-------------|------|
| **`founder_list_view.dart`** | 예비창업자 **목록** 화면. |
| **`founder_detail_view.dart`** | 예비창업자 **상세** (등록은 동일 파일 내 탭/모드로 두거나 별도 최소 파일). |
| **`founder_controller.dart`** | 예비창업자 **데이터·필터 상태** 로직. |

### 물건 관리 (`properties/`) — 확장 시

| 목표 파일명 | 역할 |
|-------------|------|
| **`property_list_view.dart`** | 물건 목록. |
| **`property_detail_view.dart`** | 물건 상세. |
| **`property_controller.dart`** | 물건 데이터·필터. |

---

## 3. 데이터 및 유틸 (`lib/core/data`)

| 목표 파일명 | 역할 |
|-------------|------|
| **`mock_options.dart`** | 지역·가맹구분 등 **공통 드롭다운 옵션**(API 전 mock 문자열, 시·도 목록 포함). |
| **`mock_data_hub.dart`** | 개발·UI 테스트용 **목 데이터** 통합 (또는 도메인별 part). |

---

## 부록: 현재 코드 → 목표 이름 매핑 (리팩터 시 참고)

| 현재 (요약) | 목표에 가깝게 |
|-------------|----------------|
| `erp_shell_layout.dart` | `main_frame_layout.dart` |
| `erp_shell_tabs_provider.dart` | `tab_manager_provider.dart` |
| `detail_palette.dart` | `form_style_palette.dart` (역할 합치거나 병행) |
| `management_list_scaffold.dart` | `widgets/common/common_list_page_template.dart` |
| `filter_summary_chip.dart` + 필터 버튼 일부 | `active_filter_chips.dart` + `search_bar_area.dart` |
| `list_filter_end_sheet.dart` | `widgets/common/common_filter_side_drawer.dart` |
| `erp_data_table.dart` + `erp_table_cells.dart` | `erp_data_grid.dart` (셀은 파일 하단 또는 part) |
| `store_view.dart` | `store_list_view.dart` |
| `store_detail_panel.dart` + 여러 `store_*_tab.dart` | `store_detail_tabs.dart` (통합됨) |
| `store_provider.dart` / `store_repository.dart` | `store_controller.dart` |
| `founder_*_provider` / `founder_repository` 등 | `founder_controller.dart` (동일 패턴: property) |
| (구 `region_options.dart`) | `mock_options.dart` 의 `kMockRegionOptions` 로 통합됨. |
| `core/data/mock/*.dart` | `mock_data_hub.dart` + part 또는 하위 폴더 유지 |

> 위 매핑은 **일괄 리네임이 아니라** 이후 작업 순서를 잡을 때의 가이드다. `go_router` 경로·import 한 번에 깨지지 않도록 **기능 단위로** 옮긴다.
