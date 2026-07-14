import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';

/// 네이티브(Android·iOS·Windows·macOS)에서 PDF를 실제 페이지로 렌더한다.
///
/// WebView 의 `data:application/pdf` 로드는 Android 등에서 까만 화면만 떠서
/// 네이티브 PDF 렌더러(`pdfx`)로 직접 그린다.
Widget buildStoreDocumentPdfEmbed({
  required Uint8List bytes,
  required String viewType,
}) {
  return _StoreDocumentPdfView(bytes: bytes);
}

void revokeStoreDocumentPdfEmbed(String viewType) {}

class _StoreDocumentPdfView extends StatefulWidget {
  const _StoreDocumentPdfView({required this.bytes});

  final Uint8List bytes;

  @override
  State<_StoreDocumentPdfView> createState() => _StoreDocumentPdfViewState();
}

class _StoreDocumentPdfViewState extends State<_StoreDocumentPdfView> {
  late final PdfControllerPinch _controller = PdfControllerPinch(
    document: PdfDocument.openData(widget.bytes),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF4F4F4),
      child: PdfViewPinch(
        controller: _controller,
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: CommonLoadingIndicator()),
          pageLoaderBuilder: (_) =>
              const Center(child: CommonLoadingIndicator()),
          errorBuilder: (_, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'PDF를 표시하지 못했습니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: FormStylePalette.textMuted,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
