import 'picked_store_document_file.dart';
import 'store_document_file_picker_stub.dart'
    if (dart.library.io) 'store_document_file_picker_io.dart'
    if (dart.library.html) 'store_document_file_picker_web.dart';

/// 로컬 문서·이미지 파일을 하나 이상 선택한다.
Future<List<PickedStoreDocumentFile>> pickStoreDocumentFiles() {
  return pickStoreDocumentFilesImpl();
}

/// 단일 파일 선택 — [pickStoreDocumentFiles] 의 첫 항목.
Future<PickedStoreDocumentFile?> pickStoreDocumentFile() async {
  final files = await pickStoreDocumentFiles();
  return files.isEmpty ? null : files.first;
}
