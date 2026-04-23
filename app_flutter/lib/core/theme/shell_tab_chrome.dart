// ERP 셸 상단 멀티 탭 바 전용 색·스타일 상수.

import 'package:flutter/material.dart';

/// ERP 셸 상단 **멀티 탭** 바에만 쓰는 크롬 팔레트.
///
/// 선택 탭 그라데이션 하단은 브랜드 레드 `#BC1F26`(app_theme `accentRed`) 과 동일.
abstract final class ShellTabChrome {
  ShellTabChrome._();

  /// 탭 스트립 전체 높이. 선택 탭은 이 안에서 **아래까지 채워** 빨간 배너와 끊김 없이 맞춘다.
  static const double tabStripHeight = 46;
  static const double tabStripTopPadding = 6;
  static double get tabActiveFillHeight => tabStripHeight - tabStripTopPadding;

  /// 탭 제목 [Text]의 `ConstrainedBox(maxWidth: …)` — 길어지면 ellipsis 전까지 이 폭까지 사용.
  static const double tabTitleMaxWidthActive = 400;
  static const double tabTitleMaxWidthInactive = 320;

  /// 차콜 크롬 → 아래로 갈수록 버건디 톤으로 [accentRed] 배너와 이어지게.
  static const LinearGradient barGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF383F4E),
      Color(0xFF2F3542),
      Color(0xFF35262A),
      Color(0xFF3D1F24),
    ],
    stops: [0.0, 0.42, 0.72, 1.0],
  );

  static const Color barHighlightLine = Color(0x12FFFFFF);

  static const Color inactiveLabel = Color(0xFFD2D8E3);
  static const Color inactiveIcon = Color(0xFF9AA3B5);
  static const Color inactiveHoverFill = Color(0x16FFFFFF);

  /// 선택 탭: 배너와 같은 레드 계열, 밝은 면은 위쪽에만.
  static const LinearGradient activeTabGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD32F37), Color(0xFFC4252D), Color(0xFFBC1F26)],
    stops: [0.0, 0.35, 1.0],
  );

  /// 선택 탭: 위·좌·우만 (배너와 맞닿는 **아래쪽은 직각·보더**).
  static const Border activeTabBorderSides = Border(
    left: BorderSide(color: Color(0x3DFFFFFF)),
    top: BorderSide(color: Color(0x3DFFFFFF)),
    right: BorderSide(color: Color(0x3DFFFFFF)),
  );

  static const Color activeLabelOnRed = Color(0xFFF8FAFC);
  static const Color activeIconOnRed = Color(0xD8FFFFFF);

  /// 아래로 번지지 않게 위쪽만 살짝 입체감.
  static const List<BoxShadow> activeTabShadow = [
    BoxShadow(
      color: Color(0x28000000),
      blurRadius: 6,
      offset: Offset(0, -1),
      spreadRadius: -2,
    ),
  ];
}
