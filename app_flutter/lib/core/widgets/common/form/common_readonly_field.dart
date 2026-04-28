// 읽기 전용 값·접미사·면적 쌍 표시 위젯.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

/// 읽기 전용 입력처럼 보이는 공통 컨테이너(테두리 + 배경).
class ReadonlyInputShell extends StatelessWidget {
  const ReadonlyInputShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: FormStylePalette.inputBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FormStylePalette.panelBorder),
      ),
      child: child,
    );
  }
}

/// 단일 값을 읽기 전용으로 노출하는 기본 위젯.
class ReadonlyValue extends StatelessWidget {
  const ReadonlyValue(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ReadonlyInputShell(
      child: Text(
        text,
        style: const TextStyle(
          color: FormStylePalette.textPrimary,
          fontSize: 15,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

/// 값 + 단위(㎡, 원, % 등)를 한 칸에 보여주는 읽기 전용 위젯.
class ReadonlyWithSuffix extends StatelessWidget {
  const ReadonlyWithSuffix({
    super.key,
    required this.value,
    required this.suffix,
  });

  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return ReadonlyInputShell(
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: FormStylePalette.textPrimary,
                fontSize: 15,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          Text(
            suffix,
            style: const TextStyle(
              color: FormStylePalette.textMuted,
              fontSize: 15,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ],
      ),
    );
  }
}

/// 두 개의 단위 값을 좌/우로 나란히 보여주는 셀 (예: 계약 면적 / 실 면적).
class UnitPairRow extends StatelessWidget {
  const UnitPairRow({
    super.key,
    required this.primary,
    required this.primarySuffix,
    required this.secondary,
    required this.secondarySuffix,
  });

  final String primary;
  final String primarySuffix;
  final String secondary;
  final String secondarySuffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ReadonlyWithSuffix(value: primary, suffix: primarySuffix),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ReadonlyWithSuffix(value: secondary, suffix: secondarySuffix),
        ),
      ],
    );
  }
}
