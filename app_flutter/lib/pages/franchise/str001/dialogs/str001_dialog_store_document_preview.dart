import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/pages/franchise/str001/store_document_pdf_embed_stub.dart'
    if (dart.library.io) 'package:app_flutter/pages/franchise/str001/store_document_pdf_embed_io.dart'
    if (dart.library.html) 'package:app_flutter/pages/franchise/str001/store_document_pdf_embed_web.dart';
import 'package:app_flutter/pages/franchise/str001/store_document_preview_kind.dart';

/// 미리보기 한 건 — [loadBytes]는 페이지 진입 시 호출된다.
class StoreDocumentPreviewItem {
  const StoreDocumentPreviewItem({
    required this.fileName,
    required this.loadBytes,
  });

  final String fileName;
  final Future<Uint8List?> Function() loadBytes;
}

/// 가맹점 문서 미리보기 다이얼로그(단건).
Future<void> showStoreDocumentPreviewDialog({
  required BuildContext context,
  required String fileName,
  required Future<Uint8List?> bytesFuture,
}) async {
  if (!context.mounted) return;
  await showStoreDocumentGalleryPreviewDialog(
    context: context,
    items: [
      StoreDocumentPreviewItem(
        fileName: fileName,
        loadBytes: () => bytesFuture,
      ),
    ],
    initialIndex: 0,
  );
}

/// 여러 문서·첨부를 좌우 스와이프·이전/다음으로 넘기며 미리본다.
Future<void> showStoreDocumentGalleryPreviewDialog({
  required BuildContext context,
  required List<StoreDocumentPreviewItem> items,
  int initialIndex = 0,
}) async {
  if (!context.mounted || items.isEmpty) return;
  final start = initialIndex.clamp(0, items.length - 1);
  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (dialogCtx) {
      return _StoreDocumentGalleryPreviewDialog(
        items: items,
        initialIndex: start,
      );
    },
  );
}

class _StoreDocumentGalleryPreviewDialog extends StatefulWidget {
  const _StoreDocumentGalleryPreviewDialog({
    required this.items,
    required this.initialIndex,
  });

  final List<StoreDocumentPreviewItem> items;
  final int initialIndex;

  @override
  State<_StoreDocumentGalleryPreviewDialog> createState() =>
      _StoreDocumentGalleryPreviewDialogState();
}

class _StoreDocumentGalleryPreviewDialogState
    extends State<_StoreDocumentGalleryPreviewDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.items.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxH = size.height * 0.85;
    final maxW = math.min(960.0, size.width - 48);
    final item = widget.items[_currentIndex];
    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < widget.items.length - 1;
    final showPager = widget.items.length > 1;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      child: SizedBox(
        width: maxW,
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamilyFallback: AppTheme.koreanFontFallback,
                          ),
                        ),
                        if (showPager)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${_currentIndex + 1} / ${widget.items.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: FormStylePalette.textMuted,
                                fontFamilyFallback: AppTheme.koreanFontFallback,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final entry = widget.items[index];
                  return _StoreDocumentPreviewPane(
                    key: ValueKey<String>(entry.fileName),
                    fileName: entry.fileName,
                    loadBytes: entry.loadBytes,
                    viewTypeKey: 'gallery-$index-${entry.fileName.hashCode}',
                  );
                },
              ),
            ),
            if (showPager) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: '이전',
                      onPressed: hasPrev ? () => _goTo(_currentIndex - 1) : null,
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      color: hasPrev
                          ? FormStylePalette.textPrimary
                          : FormStylePalette.textMuted,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '좌우로 넘겨 확인',
                        style: TextStyle(
                          fontSize: 13,
                          color: FormStylePalette.textMuted,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '다음',
                      onPressed: hasNext ? () => _goTo(_currentIndex + 1) : null,
                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      color: hasNext
                          ? FormStylePalette.textPrimary
                          : FormStylePalette.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoreDocumentPreviewPane extends StatefulWidget {
  const _StoreDocumentPreviewPane({
    super.key,
    required this.fileName,
    required this.loadBytes,
    required this.viewTypeKey,
  });

  final String fileName;
  final Future<Uint8List?> Function() loadBytes;
  final String viewTypeKey;

  @override
  State<_StoreDocumentPreviewPane> createState() =>
      _StoreDocumentPreviewPaneState();
}

class _StoreDocumentPreviewPaneState extends State<_StoreDocumentPreviewPane> {
  late final Future<Uint8List?> _loadFuture = widget.loadBytes();

  @override
  void dispose() {
    revokeStoreDocumentPdfEmbed(widget.viewTypeKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = storeDocumentPreviewKindFor(widget.fileName);

    return FutureBuilder<Uint8List?>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CommonLoadingIndicator());
        }
        if (snapshot.hasError) {
          return _messageBody('문서를 불러오지 못했습니다.');
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return _messageBody('문서 파일이 없거나 읽을 수 없습니다.');
        }
        if (kind == StoreDocumentPreviewKind.unsupported) {
          return _messageBody(
            '이 파일 형식은 미리보기를 지원하지 않습니다.\n'
            '(이미지·PDF만 가능)',
          );
        }
        return _buildPreviewBody(bytes, kind);
      },
    );
  }

  Widget _messageBody(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: FormStylePalette.textMuted,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBody(Uint8List bytes, StoreDocumentPreviewKind kind) {
    return switch (kind) {
      StoreDocumentPreviewKind.image => ColoredBox(
          color: const Color(0xFFF4F4F4),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => _messageBody(
                  '이 환경에서는 이 이미지를 표시할 수 없습니다.\n'
                  '(HEIC 등 일부 형식은 미리보기가 지원되지 않을 수 있습니다)',
                ),
              ),
            ),
          ),
        ),
      StoreDocumentPreviewKind.pdf => buildStoreDocumentPdfEmbed(
          bytes: bytes,
          viewType: widget.viewTypeKey,
        ),
      StoreDocumentPreviewKind.unsupported => _messageBody(
          '미리보기를 지원하지 않는 형식입니다.',
        ),
    };
  }
}
