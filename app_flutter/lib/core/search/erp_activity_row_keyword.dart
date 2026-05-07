/// 활동 목록 격자 등에서 통합 키워드(가맹점명·코드·수퍼바이저·메모 OR).
bool erpActivityRowMatchesKeyword(Map<String, dynamic> row, String keyword) {
  final q = keyword.trim().toLowerCase();
  if (q.isEmpty) return true;

  String gs(dynamic x) => x?.toString().toLowerCase() ?? '';

  return gs(row['storeNm']).contains(q) ||
      gs(row['storeCd']).contains(q) ||
      gs(row['ssvNm']).contains(q) ||
      gs(row['svNm']).contains(q) ||
      gs(row['actNotes']).contains(q) ||
      gs(row['memoTxt']).contains(q);
}
