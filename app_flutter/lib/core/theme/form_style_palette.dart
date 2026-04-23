// 상세 화면·입력 폼에서 쓰는 색·간격·텍스트 스타일 상수를 모아 둔다.

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 상세 화면(가맹점 상세 등)에서 공통으로 사용하는 라이트 테마 팔레트.
///
/// 화면 내부에 색상 상수를 하드코딩하던 것을 한 곳으로 모아 변경 지점을 단일화합니다.
class FormStylePalette {
  FormStylePalette._();

  static const Color panelBg = Colors.white;
  static const Color panelBorder = Color(0xFFE5E7EB);
  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color rowDivider = Color(0xFFEEF1F7);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  /// 탭바·강조 버튼에 공통 사용하는 포인트 컬러.
  static const Color accent = AppTheme.accentRed;

  /// 경고·취소 계열에 사용하는 중립 그레이.
  static const Color neutralGray = Color(0xFF6B7280);

  /// 문서 첨부 미첨부 같은 에러 강조용.
  static const Color danger = Color(0xFFDC2626);

  /// 헤더 행 배경.
  static const Color tableHeaderBg = Color(0xFFF8FAFC);

  /// 결재정보 표 — 좌측 열: 목록 [ErpDataTable] 헤더와 동일 ([AppTheme.accentRed] + 흰 글씨).
  /// 본문 칸: 카드·필드와 맞는 밝은 배경 (참고 이미지 틴트 금지).
  static const Color approvalTableLabelColumn = AppTheme.accentRed;
  static const Color approvalTableDataBg = AppTheme.cardBackground;
  static const Color approvalTableBorder = panelBorder;

  /// 폼에서 기본값 표시에 쓰는 텍스트 스타일.
  static const TextStyle valueStyle = TextStyle(
    color: textPrimary,
    fontSize: 15,
    fontFamilyFallback: AppTheme.koreanFontFallback,
  );

  /// 상세 패널(흰 카드) 가로 상한. 너무 좁으면 ERP 폼이 답답해 보이므로 웹·데스크톱 기준으로 넉넉히 둔다.
  static const double formMaxWidth = 1000.0;

  /// 라벨 열 폭 (좌측 라벨 + 우측 입력).
  static const double labelWidth = 100.0;
}
