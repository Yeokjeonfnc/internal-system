import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_api.dart';
import 'package:app_flutter/pages/franchise/str001/dialogs/str001_dialog_store_document_preview.dart';

/// 게시글 목록 썸네일(첫 이미지 첨부).
class BoardListThumb extends StatefulWidget {
  const BoardListThumb({
    super.key,
    required this.postIdx,
    required this.thumbDocIdx,
    required this.api,
    required this.userId,
  });

  final int postIdx;
  final int thumbDocIdx;
  final Bbs001ApiService api;
  final String userId;

  @override
  State<BoardListThumb> createState() => _BoardListThumbState();
}

class _BoardListThumbState extends State<BoardListThumb> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.api.downloadDocumentBytes(
      postIdx: widget.postIdx,
      bbsDocIdx: widget.thumbDocIdx,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _failed = bytes == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) =>
              _placeholder(icon: Icons.broken_image_outlined),
        ),
      );
    }
    if (_failed) {
      return _placeholder(icon: Icons.broken_image_outlined);
    }
    return _placeholder(loading: true);
  }

  Widget _placeholder({IconData? icon, bool loading = false}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                icon ?? Icons.image_outlined,
                color: FormStylePalette.textSecondary,
              ),
      ),
    );
  }
}

/// 게시글 상세 본문에 표시하는 인라인 이미지.
class BoardInlineImage extends StatefulWidget {
  const BoardInlineImage({
    super.key,
    required this.postIdx,
    required this.bbsDocIdx,
    required this.fileName,
    required this.api,
    required this.userId,
    this.onTap,
  });

  final int postIdx;
  final int bbsDocIdx;
  final String fileName;
  final Bbs001ApiService api;
  final String userId;
  final VoidCallback? onTap;

  @override
  State<BoardInlineImage> createState() => _BoardInlineImageState();
}

class _BoardInlineImageState extends State<BoardInlineImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.api.downloadDocumentBytes(
      postIdx: widget.postIdx,
      bbsDocIdx: widget.bbsDocIdx,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _failed = bytes == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    Widget child;
    if (bytes != null && bytes.isNotEmpty) {
      child = Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _ImageErrorBox(),
      );
    } else if (_failed) {
      child = const _ImageErrorBox();
    } else {
      child = const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ImageErrorBox extends StatelessWidget {
  const _ImageErrorBox();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: FormStylePalette.textSecondary,
        ),
      ),
    );
  }
}

Future<void> showBoardImageGallery({
  required BuildContext context,
  required Bbs001ApiService api,
  required String userId,
  required int postIdx,
  required List<({int bbsDocIdx, String fileName})> images,
  int initialIndex = 0,
}) {
  return showStoreDocumentGalleryPreviewDialog(
    context: context,
    initialIndex: initialIndex,
    items: [
      for (final img in images)
        StoreDocumentPreviewItem(
          fileName: img.fileName,
          loadBytes: () => api.downloadDocumentBytes(
            postIdx: postIdx,
            bbsDocIdx: img.bbsDocIdx,
            userId: userId,
          ),
        ),
    ],
  );
}
