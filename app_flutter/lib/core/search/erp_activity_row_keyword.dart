import 'package:flutter/material.dart';

import 'package:app_flutter/pages/active/act002/act002_model.dart';

/// 필터 적용 후 행 수를 목록 셸 [countText] 등에 전달한다. [count] null = 조회 중.
void erpNotifyFilteredRowCount(
  ValueChanged<int?>? callback,
  int? count,
) {
  if (callback == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    callback(count);
  });
}

/// 활동일자(`actDt`)가 [start]~[end] 구간(일 단위, 양끝 포함)에 들어가는지.
bool erpActivityRowInDateRange(
  ActivityRow row,
  DateTime start,
  DateTime end,
) {
  final raw = row.actDt.trim();
  if (raw.isEmpty) return false;
  final parsed = DateTime.tryParse(raw.split('T').first);
  if (parsed == null) return false;
  final day = DateTime(parsed.year, parsed.month, parsed.day);
  final a = DateTime(start.year, start.month, start.day);
  final b = DateTime(end.year, end.month, end.day);
  return !day.isBefore(a) && !day.isAfter(b);
}

/// 활동 목록 격자 등에서 통합 키워드(가맹점명·코드·수퍼바이저·메모 OR).
bool erpActivityRowMatchesKeyword(ActivityRow row, String keyword) {
  final q = keyword.trim().toLowerCase();
  if (q.isEmpty) return true;

  String gs(String x) => x.trim().toLowerCase();

  return gs(row.storeNm).contains(q) ||
      gs(row.storeCd).contains(q) ||
      gs(row.ssvNm).contains(q) ||
      gs(row.svNm).contains(q) ||
      gs(row.actNotes).contains(q) ||
      gs(row.memoTxt).contains(q) ||
      gs(row.apprNotes).contains(q);
}
