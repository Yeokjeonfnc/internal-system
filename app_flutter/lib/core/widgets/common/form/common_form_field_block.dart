// 폼 라벨 + 자식을 감싸는 필드 블록.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

/// 라벨(상단) + 입력 필드(하단)로 구성된 기본 폼 셀.
class FormFieldBlock extends StatelessWidget {
  const FormFieldBlock({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FormStylePalette.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        const SizedBox(height: 13),
        child,
      ],
    );
  }
}
