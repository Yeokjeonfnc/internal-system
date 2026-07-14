import 'package:flutter/material.dart';

import 'package:app_flutter/pages/development/dev003/dev003_search_map_model.dart';

import 'package:app_flutter/pages/development/dev003/map/sales_area_search_view_options.dart';

class SalesAreaSearchMapFrame extends StatefulWidget {
  const SalesAreaSearchMapFrame({
    super.key,
    this.viewOptions = kSalesAreaSearchViewDefaults,
    this.onStats,
    this.onMapError,
  });

  final SalesAreaSearchViewOptions viewOptions;
  final ValueChanged<SalesAreaMapStats>? onStats;
  final ValueChanged<String>? onMapError;

  @override
  State<SalesAreaSearchMapFrame> createState() => SalesAreaSearchMapFrameState();
}

class SalesAreaSearchMapFrameState extends State<SalesAreaSearchMapFrame> {
  void filterKeyword(String keyword) {}
  void searchAddress(String keyword) {}

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF8FAFC),
      child: Center(
        child: Text(
          '영업지역 지도는 Flutter Web에서 사용할 수 있습니다.',
          style: TextStyle(
            color: Color(0xFF52606D),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
