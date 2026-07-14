import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'picked_store_document_file.dart';

Future<Uint8List?> _bytesFromPlatformFile(PlatformFile file) async {
  var bytes = file.bytes;
  if ((bytes == null || bytes.isEmpty) && file.readStream != null) {
    final chunks = <int>[];
    await for (final chunk in file.readStream!) {
      chunks.addAll(chunk);
    }
    bytes = Uint8List.fromList(chunks);
  }
  if (bytes == null || bytes.isEmpty) return null;
  return bytes;
}

/// 웹에서도 `file_picker`로 파일을 고른다(과거 `dart:html` 구현은 최신 웹에서
/// 불안정해 제거). `withData: true`로 바이트를 바로 받는다.
Future<List<PickedStoreDocumentFile>> pickStoreDocumentFilesImpl() async {
  final picked = await FilePicker.platform.pickFiles(
    withData: true,
    allowMultiple: true,
  );
  if (picked == null || picked.files.isEmpty) return const [];

  final out = <PickedStoreDocumentFile>[];
  for (final file in picked.files) {
    final bytes = await _bytesFromPlatformFile(file);
    if (bytes == null) continue;
    out.add(PickedStoreDocumentFile(name: file.name, bytes: bytes));
  }
  return out;
}
