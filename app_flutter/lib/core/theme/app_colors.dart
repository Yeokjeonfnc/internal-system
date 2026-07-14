// 역전 F&C 브랜드 색·글꼴·Material ThemeData 를 정의한다.
//
// ── 2026 리디자인 반영본 (프리미엄 미니멀 / 쿨 뉴트럴 화이트 베이스) ──
// 공개 API(상수 이름·타입, `light` getter)는 기존과 100% 동일하므로
// 이 파일 하나만 덮어써도 다른 코드 수정 없이 앱 전체 톤이 바뀐다.
// 값(색/라운드/보더/타이포 웨이트)만 리디자인 토큰으로 교체했다.

import 'package:flutter/material.dart';

class AppTheme {
  /// 브랜드 폰트. `pubspec.yaml` 에 번들된 Pretendard(가변 폰트)를 사용한다.
  /// 런타임 네트워크 다운로드가 없어 첫 화면이 즉시 렌더된다.
  static const String brandFontFamily = 'Pretendard';

  // ── 사이드바 ────────────────────────────────────────────────
  // 기존 다크 사이드바를 유지하되 회색빛(0xFF212529)에서 프리미엄
  // 웜-블랙(0xFF15130F)으로 교체해 고급감을 높였다. 흰색 텍스트 대비 유지.
  // ※ 완전한 '화이트 사이드바(3b)'로 가려면 APPLY_GUIDE.md 의 Option B 참고.
  static const Color sidebarBackground = Color(0xFFFBFBFA);
  static const Color sidebarActiveItem = Color(0xFFF0F0EE);

  // ── 브랜드 액센트 (레드 유지) ────────────────────────────────
  static const Color accentRed = Color(0xFFBC1F26);
  static const Color accentRedHover = Color(0xFFA81A20);

  // ── 서피스 ──────────────────────────────────────────────────
  static const Color appSurface = Color(0xFFF7F7F5); // 웜 뉴트럴 배경
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// 테이블·팝업 목록 바디의 줄무늬.
  /// 기존의 푸른 줄무늬(0xFFF4F7FB)를 중성 뉴트럴(0xFFFBFBFA)로 교체해
  /// 화이트 베이스 톤과 어긋나지 않게 했다.
  static const Color tableRowOdd = Color(0xFFFFFFFF);
  static const Color tableRowEven = Color(0xFFFBFBFA);

  // ── 계약상태 색상 (채도 낮춘 프리미엄 팔레트) ─────────────────
  static const Color statusNew = Color(0xFF1E8E4E); // 신규계약
  static const Color statusRenewal = Color(0xFF2563C7); // 재계약
  static const Color statusTransfer = Color(0xFF8A3FC7); // 양수도
  static const Color statusClosed = Color(0xFFC23636); // 폐점

  // ── 크롬(앱바 등) ───────────────────────────────────────────
  static const Color chromeBlack = Color(0xFF15130F);
  static const Color chromeDark = Color(0xFF2A2622);

  /// 헤어라인 보더 / 구분선 공통값. (신규 토큰 — 기존 하드코딩 0xFFE5E7EB 대체용)
  static const Color hairline = Color(0xFFEEEEEB);

  /// 보조 텍스트(라벨·캡션)용 뉴트럴 그레이. (신규 토큰)
  static const Color textMuted = Color(0xFF8A8A90);

  /// 경고·대기 상태 강조색(예: '대기', '3일 이상'). (신규 토큰)
  static const Color statusPending = Color(0xFFB4682A);

  // ── 2026 리디자인 추가 토큰 (01_design_system.md SSOT) ─────────
  /// 본문 보조 텍스트(값·부제목 등).
  static const Color textSecondary = Color(0xFF55555A);

  /// 최약 텍스트 / placeholder.
  static const Color textPlaceholder = Color(0xFFB5B5B1);

  /// 입력창 보더(비포커스).
  static const Color inputBorder = Color(0xFFE0E0DD);

  /// ERP 목록 테이블 헤더 행 배경(라이트).
  static const Color tableHeaderBackground = Color(0xFFFBFBFA);

  /// ERP 목록 테이블 헤더 행 하단 보더.
  static const Color tableHeaderBorder = Color(0xFFE6E6E3);

  /// ERP 목록 테이블 본문 행 하단 보더.
  static const Color tableRowBorder = Color(0xFFF4F4F2);

  /// 선택/포커스 행 강조(레드 옅은 틴트).
  static const Color tableRowSelectedTint = Color(0xFFFBF4F4);

  /// 활성 필터 요약칩 배경(뉴트럴).
  static const Color chipNeutralBackground = Color(0xFFF4F4F2);

  /// 폰트 로딩 실패 시 사용할 시스템 한글 폰트.
  static const List<String> koreanFontFallback = [
    'Malgun Gothic',
    'Apple SD Gothic Neo',
    'Noto Sans KR',
    'sans-serif',
  ];

  static const Color textPrimary = Color(0xFF101014); // 기본 텍스트(순검정 → 잉크블랙)

  static ThemeData get light {
    final base = ThemeData.light();
    final family = brandFontFamily;
    return ThemeData(
      useMaterial3: true,
      fontFamily: family,
      fontFamilyFallback: koreanFontFallback,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: accentRed,
        onPrimary: Colors.white,
        secondary: chromeDark,
        onSecondary: Colors.white,
        error: Color(0xFFC23636),
        onError: Colors.white,
        surface: appSurface,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: appSurface,
      textTheme: base.textTheme
          .apply(
            fontFamily: family,
            fontFamilyFallback: koreanFontFallback,
          )
          .copyWith(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          fontFamily: family,
          fontFamilyFallback: koreanFontFallback,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          fontFamily: family,
          fontFamilyFallback: koreanFontFallback,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: family,
          fontFamilyFallback: koreanFontFallback,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w500,
          fontFamily: family,
          fontFamilyFallback: koreanFontFallback,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400,
          fontFamily: family,
          fontFamilyFallback: koreanFontFallback,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: family,
          fontFamilyFallback: koreanFontFallback,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: hairline),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: accentRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontFamily: family,
            fontFamilyFallback: koreanFontFallback,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: Color(0xFFE0E0DD)),
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: family,
            fontFamilyFallback: koreanFontFallback,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentRed, width: 1.4),
        ),
        hintStyle: const TextStyle(color: Color(0xFFB5B5B1)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: hairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: chromeBlack,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
    );
  }
}
