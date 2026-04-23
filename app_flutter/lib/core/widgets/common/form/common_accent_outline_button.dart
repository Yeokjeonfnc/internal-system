// 포인트 컬러 아웃라인 버튼·스타일 헬퍼.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

/// 지도보기·영업지역·달력 등 상세 화면 전반에서 사용하는 공통 아웃라인 버튼 스타일.
ButtonStyle accentOutlineButtonStyle({required bool iconOnly}) {
  return OutlinedButton.styleFrom(
    foregroundColor: FormStylePalette.accent,
    backgroundColor: FormStylePalette.accent.withValues(alpha: 0.08),
    side: const BorderSide(color: FormStylePalette.accent, width: 1.2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    padding: iconOnly
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    minimumSize: iconOnly ? const Size(44, 44) : null,
    fixedSize: iconOnly ? const Size(44, 44) : null,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

/// 위 스타일이 적용된 텍스트 라벨 전용 아웃라인 버튼.
class AccentOutlinedButton extends StatelessWidget {
  const AccentOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: accentOutlineButtonStyle(iconOnly: false),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}
