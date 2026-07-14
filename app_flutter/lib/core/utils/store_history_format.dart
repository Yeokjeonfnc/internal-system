import 'dart:convert';

/// 히스토리 탭 `chgContent` 원본을 JSON 문자열로 저장할 때 사용.
String storeHistoryChgContentEncode(Object? raw) {
  if (raw == null) return '[]';
  return jsonEncode(raw);
}

/// `chgDt` 등 ISO 문자열을 표시용으로 정규화.
String storeHistoryChgDtFormat(String raw) {
  if (raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw.replaceFirst('T', ' ');
  }
  String two(int value) => value.toString().padLeft(2, '0');
  return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)} '
      '${two(parsed.hour)}:${two(parsed.minute)}:${two(parsed.second)}';
}

int? _historyPart(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '');
}

String _trimmedString(Object? v) {
  if (v == null) return '';
  return v.toString().trim();
}

String storeHistoryChgDtFromJson(Object? v) {
  if (v == null) return '';
  if (v is List && v.length >= 3) {
    final y = _historyPart(v[0]);
    final m = _historyPart(v[1]);
    final d = _historyPart(v[2]);
    if (y != null && m != null && d != null) {
      final h = v.length > 3 ? (_historyPart(v[3]) ?? 0) : 0;
      final min = v.length > 4 ? (_historyPart(v[4]) ?? 0) : 0;
      final sec = v.length > 5 ? (_historyPart(v[5]) ?? 0) : 0;
      String two(int n) => n.toString().padLeft(2, '0');
      return '$y-${two(m)}-${two(d)} ${two(h)}:${two(min)}:${two(sec)}';
    }
  }
  return storeHistoryChgDtFormat(v.toString());
}

/// [chgType]별 UI 표시 — DB [chg_content]는 그대로 두고 노출만 가공한다.
String storeHistoryDisplayFromEncoded(
  String chgContentJson,
  String apiPlainContent,
  String chgType,
) {
  final type = chgType.trim().toUpperCase();
  if (type == 'INSERT') {
    return '신규 가맹점 등록';
  }
  if (type == 'UPDATE') {
    return _formatHistoryContentUpdateOnly(chgContentJson, apiPlainContent);
  }
  if (type == 'ACTIVE') {
    return _formatHistoryActiveContent(chgContentJson, apiPlainContent);
  }
  if (apiPlainContent.isNotEmpty) return apiPlainContent;
  return _formatHistoryContentVerbose(chgContentJson);
}

/// 활동관리 결재(active) — [chg_content] 문자열 그대로 노출.
String _formatHistoryActiveContent(
  String chgContentJson,
  String apiPlainContent,
) {
  if (apiPlainContent.isNotEmpty) return apiPlainContent;
  final trimmed = chgContentJson.trim();
  if (trimmed.isEmpty || trimmed == '[]' || trimmed == 'null') {
    return '-';
  }
  try {
    final raw = jsonDecode(chgContentJson);
    if (raw is String && raw.isNotEmpty) return raw;
  } catch (_) {
    // JSON 문자열이 아니면 원문 사용
  }
  if (trimmed.startsWith('"') && trimmed.endsWith('"') && trimmed.length >= 2) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  return trimmed;
}

String _formatHistoryContentUpdateOnly(
  String chgContentJson,
  String fallbackContent,
) {
  dynamic rawContent;
  try {
    rawContent = jsonDecode(chgContentJson);
  } catch (_) {
    rawContent = null;
  }
  if (rawContent is List && rawContent.isNotEmpty) {
    return rawContent.map(_formatHistoryChangeDescOnly).join(', ');
  }
  if (rawContent is Map<String, dynamic>) {
    return _formatHistoryChangeDescOnly(rawContent);
  }
  if (fallbackContent.isNotEmpty) return fallbackContent;
  return '-';
}

String _formatHistoryContentVerbose(String chgContentJson) {
  dynamic rawContent;
  try {
    rawContent = jsonDecode(chgContentJson);
  } catch (_) {
    return '-';
  }
  if (rawContent is List && rawContent.isNotEmpty) {
    return rawContent.map(_formatHistoryChangeVerbose).join(', ');
  }
  if (rawContent is Map<String, dynamic>) {
    return _formatHistoryChangeVerbose(rawContent);
  }
  return '-';
}

String _formatHistoryChangeDescOnly(dynamic rawChange) {
  if (rawChange is! Map) return _trimmedString(rawChange);
  // insertHistorySimple 저장 형식(column_nm=store) — DB는 그대로, 요약은 after_value만 노출
  final columnNm = _trimmedString(rawChange['column_nm']);
  if (columnNm == 'store') {
    final after = _trimmedString(rawChange['after_value']);
    if (after.isNotEmpty) return after;
  }
  final desc = _trimmedString(rawChange['column_desc']);
  if (desc.isNotEmpty) return desc;
  final nm = _trimmedString(rawChange['column_nm']);
  if (nm.isNotEmpty) return nm;
  return '변경';
}

String _formatHistoryChangeVerbose(dynamic rawChange) {
  if (rawChange is! Map) return rawChange.toString();
  final desc = _trimmedString(rawChange['column_desc']);
  final col = desc.isNotEmpty
      ? desc
      : _trimmedString(rawChange['column_nm']).isNotEmpty
      ? _trimmedString(rawChange['column_nm'])
      : _trimmedString(rawChange['col']).isNotEmpty
      ? _trimmedString(rawChange['col'])
      : '변경값';
  final before =
      rawChange['before_value']?.toString() ??
      rawChange['before']?.toString();
  final after =
      rawChange['after_value']?.toString() ?? rawChange['after']?.toString();
  if ((before == null || before.isEmpty) && (after == null || after.isEmpty)) {
    return '$col 변경';
  }
  if (before == null || before.isEmpty) return '$col: $after';
  if (after == null || after.isEmpty) return '$col: $before -> -';
  return '$col: $before -> $after';
}
