// JSON / 동적 값 → 기본 타입 (메뉴별 API 파싱에서 공통 사용).

extension JsonDynamicParsing on Object? {
  int asJsonInt([int fallback = 0]) {
    final v = this;
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  double asJsonDouble([double fallback = 0]) {
    final v = this;
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  String asJsonString([String fallback = '']) {
    final v = this;
    if (v == null) return fallback;
    return v.toString();
  }
}

extension JsonMapParsing on Map<String, dynamic> {
  int jsonInt(String key, [int fallback = 0]) =>
      (this[key] as Object?).asJsonInt(fallback);

  double jsonDouble(String key, [double fallback = 0]) =>
      (this[key] as Object?).asJsonDouble(fallback);

  String jsonString(String key, [String fallback = '']) =>
      (this[key] as Object?).asJsonString(fallback);
}

/// ISO / `YYYY-MM-DD` 문자열을 `YYYY-MM-DD` 로만 잘라 반환.
String erpFormatYmdString(String raw) {
  if (raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw.split('T').first;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)}';
}

/// [JsonKey.fromJson] 용 — 동적 값을 `YYYY-MM-DD` 로 정규화.
String erpFormatYmdFromJson(Object? v) =>
    erpFormatYmdString(v?.toString() ?? '');

/// null 이면 null, 아니면 [asJsonInt] 와 동일 규칙.
int? asJsonIntOpt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}
