/// 가맹계약/개점 요약 카드용 표시 데이터.
class FranchiseContractCardData {
  const FranchiseContractCardData({
    required this.title,
    required this.numerator,
    required this.denominator,
    this.numeratorPrefix = '+',
    required this.unit,
    required this.totalStores,
    required this.consultCount,
    required this.newCount,
    required this.openCount,
    required this.expiringSoonCount,
    required this.terminatedCount,
  });

  final String title;
  final int numerator;
  final int denominator;
  final String numeratorPrefix;
  final String unit;
  final int totalStores;
  final int consultCount;
  final int newCount;
  final int openCount;
  final int expiringSoonCount;
  final int terminatedCount;
}
