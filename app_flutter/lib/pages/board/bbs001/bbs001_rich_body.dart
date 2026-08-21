import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_api.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_attachment_image.dart';

/// 본문(JSON)의 한 블록 — 텍스트이거나 이미지(첨부 docIdx + 표시 폭) 중 하나.
class BoardBodyBlock {
  const BoardBodyBlock.text(this.text) : imageDocIdx = null, imageWidth = 1.0;

  const BoardBodyBlock.image({required int docIdx, required double width})
    : text = null,
      imageDocIdx = docIdx,
      imageWidth = width;

  /// 텍스트 블록이면 내용, 이미지 블록이면 `null`.
  final String? text;

  /// 이미지 블록이면 첨부 문서 idx, 텍스트 블록이면 `null`.
  final int? imageDocIdx;

  /// 이미지 표시 폭(본문 가용 폭 대비 0.3~1.0).
  final double imageWidth;

  bool get isImage => imageDocIdx != null;
}

/// 게시글 본문. 신규 글은 JSON(블록 배열)으로 저장하고, 과거 글(순수 텍스트)은
/// 단일 텍스트 블록으로 취급한다.
class BoardRichBody {
  const BoardRichBody({required this.blocks, required this.isRich});

  final List<BoardBodyBlock> blocks;

  /// JSON(블록) 형식으로 저장된 본문이면 `true`. 과거 순수 텍스트면 `false`.
  final bool isRich;

  static const String _marker = 'bbsRich';

  /// 저장된 본문 문자열을 파싱한다. JSON 블록이 아니면 단일 텍스트 블록으로 본다.
  factory BoardRichBody.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{') && trimmed.contains(_marker)) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map &&
            decoded[_marker] == 1 &&
            decoded['blocks'] is List) {
          final blocks = <BoardBodyBlock>[];
          for (final b in (decoded['blocks'] as List)) {
            if (b is! Map) continue;
            final img = b['img'];
            if (img is Map && img['doc'] != null) {
              final doc = (img['doc'] as num).toInt();
              final w = (img['w'] as num?)?.toDouble() ?? 1.0;
              blocks.add(
                BoardBodyBlock.image(docIdx: doc, width: w.clamp(0.3, 1.0)),
              );
            } else if (b['text'] != null) {
              blocks.add(BoardBodyBlock.text(b['text'].toString()));
            }
          }
          return BoardRichBody(blocks: blocks, isRich: true);
        }
      } catch (_) {
        // JSON 파싱 실패 시 순수 텍스트로 폴백.
      }
    }
    return BoardRichBody(blocks: [BoardBodyBlock.text(raw)], isRich: false);
  }

  /// 블록 목록을 저장용 JSON 문자열로 직렬화한다.
  static String encode(List<BoardBodyBlock> blocks) {
    return jsonEncode({
      _marker: 1,
      'blocks': [
        for (final b in blocks)
          if (b.isImage)
            {
              'img': {'doc': b.imageDocIdx, 'w': b.imageWidth},
            }
          else
            {'text': b.text ?? ''},
      ],
    });
  }

  /// 본문에서 사용 중인 이미지 첨부 idx 집합.
  Set<int> get usedImageDocIdxs => {
    for (final b in blocks)
      if (b.imageDocIdx != null) b.imageDocIdx!,
  };
}

/// 상세 보기에서 리치 본문(텍스트+사진)을 순서대로 렌더링한다.
class BoardRichBodyView extends StatelessWidget {
  const BoardRichBodyView({
    super.key,
    required this.body,
    required this.postIdx,
    required this.api,
    required this.userId,
    this.onTapImage,
  });

  final BoardRichBody body;
  final int postIdx;
  final Bbs001ApiService api;
  final String userId;

  /// 이미지를 탭했을 때(갤러리 등). 인자는 해당 이미지의 docIdx.
  final void Function(int docIdx)? onTapImage;

  @override
  Widget build(BuildContext context) {
    final blocks = body.blocks;
    final hasContent = blocks.any(
      (b) => b.isImage || (b.text?.trim().isNotEmpty ?? false),
    );
    if (!hasContent) {
      return const Text('(내용 없음)', style: kSearchFilterValueTextStyle);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final block in blocks)
              if (block.isImage)
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: (maxW * block.imageWidth).clamp(80.0, maxW),
                    child: BoardInlineImage(
                      postIdx: postIdx,
                      bbsDocIdx: block.imageDocIdx!,
                      fileName: '',
                      api: api,
                      userId: userId,
                      onTap: onTapImage == null
                          ? null
                          : () => onTapImage!(block.imageDocIdx!),
                    ),
                  ),
                )
              else if ((block.text?.trim().isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(block.text!, style: kSearchFilterValueTextStyle),
                ),
          ],
        );
      },
    );
  }
}

/// 사진 크기 조절 라벨(슬라이더 보조 표시).
String boardImageWidthLabel(double w) {
  if (w <= 0.45) return '작게';
  if (w <= 0.75) return '중간';
  return '크게';
}
