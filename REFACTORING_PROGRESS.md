# 리팩토링 진행 현황

최종 갱신: 2026-04-21

---

## 1. 완료 (2026-04-20) — 파일/클래스 네이밍 규칙 정비

사용자 요청 규칙:
- 중복 제거(상위 폴더에서 이미 의미가 전달되면 파일명에서 제거)
- Screen 접미사 → `_view.dart`
- Notifier 파일 → `_provider.dart`
- `management` → `manage`
- `prospective_founder` → `founder`

### 1.1 데이터 모델 리네임

| 기존 파일 | 신규 파일 | 기존 클래스 | 신규 클래스 |
| --- | --- | --- | --- |
| `stores/data/models/store_row.dart` | `stores/data/models/store.dart` | `StoreRow` | `Store` |
| `stores/data/models/document_row.dart` | `stores/data/models/document.dart` | `DocumentRow` | `Document` |
| `development/data/models/property_row.dart` | `development/data/models/property.dart` | `PropertyRow` | `Property` |
| `development/data/models/prospective_founder_row.dart` | `development/data/models/founder.dart` | `ProspectiveFounderRow` | `Founder` |

### 1.2 Mock 파일

| 기존 | 신규 | 비고 |
| --- | --- | --- |
| `data/mock/mock_stores.dart` | 유지 | 내부만 `Store` 로 갱신 |
| `data/mock/mock_documents.dart` | 유지 | 내부만 `Document` 로 갱신 |
| `data/mock/mock_properties.dart` | 유지 | 내부만 `Property` 로 갱신 |
| `data/mock/mock_prospective_founders.dart` | `data/mock/mock_founders.dart` | `kMockProspectiveFounders` → `kMockFounders`, `kProspectiveFounderRegionOptions` → `kFounderRegionOptions` |

### 1.3 View model (Notifier / Provider) 리네임

| 기존 | 신규 | 기존 클래스 / 프로바이더 | 신규 클래스 / 프로바이더 |
| --- | --- | --- | --- |
| `stores/.../view_models/store_management_notifier.dart` | `stores/.../view_models/manage_provider.dart` | `StoreManagementNotifier` / `storeManagementProvider` | `StoreManageNotifier` / `storeManageProvider` |
| `development/.../view_models/property_notifier.dart` | `development/.../view_models/property_provider.dart` → (2일차에 `view_models/properties/manage_provider.dart` 로 재이동) | `PropertyManagementNotifier` / `propertyManagementProvider` | `PropertyManageNotifier` / `propertyManageProvider` |
| `development/.../view_models/prospective_founder_notifier.dart` | `development/.../view_models/founder_provider.dart` → (2일차에 `view_models/founders/manage_provider.dart` 로 재이동) | `ProspectiveFounderManagementNotifier` / `prospectiveFounderManagementProvider` | `FounderManageNotifier` / `founderManageProvider` |

### 1.4 Screen (→ View) 리네임

`stores` 는 엔티티가 하나라 기존 폴더 구조를 유지,
`development` 는 `property` / `founder` 두 엔티티가 공존하므로 서브 폴더(`properties/`, `founders/`) 로 분리.

| 기존 파일 | 신규 파일 | 기존 클래스 | 신규 클래스 |
| --- | --- | --- | --- |
| `stores/.../screens/store_management_screen.dart` | `stores/.../screens/manage_view.dart` | `StoreManagementScreen` | `StoreManageView` |
| `stores/.../screens/store_detail/store_detail_screen.dart` | `stores/.../screens/store_detail/detail_view.dart` | `StoreDetailScreen` | `StoreDetailView` |
| `development/.../screens/property_management_screen.dart` | `development/.../screens/properties/manage_view.dart` | `PropertyManagementScreen` | `PropertyManageView` |
| `development/.../screens/property_register_screen.dart` | `development/.../screens/properties/register_view.dart` | `PropertyRegisterScreen` | `PropertyRegisterView` |
| `development/.../screens/property_detail_screen.dart` | `development/.../screens/properties/detail_view.dart` | `PropertyDetailScreen` | `PropertyDetailView` |
| `development/.../screens/prospective_founder_management_screen.dart` | `development/.../screens/founders/manage_view.dart` | `ProspectiveFounderManagementScreen` | `FounderManageView` |
| `development/.../screens/prospective_founder_register_screen.dart` | `development/.../screens/founders/register_view.dart` | `ProspectiveFounderRegisterScreen` | `FounderRegisterView` |
| `development/.../screens/prospective_founder_detail_screen.dart` | `development/.../screens/founders/detail_view.dart` | `ProspectiveFounderDetailScreen` | `FounderDetailView` |

