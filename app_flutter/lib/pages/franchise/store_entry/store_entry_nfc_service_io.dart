import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import 'package:app_flutter/pages/franchise/store_entry/store_entry_nfc_uid.dart';

/// 태그 인식 직후 Reader Mode를 끄면 태그가 계속 감지될 때 시스템이 CJ ONE 등으로 넘긴다.
/// 인식 후 [kReaderModeHoldAfterTag] 동안 Reader Mode를 유지한다.
const Duration kReaderModeHoldAfterTag = Duration(seconds: 3);

class StoreEntryNfcService {
  const StoreEntryNfcService();

  static int _sessionId = 0;
  static bool _readerModeEnabled = false;
  static bool _tagConsumed = false;
  static Timer? _releaseTimer;

  Future<bool> get isAvailable async {
    final availability = await NfcManager.instance.checkAvailability();
    return availability == NfcAvailability.enabled;
  }

  Future<void> startScan({
    required void Function(String tagUid) onTagDiscovered,
  }) async {
    await _cancelPendingRelease();
    final sessionId = ++_sessionId;
    _tagConsumed = false;

    final available = await isAvailable;
    if (!available) {
      throw StateError('NFC를 사용할 수 없습니다. 기기 설정을 확인해 주세요.');
    }

    void handleTag(NfcTag tag) {
      if (sessionId != _sessionId || _tagConsumed) return;
      final uid = extractNfcTagUid(tag);
      debugPrint('[StoreEntryNfc] tag discovered uid=$uid tag=$tag');
      if (uid == null || uid.isEmpty) return;
      _tagConsumed = true;
      onTagDiscovered(normalizeNfcTagUid(uid));
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await NfcManagerAndroid.instance.enableReaderMode(
        flags: const {
          NfcReaderFlagAndroid.nfcA,
          NfcReaderFlagAndroid.nfcB,
          NfcReaderFlagAndroid.nfcV,
          NfcReaderFlagAndroid.skipNdefCheck,
          NfcReaderFlagAndroid.noPlatformSounds,
        },
        onTagDiscovered: handleTag,
      );
      _readerModeEnabled = true;
      return;
    }

    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      alertMessageIos: '휴대폰을 NFC 태그에 가까이 대 주세요.',
      onDiscovered: handleTag,
    );
    _readerModeEnabled = true;
  }

  /// 태그 인식·처리 후 Reader Mode를 잠시 유지한 뒤 종료한다.
  Future<void> releaseScanSession({
    Duration hold = kReaderModeHoldAfterTag,
  }) async {
    if (!_readerModeEnabled) return;
    await _cancelPendingRelease();
    final sessionId = _sessionId;
    final completer = Completer<void>();
    _releaseTimer = Timer(hold, () async {
      if (sessionId != _sessionId) {
        if (!completer.isCompleted) completer.complete();
        return;
      }
      await _disableReaderMode();
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  /// 취소 등 — 즉시 Reader Mode 종료.
  Future<void> stopScan() async {
    _sessionId++;
    _tagConsumed = false;
    await _cancelPendingRelease();
    await _disableReaderMode();
  }

  Future<void> _cancelPendingRelease() async {
    final timer = _releaseTimer;
    _releaseTimer = null;
    timer?.cancel();
  }

  Future<void> _disableReaderMode() async {
    if (!_readerModeEnabled) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await NfcManagerAndroid.instance.disableReaderMode();
      } else {
        await NfcManager.instance.stopSession();
      }
    } catch (e, st) {
      debugPrint('[StoreEntryNfc] disable reader mode: $e\n$st');
    } finally {
      _readerModeEnabled = false;
    }
  }
}
