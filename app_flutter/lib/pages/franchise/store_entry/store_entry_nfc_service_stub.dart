/// 웹·데스크톱 등 NFC 미지원 환경.
class StoreEntryNfcService {
  const StoreEntryNfcService();

  Future<bool> get isAvailable async => false;

  Future<void> startScan({
    required void Function(String tagUid) onTagDiscovered,
  }) async {}

  Future<void> releaseScanSession({Duration hold = Duration.zero}) async {}

  Future<void> stopScan() async {}
}
