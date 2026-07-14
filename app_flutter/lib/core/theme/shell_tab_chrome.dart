// ERP 셸 상단 히스토리 탭 줄 전용 색·스타일 상수.

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ERP 셸 상단 **히스토리 탭** 줄에만 쓰는 크롬 팔레트.
///
/// 2026 리디자인: 화이트 바 + 헤어라인 하단 보더.
/// 활성 탭 스타일(잉크 라벨 + 레드 언더라인)은 `main_frame_layout.dart` 의
/// `_ShellTabChip` 에서 직접 그린다.
abstract final class ShellTabChrome {
  ShellTabChrome._();

  /// 탭 스트립 전체 높이.
  static const double tabStripHeight = 44;

  /// 탭 제목 [Text]의 `ConstrainedBox(maxWidth: …)` — 길어지면 ellipsis 전까지 이 폭까지 사용.
  static const double tabTitleMaxWidthActive = 400;
  static const double tabTitleMaxWidthInactive = 320;

  static const Color inactiveLabel = AppTheme.textMuted;
  static const Color inactiveIcon = Color(0xFFB5B5B1);
  static const Color inactiveHoverFill = Color(0xFFF4F4F2);
}
