// ERP 공통 검색 조건 메타데이터. 화면은 [kCommonSearchCatalog]에서
// 이 목록에 쓸 [CommonSearchFieldId] 집합만 고르면 된다.

/// 스프레드시트 기준 검색 구역(가맹점 / 예비창업자 / 지역·연락처).
enum CommonSearchFieldGroup {
  /// 가맹점 검색
  storeSearch,

  /// 예비창업자 검색
  partnerSearch,

  /// 물건 검색
  propertySearch,

  /// 지역·연락처 검색
  regionContact,

  /// 활동관리 화면 전용
  activitySearch,

  /// 영업지역 관리
  salesAreaSearch,

  /// 마스터 — 사원관리
  masterEmployeeSearch,
}

/// 공통 검색 필드 식별자(화면·필터 상태와 매핑).
enum CommonSearchFieldId {
  /// 가맹점명
  storeNm,

  /// 가맹점코드
  storeCd,

  /// 브랜드(옵션 적을 때 브랜드형 칩, 많으면 드롭다운)
  brandCd,

  /// 계약상태 — 다중 칩 등은 화면에서 [CommonSearchPresentation.pageBuilt]로 구현
  storeStatus,

  /// 담당슈퍼바이저
  supervisorCd,

  /// 가맹점구분(가맹 / 직영)
  storeType,

  /// 예비창업자(이름 등)
  prospectName,

  /// 상태(전체 / 예비창업자 / 가맹점사업자)
  entrepreneurStatus,

  /// 지역 — 항상 드롭다운
  regionCd,

  /// 휴대전화
  mobilePhone,

  /// 등록일
  registrationDate,

  /// 물건명
  propertyName,

  /// 예비창업자명
  partnerName,

  /// 종류(자가·임대차)
  propertyOwnership,

  /// 구분(체결물건 / 보류물건 / 부적합물건)
  propertyStatus,

  /// 주소(키워드)
  propertyAddress,

  /// 예비창업자 목록 — 평가상태
  founderEvaluation,

  /// 예비창업자 목록 — 상태(예비창업자 / 가맹점사업자) [Partner.partnerStatus]
  partnerStatus,

  /// 활동관리 — 상담내용 및 의견
  activityConsultMemo,

  /// 활동관리 — 활동일자(기간)
  activityDateRange,

  // --- 영업지역 관리 (필드 전용, 다른 목록의 동명 필드와 id 분리)
  /// 영업지역명
  salesAreaName,

  /// 물건명(영업지역 화면)
  salesAreaPropertyName,

  /// 브랜드(영업지역 화면)
  salesAreaBrand,

  /// 지역(영업지역 화면)
  salesAreaRegion,

  /// 전략출점지역 보기
  salesAreaStrategicOnly,

  /// 비가맹 물건 포함
  salesAreaIncludeNonFranchise,

  /// 영업지역 미설정 포함
  salesAreaIncludeUnset,

  /// 설정일자(기간)
  salesAreaSettingDateRange,

  // --- 사원관리(마스터)
  /// 사원명
  employeeName,

  /// 부서
  employeeDepartment,

  /// 이메일 주소
  employeeEmail,

  /// 휴대전화(사원관리)
  employeePhone,
}

/// UI 표현 방식(브랜드형 칩 vs 드롭다운 vs 텍스트 등).
enum CommonSearchPresentation {
  /// 한 줄 텍스트
  text,

  /// 옵션 개수에 따라 칩 또는 드롭다운([FilterStringOptionsSlot])
  adaptiveChipsOrDropdown,

  /// 지역 전용 — 항상 드롭다운([FilterStringOptionsSlot.forceDropdown])
  alwaysDropdown,

  /// 필드별 커스텀 슬롯(예: 계약상태 다중 선택)
  pageBuilt,
}

/// 한 검색 항목에 대한 공통 설명.
class CommonSearchFieldDef {
  const CommonSearchFieldDef({
    required this.id,
    required this.label,
    required this.group,
    required this.presentation,
  });

  final CommonSearchFieldId id;
  final String label;
  final CommonSearchFieldGroup group;
  final CommonSearchPresentation presentation;
}

