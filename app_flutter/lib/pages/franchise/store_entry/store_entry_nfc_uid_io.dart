import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

String? extractNfcTagUidFromTag(NfcTag tag) {
  final androidTag = NfcTagAndroid.from(tag);
  if (androidTag != null) {
    return _bytesToUid(androidTag.id);
  }

  final mifare = MiFareIos.from(tag);
  if (mifare != null) {
    return _bytesToUid(mifare.identifier);
  }

  final iso7816 = Iso7816Ios.from(tag);
  if (iso7816 != null) {
    return _bytesToUid(iso7816.identifier);
  }

  final iso15693 = Iso15693Ios.from(tag);
  if (iso15693 != null) {
    return _bytesToUid(iso15693.identifier);
  }

  return null;
}

String _bytesToUid(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
