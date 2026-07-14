/// 우편번호 검색 + 지도 좌표 지정 통합 결과.
class KakaoAddressCoordinateResult {
  const KakaoAddressCoordinateResult({
    required this.zonecode,
    required this.roadAddress,
    required this.jibunAddress,
    required this.userSelectedType,
    this.buildingName = '',
    required this.latitude,
    required this.longitude,
  });

  factory KakaoAddressCoordinateResult.fromJson(Map<String, dynamic> json) {
    return KakaoAddressCoordinateResult(
      zonecode: '${json['zonecode'] ?? ''}',
      roadAddress: '${json['roadAddress'] ?? ''}',
      jibunAddress: '${json['jibunAddress'] ?? ''}',
      userSelectedType: '${json['userSelectedType'] ?? ''}',
      buildingName: '${json['buildingName'] ?? ''}',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  final String zonecode;
  final String roadAddress;
  final String jibunAddress;
  final String userSelectedType;
  final String buildingName;
  final double latitude;
  final double longitude;

  String get addressLine {
    final road = roadAddress.trim();
    final jibun = jibunAddress.trim();
    if (userSelectedType == 'R') return road.isNotEmpty ? road : jibun;
    if (userSelectedType == 'J') return jibun.isNotEmpty ? jibun : road;
    return road.isNotEmpty ? road : jibun;
  }
}
