import 'package:app_flutter/pages/franchise/str001/str001_model.dart';

/// 가맹점 목록 — 계약상태 다중 선택 칩 라벨.
const List<String> kStoreContractStatusLabels = [
  '신규계약',
  '재계약',
  '양수도',
  '폐점',
];

/// 테이블·필터 공통 계약상태 표시명.
String storeContractStatusLabel(Store store) {
  final nm = store.storeStatusNm.trim();
  if (nm.isNotEmpty) return nm;
  return switch (store.storeStatus.toLowerCase()) {
    'new' => '신규계약',
    'renewal' => '재계약',
    'transfer' => '양수도',
    'closed' => '폐점',
    _ => store.storeStatus,
  };
}

/// 선택된 계약상태(OR) — 비어 있으면 전체.
bool storeMatchesContractStatusFilter(Set<String> selected, Store store) {
  if (selected.isEmpty) return true;
  return selected.contains(storeContractStatusLabel(store));
}

/// 조건 값 — 쉼표 구분 계약상태(다중 선택).
Set<String> parseContractStatusConditionValue(String value) {
  return value
      .split(',')
      .map((e) => e.trim())
      .where(kStoreContractStatusLabels.contains)
      .toSet();
}

String joinContractStatusConditionValue(Set<String> selected) {
  final list = selected.toList()..sort();
  return list.join(',');
}

bool storeMatchesContractStatusCondition(String value, Store store) {
  final selected = parseContractStatusConditionValue(value);
  if (selected.isEmpty) return true;
  return selected.contains(storeContractStatusLabel(store));
}

class StoreFilter {
  const StoreFilter({
    this.storeKeyword = '',
    this.brandCd = '\uC804\uCCB4',
    this.regionNms = const <String>{},
    this.storeStatus = const <String>{},
    this.conditions = const <StoreFilterCondition>[],
  });

  // Legacy values remain only to safely read an already-open screen state.
  // STR001 no longer exposes or persists these filters.
  final String storeKeyword;
  final String brandCd;
  final Set<String> regionNms;
  final Set<String> storeStatus;
  final List<StoreFilterCondition> conditions;

  StoreFilter copy({
    String? storeKeyword,
    String? brandCd,
    Set<String>? regionNms,
    Set<String>? storeStatus,
    List<StoreFilterCondition>? conditions,
    bool clearStatuses = false,
    bool clearRegions = false,
  }) => StoreFilter(
    storeKeyword: storeKeyword ?? this.storeKeyword,
    brandCd: brandCd ?? this.brandCd,
    regionNms: clearRegions ? <String>{} : regionNms ?? this.regionNms,
    storeStatus: clearStatuses ? <String>{} : storeStatus ?? this.storeStatus,
    conditions: conditions ?? this.conditions,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': 3,
    'storeStatus': storeStatus.toList(growable: false),
    'conditions': conditions.map((e) => e.toJson()).toList(),
  };

  factory StoreFilter.fromJson(Map<String, dynamic> json) {
    final rawConditions = json['conditions'];
    final rawStatuses = json['storeStatus'];
    final statuses = rawStatuses is List
        ? rawStatuses.map((e) => e.toString()).toSet()
        : const <String>{};
    return StoreFilter(
      storeStatus: statuses,
      conditions: rawConditions is List
          ? rawConditions
                .whereType<Map>()
                .map(
                  (e) => StoreFilterCondition.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .where((e) => e.value.trim().isNotEmpty)
                .toList(growable: false)
          : const <StoreFilterCondition>[],
    );
  }
}

class StoreFilterCondition {
  const StoreFilterCondition({required this.field, required this.value});

  final StoreFilterField field;
  final String value;

  StoreFilterCondition copyWith({StoreFilterField? field, String? value}) =>
      StoreFilterCondition(
        field: field ?? this.field,
        value: value ?? this.value,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'field': field.name,
    'value': value,
  };

  factory StoreFilterCondition.fromJson(Map<String, dynamic> json) {
    final name = json['field']?.toString() ?? '';
    return StoreFilterCondition(
      field: StoreFilterField.values.firstWhere(
        (e) => e.name == name,
        orElse: () => StoreFilterField.storeName,
      ),
      value: json['value']?.toString() ?? '',
    );
  }
}

enum StoreFilterField {
  storeName('\uAC00\uB9F9\uC810\uBA85'),
  storeCode('\uAC00\uB9F9\uC810 \uCF54\uB4DC'),
  ownerName('\uC810\uC8FC\uBA85'),
  phone('\uC5F0\uB77D\uCC98'),
  address('\uC8FC\uC18C'),
  contractStartDate('\uACC4\uC57D \uC2DC\uC791\uC77C'),
  contractEndDate('\uACC4\uC57D \uB9CC\uB8CC\uC77C'),
  contractStatus('\uACC4\uC57D\uC0C1\uD0DC'),
  supervisor('SV \uB2F4\uB2F9\uC790'),
  businessNumber('\uC0AC\uC5C5\uC790\uBC88\uD638'),
  notes('\uBE44\uACE0');

  const StoreFilterField(this.label);
  final String label;
}