---

## 2. 완료 (2026-04-21) — 구조/아키텍처 정비

### 2.1 URL / 라우트 상수 `founder...` 로 통일 (A)

파일명·클래스에 맞춰 라우트 상수와 URL 도 `founder...` 로 축약.

| 기존 | 신규 |
| --- | --- |
| `AppRoutes.prospectiveFounders` = `/development/prospective-founders` | `AppRoutes.founders` = `/development/founders` |
| `AppRoutes.prospectiveFounderRegister` = `/development/prospective-founders/new` | `AppRoutes.founderRegister` = `/development/founders/new` |
| `AppRoutes.prospectiveFounderDetail` = `/development/prospective-founders/:founderNo` | `AppRoutes.founderDetail` = `/development/founders/:founderNo` |
| `AppRouteNames.prospectiveFounders` | `AppRouteNames.founders` |
| `AppRouteNames.prospectiveFounderRegister` | `AppRouteNames.founderRegister` |
| `AppRouteNames.prospectiveFounderDetail` | `AppRouteNames.founderDetail` |

일괄 갱신 파일:
- `core/router/app_router.dart`
- `core/router/route_meta.dart`
- `core/layout/erp_shell_layout.dart` (공통 레이아웃; 기존 `features/shell/...` 에서 이전)
- `features/development/presentation/screens/founders/manage_view.dart`
- `features/development/presentation/screens/founders/register_view.dart`

> grep `prospective` → 0 matches.

### 2.2 `development/presentation/view_models/` 를 엔티티 서브폴더로 분리 (B)

파일명 중복(`property_provider.dart`, `founder_provider.dart`) 을 해소하기 위해 엔티티 서브폴더로 이동. stores 는 엔티티 1개라 현상 유지.

| 기존 | 신규 |
| --- | --- |
| `development/.../view_models/property_provider.dart` | `development/.../view_models/properties/manage_provider.dart` |
| `development/.../view_models/founder_provider.dart` | `development/.../view_models/founders/manage_provider.dart` |

이름도 `_provider.dart` 규칙에 맞춰 `manage_provider.dart` 로 통일(클래스/프로바이더명은 그대로).

### 2.3 필터 Notifier 공통 베이스 추상화 (D)

세 Notifier(`StoreManageNotifier`, `PropertyManageNotifier`, `FounderManageNotifier`) 가
모두 "원본 리스트 + 상태 기반 필터링" 패턴이라 공용 베이스로 추출.

신규: `core/state/list_filter_notifier.dart`

```dart
abstract class ListFilterNotifier<F, T> extends Notifier<F> {
  List<T> get source;
  bool matches(T row);
  List<T> getFilteredList() => source.where(matches).toList(growable: false);
}
```

각 Notifier 는 이제 `source` 와 `matches` 만 구현. `getFilteredList` 는 베이스 제공.
기존 `StoreManageNotifier.getFilteredStoreList()` → `getFilteredList()` 로 통일(호출처도 함께 갱신).

### 2.4 Repository 레이어 도입 (C)

각 feature `data/repositories/` 하위에 인터페이스 + 인메모리 구현체 + Provider 추가.
UI 와 Notifier 에서 mock 리스트를 직접 참조하지 않고 Repository 를 통해서만 데이터를 가져오도록 변경.

신규 파일:
- `features/stores/data/repositories/store_repository.dart` — `StoreRepository`, `InMemoryStoreRepository`, `storeRepositoryProvider`
- `features/stores/data/repositories/document_repository.dart` — `DocumentRepository`, `InMemoryDocumentRepository`, `documentRepositoryProvider`
- `features/development/data/repositories/property_repository.dart`
- `features/development/data/repositories/founder_repository.dart`

