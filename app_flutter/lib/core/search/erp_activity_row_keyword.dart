import 'package:app_flutter/pages/active/act002/act002_model.dart';

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
