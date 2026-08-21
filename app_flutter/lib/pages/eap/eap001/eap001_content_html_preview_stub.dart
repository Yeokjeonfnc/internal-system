// 전자결재 본문 HTML 미리보기 — non-web (문자열 폴백).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

Widget buildEapContentHtmlPreview(
  String htmlBody, {
  bool seamless = false,
  bool readOnly = false,
}) {
  final text = htmlBody.trim().isEmpty ? '(본문 없음)' : htmlBody;
  return ConstrainedBox(
    constraints: BoxConstraints(minHeight: seamless ? 0 : 1280),
    child: SingleChildScrollView(
      child: SelectableText(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: AppTheme.textSecondary,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    ),
  );
}
