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
    'version': 2,
    'conditions': conditions.map((e) => e.toJson()).toList(),
  };

  factory StoreFilter.fromJson(Map<String, dynamic> json) {
    final rawConditions = json['conditions'];
    return StoreFilter(
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
  supervisor('SV \uB2F4\uB2F9\uC790'),
  businessNumber('\uC0AC\uC5C5\uC790\uBC88\uD638'),
  notes('\uBE44\uACE0');

  const StoreFilterField(this.label);
  final String label;
}
