// 역전 F&C 브랜드 색·글꼴·Material ThemeData 를 정의한다.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  /// 브랜드 폰트. google_fonts 로 런타임에 Noto Sans KR 을 로드한다.
  ///
  /// google_fonts 는 내부적으로 `NotoSansKR_regular` 같은 동적 패밀리명을
  /// 생성하므로, 반드시 이 getter 를 통해 얻은 문자열을 사용해야 한다.
  static String get brandFontFamily =>
      GoogleFonts.notoSansKr().fontFamily ?? 'Noto Sans KR';

  static const Color sidebarBackground = Color(0xFF212529);
  static const Color sidebarActiveItem = Color(0xFF412B2B);
  static const Color accentRed = Color(0xFFBC1F26);
  static const Color accentRedHover = Color(0xFFA81A20);
  static const Color appSurface = Color(0xFFF2F2F2);
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// 테이블 바디의 홀수/짝수 행 배경색 (zebra striping).
  static const Color tableRowOdd = Color(0xFFFFFFFF);
  static const Color tableRowEven = Color(0xFFF5F7FA);
  static const Color statusNew = Color(0xFF28A745);
  static const Color statusRenewal = Color(0xFF007BFF);
  static const Color statusTransfer = Color(0xFFDC3545);
  static const Color chromeBlack = Color(0xFF1E2126);
  static const Color chromeDark = Color(0xFF2B2F35);

  /// 폰트 로딩 실패 시 사용할 시스템 한글 폰트.
  static const List<String> koreanFontFallback = [
    'Malgun Gothic',
    'Apple SD Gothic Neo',
    'Noto Sans KR',
    'sans-serif',
  ];

  static const Color textPrimary = Color(0xFF000000); // 기본 텍스트 색상 추가

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
        error: Color(0xFFB3261E),
        onError: Colors.white,
        surface: appSurface,
        onSurface: Color(0xFF111827),
      ),
      scaffoldBackgroundColor: appSurface,
      textTheme: GoogleFonts.notoSansKrTextTheme(base.textTheme).copyWith(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: family,
          fontFamilyFallback: koreanFontFallback,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: family,
          fontFamilyFallback: koreanFontFallback,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
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
          fontWeight: FontWeight.w500,
          fontFamily: family,
          fontFamilyFallback: koreanFontFallback,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentRed, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: chromeBlack,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
    );
  }
}
