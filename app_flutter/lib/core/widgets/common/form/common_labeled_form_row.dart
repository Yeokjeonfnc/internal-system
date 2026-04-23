// 왼쪽 라벨 + 필수 표시가 있는 폼 한 줄.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

/// 라벨이 좌측에 있고 오른쪽에 입력 영역이 이어지는 폼 행.
///
/// `requiredField`가 true이면 라벨 앞에 빨간색 `*` 마크가 붙습니다.
class LabeledFormRow extends StatelessWidget {
  const LabeledFormRow({
    super.key,
    required this.label,
    required this.child,
    this.requiredField = false,
    this.labelWidth = FormStylePalette.labelWidth,
  });

  final String label;
  final Widget child;
  final bool requiredField;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: FormStylePalette.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
                children: [
                  if (requiredField)
                    const TextSpan(
                      text: '*',
                      style: TextStyle(
                        color: FormStylePalette.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  TextSpan(text: label),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
