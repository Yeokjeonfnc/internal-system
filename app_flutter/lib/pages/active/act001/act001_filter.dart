import 'package:flutter/material.dart';

/// 활동 현황(act001) 검색·기간·가맹점 탭 옵션.
class Act001StatusFilter {
  Act001StatusFilter();

  String brandCd = '';
  String periodKind = '월';
  late int year;
  late int month;
  int quarter = 1;
  int half = 1;
  bool visitingStoresOnly = false;

  factory Act001StatusFilter.initial([DateTime? now]) {
    final n = now ?? DateTime.now();
    final f = Act001StatusFilter();
    f.year = n.year;
    f.month = n.month;
    f.quarter = ((n.month - 1) ~/ 3) + 1;
    f.half = n.month <= 6 ? 1 : 2;
    return f;
  }

  void syncPeriod() {
    const kinds = {'월', '분기', '반기', '년'};
    if (!kinds.contains(periodKind)) periodKind = '월';
    month = month.clamp(1, 12);
    quarter = quarter.clamp(1, 4);
    half = half.clamp(1, 2);
    if (!yearRange.contains(year)) year = DateTime.now().year;
  }

  static List<int> get yearRange {
    final y = DateTime.now().year;
    return [y - 1, y, y + 1];
  }

  (DateTime, DateTime) get selectedDateRange {
    switch (periodKind) {
      case '월':
        return (
          DateTime(year, month, 1),
          DateTime(year, month, DateUtils.getDaysInMonth(year, month)),
        );
      case '분기':
        final startMonth = (quarter - 1) * 3 + 1;
        return (
          DateTime(year, startMonth, 1),
          DateTime(year, startMonth + 3, 0),
        );
      case '반기':
        final startMonth = half == 1 ? 1 : 7;
        return (
          DateTime(year, startMonth, 1),
          DateTime(year, startMonth + 6, 0),
        );
      case '년':
        return (DateTime(year, 1, 1), DateTime(year, 12, 31));
      default:
        return (DateTime(year, 1, 1), DateTime(year, 12, 31));
    }
  }

  int get timelineColumnCount => switch (periodKind) {
        '월' => DateUtils.getDaysInMonth(year, month),
        '분기' => 3,
        '반기' => 6,
        '년' => 12,
        _ => 12,
      };
}
