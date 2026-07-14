import 'package:nfc_manager/nfc_manager.dart';

import 'store_entry_nfc_uid_stub.dart'
    if (dart.library.io) 'store_entry_nfc_uid_io.dart';

/// NFC 태그 UID (콜론 제거, 대문자 HEX).
String normalizeNfcTagUid(String raw) =>
    raw.replaceAll(':', '').replaceAll('-', '').replaceAll(' ', '').trim().toUpperCase();

/// 플랫폼별 UID 추출 — 웹·데스크톱은 null.
String? extractNfcTagUid(NfcTag tag) => extractNfcTagUidFromTag(tag);
