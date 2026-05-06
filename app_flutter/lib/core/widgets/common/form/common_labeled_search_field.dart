// 라벨 열 + 검색용 단일 줄 텍스트 필드 — 결재선·모달 등 공통.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';

/// [LabeledSearchFieldRow]와 동일한 배경·테두리·포커스 스타일.
InputDecoration labeledSearchInputDecoration({
  required String hintText,
  bool showSearchIcon = true,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: FormStylePalette.inputBg,
    hintText: hintText,
    hintStyle: const TextStyle(
      fontSize: kSearchFilterFontSize,
      color: kSearchFilterHintColor,
      fontFamilyFallback: AppTheme.koreanFontFallback,
    ),
    prefixIcon: prefixIcon,
    prefixIconConstraints: prefixIcon != null
        ? const BoxConstraints(minWidth: 40, maxHeight: 40)
        : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.2),
    ),
    suffixIcon: showSearchIcon
        ? const Icon(
            Icons.search,
            size: 20,
            color: FormStylePalette.textSecondary,
          )
        : null,
    suffixIconConstraints: showSearchIcon
        ? const BoxConstraints(minWidth: 40, minHeight: 40)
        : null,
  );
}

/// 라벨 열(기본 140) + 검색 입력 한 줄 — 목록 검색 필터와 동일 타이포 토큰 사용.
class LabeledSearchFieldRow extends StatelessWidget {
  const LabeledSearchFieldRow({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.labelWidth = 140,
    this.showSearchIcon = true,
    this.enabled = true,
    this.onSubmitted,
    this.prefixIcon,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final double labelWidth;
  final bool showSearchIcon;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: kSearchFilterFontSize,
              fontWeight: FontWeight.w600,
              color: FormStylePalette.textPrimary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              fontSize: kSearchFilterFontSize,
              color: FormStylePalette.textPrimary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
            decoration: labeledSearchInputDecoration(
              hintText: hintText,
              showSearchIcon: showSearchIcon,
              prefixIcon: prefixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
