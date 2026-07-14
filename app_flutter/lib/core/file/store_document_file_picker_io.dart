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