대상 UI 변경 (StatelessWidget → ConsumerWidget / StatefulWidget → ConsumerStatefulWidget):
- `stores/.../screens/store_detail/detail_view.dart`
- `stores/.../screens/store_detail/tabs/documents_tab.dart`
- `development/.../screens/properties/detail_view.dart`
- `development/.../screens/founders/detail_view.dart`

Notifier 변경:
- `stores/.../view_models/manage_provider.dart`
- `development/.../view_models/properties/manage_provider.dart`
- `development/.../view_models/founders/manage_provider.dart`

모두 `ref.read(xxxRepositoryProvider)` 를 통해 데이터 접근. mock 상수(`kMockStores`, `kMockProperties`, `kMockFounders`, `kMockDocumentRows`) 에 대한 **UI/ViewModel 의 직접 참조는 0건**. 오직 `data/repositories/*Repository` 구현체만 mock 파일을 참조한다.

### 2.5 검증

- `ReadLints`: `No linter errors found.`
- `flutter analyze`: `No issues found!` (38.0s)

---

## 3. 다음 이어서 할 수 있는 후보

### E. 상세/등록 화면 공용 `EditablePanelScaffold` 추출 (보류 제안)

`PropertyInfoPanel`, `_FounderInfoPanel`, `_FounderRegisterPanel` 가 유사한 구조
(패널 헤더 + 편집 토글 + 필드 그리드) 를 각자 따로 구현 중. 공통화하면 코드량이 줄지만,
각 화면 별 필드 구성/레이아웃 차이가 커서 공통 추상화 비용이 실익을 넘길 수 있음.
실제 API 연동 시점에 각 패널의 저장 로직이 구체화된 다음 재평가하는 것을 추천.

### F. 필터 옵션 상수 이전

UI 드롭다운용 옵션(`kStoreBrandFilterOptions`, `kPropertyRegionOptions`, `kFounderRegionOptions`)이
아직 `data/mock/mock_*.dart` 에 같이 살고 있음. mock 데이터가 아닌 UI 상수이므로
`presentation/.../constants/` 나 Repository 가 옵션을 노출하도록 옮기면 mock 파일을
UI 가 import 하는 일이 완전히 사라짐.

### G. `kMockDocumentRows` → `kMockDocuments` 로 이름 정리 (경미)

Document 모델 이름이 `Document` 로 바뀌었으니 mock 상수도 `kMockDocuments` 가 자연스러움.
현재는 이전 이름이 남아있고 repo 에서만 참조됨.

### H. 라우트/브레드크럼 메타와 라우트 테이블 이원화 완화

`route_meta.dart` 와 `app_router.dart` 가 각각 정적/동적 라우트를 따로 들고 있어
추가 메뉴 추가 시 두 곳을 같이 수정해야 한다. 메타를 라우트 정의 옆에 두거나 빌더 함수로 통합하면 유지보수가 수월.

---

## 4. 지금까지 삭제된 구 파일

- `stores/data/models/store_row.dart`, `document_row.dart`
- `development/data/models/property_row.dart`, `prospective_founder_row.dart`
- `development/data/mock/mock_prospective_founders.dart`
- `stores/presentation/view_models/store_management_notifier.dart`
- `development/presentation/view_models/property_notifier.dart`, `prospective_founder_notifier.dart`
- `development/presentation/view_models/property_provider.dart`, `founder_provider.dart` (2일차에 서브폴더 이동하며 삭제)
- `stores/presentation/screens/store_management_screen.dart`, `store_detail/store_detail_screen.dart`
- `development/presentation/screens/property_management_screen.dart`, `property_register_screen.dart`, `property_detail_screen.dart`
- `development/presentation/screens/prospective_founder_management_screen.dart`, `prospective_founder_register_screen.dart`, `prospective_founder_detail_screen.dart`

`flutter analyze` 상 잔존 참조 없음.
