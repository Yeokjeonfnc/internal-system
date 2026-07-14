// 게시판 본문 리치 에디터(flutter_quill) 지원 유틸 + 커스텀 이미지 임베드.
//
// 이미지는 외부 업로드/인증 로딩 대신 본문 Delta 안에 base64 data URI로 인라인
// 저장한다(목록은 본문을 내려받지 않으므로 성능 영향 없음). 표시 폭(0.3~1.0)을
// 함께 저장해 게시글마다 사진 크기를 조절할 수 있다.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image/image.dart' as img;

final Random _idRandom = Random();

// 주의: 웹(dart2js)에서는 비트시프트가 32비트라 `1 << 32`가 0이 되어
// nextInt(0)이 RangeError를 던진다. 웹·네이티브 모두 안전한 상한을 쓴다.
String _newEmbedId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${_idRandom.nextInt(0x7fffffff)}';

/// 본문 Delta 안에 들어가는 이미지 블록(data URI + 표시 폭 + 고유 id).
class BoardImageEmbed extends CustomBlockEmbed {
  const BoardImageEmbed(String value) : super(embedType, value);

  static const String embedType = 'bbsimage';

  factory BoardImageEmbed.create({
    required String dataUri,
    double width = 1.0,
    String? id,
  }) {
    return BoardImageEmbed(
      jsonEncode({
        'src': dataUri,
        'w': width.clamp(_minWidthFactor, 1.0),
        'id': id ?? _newEmbedId(),
      }),
    );
  }

  Map<String, dynamic> get _decoded {
    try {
      final m = jsonDecode(data);
      if (m is Map<String, dynamic>) return m;
    } catch (_) {}
    return const {};
  }

  String get src => (_decoded['src'] ?? '').toString();

  String get id => (_decoded['id'] ?? '').toString();

  double get width {
    final w = (_decoded['w'] as num?)?.toDouble() ?? 1.0;
    return w.clamp(_minWidthFactor, 1.0);
  }
}

/// 사진 최소 표시 폭(컨테이너 폭 대비 비율).
const double _minWidthFactor = 0.15;

/// 문서에서 주어진 id를 가진 이미지 임베드의 문서 오프셋을 찾는다.
/// (커스텀 임베드는 렌더 시 노드가 새로 생성돼 documentOffset이 무효하므로
///  Delta를 순회해 직접 계산한다.)
int? boardFindImageEmbedOffset(Document document, String id) {
  var offset = 0;
  for (final op in document.toDelta().toList()) {
    final data = op.data;
    if (data is Map && data['custom'] is String) {
      if (_customEmbedImageId(data['custom'] as String) == id) return offset;
    }
    offset += op.length ?? 1;
  }
  return null;
}

String? _customEmbedImageId(String customData) {
  try {
    final outer = jsonDecode(customData);
    if (outer is Map && outer[BoardImageEmbed.embedType] is String) {
      final inner = jsonDecode(outer[BoardImageEmbed.embedType] as String);
      if (inner is Map) return inner['id']?.toString();
    }
  } catch (_) {}
  return null;
}

