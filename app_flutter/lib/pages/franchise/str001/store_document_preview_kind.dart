/// 가맹점 문서 미리보기 지원 형식.
enum StoreDocumentPreviewKind {
  image,
  pdf,
  unsupported,
}

const Set<String> kStoreDocumentImageExtensions = {
  '.jpg',
  '.jpeg',
  '.jfif',
  '.jpe',
  '.png',
  '.gif',
  '.bmp',
  '.webp',
  '.heic',
  '.heif',
};

StoreDocumentPreviewKind storeDocumentPreviewKindFor(String fileName) {
  final lower = fileName.trim().toLowerCase();
  if (lower.endsWith('.pdf')) return StoreDocumentPreviewKind.pdf;
  for (final ext in kStoreDocumentImageExtensions) {
    if (lower.endsWith(ext)) return StoreDocumentPreviewKind.image;
  }
  return StoreDocumentPreviewKind.unsupported;
}

String storeDocumentPreviewMimeType(StoreDocumentPreviewKind kind) {
  return switch (kind) {
    StoreDocumentPreviewKind.pdf => 'application/pdf',
    StoreDocumentPreviewKind.image => 'image/*',
    StoreDocumentPreviewKind.unsupported => 'application/octet-stream',
  };
}
