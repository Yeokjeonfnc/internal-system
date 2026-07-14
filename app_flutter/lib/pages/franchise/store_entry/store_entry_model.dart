/// GPS 기준 주변 가맹점 한 행.
class NearbyStoreRow {
  const NearbyStoreRow({
    required this.storeIdx,
    required this.storeNm,
    this.brandLabel = '',
    required this.distanceM,
    required this.lat,
    required this.lng,
  });

  final int storeIdx;
  final String storeNm;
  final String brandLabel;
  final int distanceM;
  final double lat;
  final double lng;

  String get distanceLabel {
    if (distanceM < 1000) return '${distanceM}m';
    final km = distanceM / 1000;
    return km >= 10 ? '${km.round()}km' : '${km.toStringAsFixed(1)}km';
  }
}

/// NFC UID로 조회한 가맹점 정보.
class StoreNfcTagLookup {
  const StoreNfcTagLookup({
    required this.storeIdx,
    required this.storeNm,
    this.brandNm = '',
    required this.latitude,
    required this.longitude,
    required this.tagUid,
  });

  final int storeIdx;
  final String storeNm;
  final String brandNm;
  final double latitude;
  final double longitude;
  final String tagUid;

  factory StoreNfcTagLookup.fromJson(Map<String, dynamic> json) {
    return StoreNfcTagLookup(
      storeIdx: (json['storeIdx'] as num?)?.toInt() ?? 0,
      storeNm: json['storeNm']?.toString() ?? '',
      brandNm: json['brandNm']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      tagUid: json['tagUid']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class StoreEntryLocation {
  const StoreEntryLocation({
    required this.latitude,
    required this.longitude,
    this.address = '',
  });

  final double latitude;
  final double longitude;
  final String address;

  String get displayAddress {
    final a = address.trim();
    if (a.isNotEmpty) return a;
    return '위도 ${latitude.toStringAsFixed(5)}, 경도 ${longitude.toStringAsFixed(5)}';
  }
}

/// 가맹점에 등록된 NFC 태그.
class StoreNfcTagRegistration {
  const StoreNfcTagRegistration({
    required this.storeIdx,
    required this.tagUid,
    this.useYn = 'Y',
  });

  final int storeIdx;
  final String tagUid;
  final String useYn;

  factory StoreNfcTagRegistration.fromJson(Map<String, dynamic> json) {
    return StoreNfcTagRegistration(
      storeIdx: (json['storeIdx'] as num?)?.toInt() ?? 0,
      tagUid: json['tagUid']?.toString() ?? '',
      useYn: json['useYn']?.toString() ?? 'Y',
    );
  }
}