/// 에디터/뷰어 공통 이미지 임베드 렌더러.
class BoardImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BoardImageEmbed.embedType;

  @override
  String toPlainText(Embed node) => '[사진]';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final embed = BoardImageEmbed(embedContext.node.value.data as String);
    final bytes = decodeImageDataUri(embed.src);
    final readOnly = embedContext.readOnly;

    // 실제 컨테이너(에디터/본문) 폭 기준으로 표시 폭을 잡는다. 화면 폭을 쓰면
    // 데스크톱/웹에서 컨테이너보다 넓어 항상 꽉 차게 나온다.
    final sized = LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final targetW = (available * embed.width).clamp(60.0, available);
        final Widget image = bytes == null
            ? const _BrokenImageBox()
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytes,
                  width: targetW,
                  fit: BoxFit.fitWidth,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const _BrokenImageBox(),
                ),
              );
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: targetW, child: image),
        );
      },
    );

    if (readOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: sized,
      );
    }

    // 편집 모드: 우하단 핸들을 드래그해 크기 조절, 탭하면 삭제 메뉴.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _ResizableEmbedImage(
        bytes: bytes,
        embed: embed,
        onResized: (w) => _applyWidth(embedContext, embed, w),
        onMenu: () => _showImageMenu(context, embedContext, embed),
      ),
    );
  }

  /// 드래그 종료 시 새 표시 폭을 문서에 반영.
  void _applyWidth(EmbedContext embedContext, BoardImageEmbed embed, double w) {
    final controller = embedContext.controller;
    final offset = boardFindImageEmbedOffset(controller.document, embed.id);
    if (offset == null) return;
    controller.replaceText(
      offset,
      1,
      BlockEmbed.custom(
        BoardImageEmbed.create(dataUri: embed.src, width: w, id: embed.id),
      ),
      TextSelection.collapsed(offset: offset + 1),
    );
  }

  Future<void> _showImageMenu(
    BuildContext context,
    EmbedContext embedContext,
    BoardImageEmbed embed,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              dense: true,
              title: Text(
                '사진 크기',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_size_select_small),
              title: const Text('작게'),
              onTap: () => Navigator.pop(ctx, 'w:0.4'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_size_select_large),
              title: const Text('중간'),
              onTap: () => Navigator.pop(ctx, 'w:0.7'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_size_select_actual),
              title: const Text('크게'),
              onTap: () => Navigator.pop(ctx, 'w:1.0'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('사진 삭제'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;

    final controller = embedContext.controller;
    final offset = boardFindImageEmbedOffset(controller.document, embed.id);
    if (offset == null) return;

    if (action == 'delete') {
      controller.replaceText(
        offset,
        1,
        '',
        TextSelection.collapsed(offset: offset),
      );
      return;
    }
    if (action.startsWith('w:')) {
      final w = double.tryParse(action.substring(2)) ?? 1.0;
      controller.replaceText(
        offset,
        1,
        BlockEmbed.custom(
          BoardImageEmbed.create(dataUri: embed.src, width: w, id: embed.id),
        ),
        TextSelection.collapsed(offset: offset + 1),
      );
    }
  }
}

/// 편집 모드 이미지: 우하단 핸들 드래그로 크기를 조절한다.
///
/// 드래그 중에는 [_liveWidth]로 로컬 미리보기만 하고, 손을 떼는 순간 한 번만
/// 문서를 갱신([onResized])해 매 프레임 Delta 변경으로 인한 끊김·커서 튐을 막는다.
class _ResizableEmbedImage extends StatefulWidget {
  const _ResizableEmbedImage({
    required this.bytes,
    required this.embed,
    required this.onResized,
    required this.onMenu,
  });

  final Uint8List? bytes;
  final BoardImageEmbed embed;
  final ValueChanged<double> onResized;
  final VoidCallback onMenu;

  @override
  State<_ResizableEmbedImage> createState() => _ResizableEmbedImageState();
}

class _ResizableEmbedImageState extends State<_ResizableEmbedImage> {
  double? _liveWidth;
  double _available = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final factor = (_liveWidth ?? widget.embed.width).clamp(
          _minWidthFactor,
          1.0,
        );
        final targetW = (_available * factor).clamp(60.0, _available);

        final Widget image = widget.bytes == null
            ? const _BrokenImageBox()
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  widget.bytes!,
                  width: targetW,
                  fit: BoxFit.fitWidth,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const _BrokenImageBox(),
                ),
              );

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: targetW,
            child: Stack(
              children: [
                image,
                // 삭제/프리셋 메뉴 (좌상단 탭).
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: widget.onMenu,
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.tune, size: 14, color: Colors.white),
                    ),
                  ),
                ),
                // 우하단 크기 조절 핸들.
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (d) {
                      if (_available <= 0) return;
                      final current = (_liveWidth ?? widget.embed.width);
                      final next = (current + d.delta.dx / _available).clamp(
                        _minWidthFactor,
                        1.0,
                      );
                      setState(() => _liveWidth = next.toDouble());
                    },
                    onPanEnd: (_) {
                      final w = _liveWidth;
                      if (w != null) widget.onResized(w);
                      setState(() => _liveWidth = null);
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xCC212529),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.open_in_full,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrokenImageBox extends StatelessWidget {
  const _BrokenImageBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}

