import 'dart:typed_data';

/// 가맹점 문서 업로드용으로 선택된 로컬 파일.
class PickedStoreDocumentFile {
  const PickedStoreDocumentFile({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}