/// 전체 공통 검색 조건(기획 스프레드시트 순·구역 반영).
const List<CommonSearchFieldDef> kCommonSearchCatalog = [
  CommonSearchFieldDef(
    id: CommonSearchFieldId.storeNm,
    label: '가맹점명',
    group: CommonSearchFieldGroup.storeSearch,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.storeCd,
    label: '가맹점코드',
    group: CommonSearchFieldGroup.storeSearch,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.brandCd,
    label: '브랜드',
    group: CommonSearchFieldGroup.storeSearch,
    presentation: CommonSearchPresentation.adaptiveChipsOrDropdown,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.storeStatus,
    label: '계약상태',
    group: CommonSearchFieldGroup.storeSearch,
    presentation: CommonSearchPresentation.pageBuilt,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.supervisorCd,
    label: '담당슈퍼바이저',
    group: CommonSearchFieldGroup.storeSearch,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.storeType,
    label: '가맹점구분(가맹 / 직영)',
    group: CommonSearchFieldGroup.storeSearch,
    presentation: CommonSearchPresentation.adaptiveChipsOrDropdown,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.partnerName,
    label: '예비창업자',
    group: CommonSearchFieldGroup.partnerSearch,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.partnerStatus,
    label: '상태',
    group: CommonSearchFieldGroup.partnerSearch,
    presentation: CommonSearchPresentation.pageBuilt,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.propertyName,
    label: '물건명',
    group: CommonSearchFieldGroup.propertySearch,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.propertyOwnership,
    label: '물건 종류',
    group: CommonSearchFieldGroup.propertySearch,
    presentation: CommonSearchPresentation.pageBuilt,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.propertyStatus,
    label: '구분',
    group: CommonSearchFieldGroup.propertySearch,
    presentation: CommonSearchPresentation.pageBuilt,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.propertyAddress,
    label: '주소',
    group: CommonSearchFieldGroup.propertySearch,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.regionCd,
    label: '지역',
    group: CommonSearchFieldGroup.regionContact,
    presentation: CommonSearchPresentation.alwaysDropdown,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.mobilePhone,
    label: '휴대전화',
    group: CommonSearchFieldGroup.regionContact,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.registrationDate,
    label: '등록일',
    group: CommonSearchFieldGroup.regionContact,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.activityConsultMemo,
    label: '상담내용 및 의견',
    group: CommonSearchFieldGroup.activitySearch,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.activityDateRange,
    label: '활동일자',
    group: CommonSearchFieldGroup.activitySearch,
    presentation: CommonSearchPresentation.pageBuilt,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.salesAreaName,
    label: '영업지역명',
    group: CommonSearchFieldGroup.salesAreaSearch,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.salesAreaPropertyName,
    label: '물건명',
    group: CommonSearchFieldGroup.salesAreaSearch,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.salesAreaBrand,
    label: '브랜드',
    group: CommonSearchFieldGroup.salesAreaSearch,
    presentation: CommonSearchPresentation.adaptiveChipsOrDropdown,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.salesAreaRegion,
    label: '지역',
    group: CommonSearchFieldGroup.salesAreaSearch,
    presentation: CommonSearchPresentation.alwaysDropdown,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.salesAreaStrategicOnly,
    label: '전략출점지역 보기',
    group: CommonSearchFieldGroup.salesAreaSearch,
    presentation: CommonSearchPresentation.pageBuilt,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.salesAreaIncludeNonFranchise,
    label: '비가맹 물건 포함',
    group: CommonSearchFieldGroup.salesAreaSearch,
    presentation: CommonSearchPresentation.pageBuilt,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.salesAreaIncludeUnset,
    label: '영업지역 미설정 포함',
    group: CommonSearchFieldGroup.salesAreaSearch,
    presentation: CommonSearchPresentation.pageBuilt,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.salesAreaSettingDateRange,
    label: '설정일자',
    group: CommonSearchFieldGroup.salesAreaSearch,
    presentation: CommonSearchPresentation.pageBuilt,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.employeeName,
    label: '사원명',
    group: CommonSearchFieldGroup.masterEmployeeSearch,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.employeeDepartment,
    label: '부서',
    group: CommonSearchFieldGroup.masterEmployeeSearch,
    presentation: CommonSearchPresentation.alwaysDropdown,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.employeeEmail,
    label: '이메일 주소',
    group: CommonSearchFieldGroup.masterEmployeeSearch,
    presentation: CommonSearchPresentation.text,
  ),
  CommonSearchFieldDef(
    id: CommonSearchFieldId.employeePhone,
    label: '휴대전화',
    group: CommonSearchFieldGroup.masterEmployeeSearch,
    presentation: CommonSearchPresentation.text,
  ),
];

String commonSearchGroupTitle(CommonSearchFieldGroup g) => switch (g) {
  CommonSearchFieldGroup.storeSearch => '가맹점 검색',
  CommonSearchFieldGroup.partnerSearch => '예비창업자 검색',
  CommonSearchFieldGroup.propertySearch => '물건 검색',
  CommonSearchFieldGroup.regionContact => '지역·연락처 검색',
  CommonSearchFieldGroup.activitySearch => '활동관리 검색',
  CommonSearchFieldGroup.salesAreaSearch => '영업지역 검색',
  CommonSearchFieldGroup.masterEmployeeSearch => '사원 관리',
};

/// [ids]에 포함된 항목만, [kCommonSearchCatalog] 순서로 반환한다.
List<CommonSearchFieldDef> commonSearchDefsOrdered(
  Iterable<CommonSearchFieldId> ids,
) {
  final want = Set<CommonSearchFieldId>.from(ids);
  return kCommonSearchCatalog.where((d) => want.contains(d.id)).toList();
}

/// [supported] 중에서 [group]에 속한 정의만 카탈로그 순으로.
List<CommonSearchFieldDef> commonSearchDefsInGroup(
  Set<CommonSearchFieldId> supported,
  CommonSearchFieldGroup group,
) {
  return kCommonSearchCatalog
      .where((d) => supported.contains(d.id) && d.group == group)
      .toList();
}
