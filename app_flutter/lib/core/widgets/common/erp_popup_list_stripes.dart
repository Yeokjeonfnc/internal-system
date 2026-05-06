// 팝업·모달 안 목록 줄무늬 배경 — [AppTheme.tableRowOdd/tableRowEven] 과 동일 규칙.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

/// 0부터 시작하는 행 인덱스에 대한 줄무늬 배경 (1행 밝음 → 2행 연한색).
Color erpPopupListRowBackground(int index) =>
    index.isEven ? AppTheme.tableRowOdd : AppTheme.tableRowEven;

/// 단일 선택 목록: 선택 행은 줄무늬 대신 강조색.
Color erpPopupListRowBackgroundSelectable(
  int index, {
  bool selected = false,
}) {
  if (selected) {
    return AppTheme.accentRed.withValues(alpha: 0.08);
  }
  return erpPopupListRowBackground(index);
}
