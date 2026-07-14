import 'package:geolocator/geolocator.dart';

import 'package:app_flutter/pages/franchise/store_entry/store_entry_model.dart';

class StoreEntryLocationService {
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// 최근 위치(캐시). GPS 재획득 전 화면을 먼저 채울 때 사용.
  Future<StoreEntryLocation?> lastKnown() async {
    final pos = await Geolocator.getLastKnownPosition();
    if (pos == null) return null;
    return StoreEntryLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }

  Future<StoreEntryLocation> current() async {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        // 1.5km 반경 검색에는 low 정확도로 충분하고 훨씬 빠르다.
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return StoreEntryLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }
}