/// 본문 문자열이 Quill Delta(JSON 배열)인지 판별.
bool boardBodyIsQuillDelta(String body) {
  final t = body.trim();
  if (!t.startsWith('[')) return false;
  try {
    return jsonDecode(t) is List;
  } catch (_) {
    return false;
  }
}

/// 저장된 본문 → Quill [Document]. Delta가 아니면 순수 텍스트 문서로 만든다.
Document boardBodyToDocument(String body) {
  if (boardBodyIsQuillDelta(body)) {
    try {
      return Document.fromJson(jsonDecode(body) as List);
    } catch (_) {}
  }
  final doc = Document();
  final text = body.trim().isEmpty ? '' : body;
  if (text.isNotEmpty) doc.insert(0, text);
  return doc;
}

/// [Document] → 저장용 Delta JSON 문자열.
String boardDocumentToBody(Document document) {
  return jsonEncode(document.toDelta().toJson());
}

/// 매직 바이트로 이미지 MIME 추정(웹 인라인 저장용).
String _guessImageMime(Uint8List b) {
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47) {
    return 'image/png';
  }
  if (b.length >= 3 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) {
    return 'image/gif';
  }
  if (b.length >= 12 &&
      b[0] == 0x52 &&
      b[1] == 0x49 &&
      b[2] == 0x46 &&
      b[3] == 0x46 &&
      b[8] == 0x57 &&
      b[9] == 0x45 &&
      b[10] == 0x42 &&
      b[11] == 0x50) {
    return 'image/webp';
  }
  return 'image/png';
}

/// data URI(base64) → 이미지 바이트.
Uint8List? decodeImageDataUri(String src) {
  final marker = src.indexOf('base64,');
  if (marker < 0) return null;
  try {
    return base64Decode(src.substring(marker + 'base64,'.length));
  } catch (_) {
    return null;
  }
}

/// 이미지 바이트를 표시에 적당한 크기로 줄여 base64 data URI로 만든다.
///
/// 큰 사진을 그대로 본문에 넣으면 base64가 수 MB가 되어 에디터가 멈추므로
/// [maxWidth]로 축소 후 JPEG로 재인코딩한다. 네이티브는 [compute]로 별도
/// isolate에서 처리해 UI 끊김을 막고, 웹은 동기로 처리한다.
Future<String> encodeImageToDataUri(
  Uint8List bytes, {
  int maxWidth = 1280,
  int quality = 80,
}) async {
  final args = _ResizeArgs(bytes, maxWidth, quality);
  if (kIsWeb) return _resizeToDataUri(args);
  try {
    return await compute(_resizeToDataUri, args);
  } catch (_) {
    return _resizeToDataUri(args);
  }
}

class _ResizeArgs {
  const _ResizeArgs(this.bytes, this.maxWidth, this.quality);
  final Uint8List bytes;
  final int maxWidth;
  final int quality;
}

/// 디코드 → (필요 시) 축소 → JPEG 인코딩. 실패하면 원본을 그대로 base64.
String _resizeToDataUri(_ResizeArgs a) {
  try {
    final decoded = img.decodeImage(a.bytes);
    if (decoded == null) {
      return 'data:${_guessImageMime(a.bytes)};base64,${base64Encode(a.bytes)}';
    }
    final resized = decoded.width > a.maxWidth
        ? img.copyResize(decoded, width: a.maxWidth)
        : decoded;
    final jpg = img.encodeJpg(resized, quality: a.quality);
    return 'data:image/jpeg;base64,${base64Encode(jpg)}';
  } catch (_) {
    return 'data:${_guessImageMime(a.bytes)};base64,${base64Encode(a.bytes)}';
  }
}
