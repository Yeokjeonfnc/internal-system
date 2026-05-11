// 물건 목록(dev002) 필터 상태.

import 'package:app_flutter/pages/development/dev002/dev002_model.dart';

class PropertyFilter {
  const PropertyFilter({
    this.propertyKeyword = '',
    this.region = '전체',
    this.ownership,
    this.status,
  });

  /// 물건명·주소 통합 검색(부분 일치, OR).
  final String propertyKeyword;
  final String region;
  final PropertyOwnership? ownership;
  final PropertyStatus? status;

  PropertyFilter copy({
    String? propertyKeyword,
    String? region,
    PropertyOwnership? ownership,
    PropertyStatus? status,
    bool clearOwnership = false,
    bool clearStatus = false,
  }) {
    return PropertyFilter(
      propertyKeyword: propertyKeyword ?? this.propertyKeyword,
      region: region ?? this.region,
      ownership: clearOwnership ? null : ownership ?? this.ownership,
      status: clearStatus ? null : status ?? this.status,
    );
  }
}
