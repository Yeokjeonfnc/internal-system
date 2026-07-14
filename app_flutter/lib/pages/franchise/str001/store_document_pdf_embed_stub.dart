import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

void revokeStoreDocumentPdfEmbed(String viewType) {}

Widget buildStoreDocumentPdfEmbed({
  required Uint8List bytes,
  required String viewType,
}) {
  return const Center(
    child: Text(
      'PDF 미리보기를 이 환경에서 표시할 수 없습니다.\n다운로드 후 확인해 주세요.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: FormStylePalette.textMuted,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
    ),
  );
}
