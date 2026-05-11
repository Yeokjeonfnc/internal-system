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

String storeHistoryChgDtFromJson(Object? v) =>
    storeHistoryChgDtFormat(v?.toString() ?? '');

/// [chgContentJson]은 [storeHistoryChgContentEncode]와 동일 규칙(또는 API 원본을 encode한 값).
String storeHistoryDisplayFromEncoded(
  String chgContentJson,
  String apiPlainContent,
) {
  dynamic rawContent;
  try {
    rawContent = jsonDecode(chgContentJson);
  } catch (_) {
    rawContent = null;
  }
  return _formatHistoryContent(rawContent, apiPlainContent);
}

String _formatHistoryContent(dynamic rawContent, String fallbackContent) {
  if (rawContent is List && rawContent.isNotEmpty) {
    return rawContent.map(_formatHistoryChange).join(', ');
  }
  if (rawContent is Map<String, dynamic>) {
    return _formatHistoryChange(rawContent);
  }
  if (fallbackContent.isNotEmpty) return fallbackContent;
  return '-';
}

String _formatHistoryChange(dynamic rawChange) {
  if (rawChange is! Map) return rawChange.toString();
  final col = rawChange['column_desc']?.toString().trim().isNotEmpty == true
      ? rawChange['column_desc'].toString()
      : rawChange['column_nm']?.toString() ??
            rawChange['col']?.toString() ??
            '변경값';
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
