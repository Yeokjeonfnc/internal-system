import 'package:flutter/material.dart';

import 'package:app_flutter/pages/development/dev003/dev003_model.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_editor_view_options.dart';

class SalesAreaEditorMapFrame extends StatefulWidget {
  const SalesAreaEditorMapFrame({
    super.key,
    required this.row,
    required this.zoneNameController,
    required this.viewOptions,
    required this.onSaved,
    this.readOnly = false,
    this.brandCd,
    this.brandLabel,
    this.onSaveError,
    this.onAddressResolved,
    this.onDetailLoaded,
    this.initialDetail,
  });

  final SalesAreaRow row;
  final bool readOnly;
  final TextEditingController zoneNameController;
  final SalesAreaEditorViewOptions viewOptions;
  final String? brandCd;
  final String? brandLabel;
  final VoidCallback onSaved;
  final void Function(String message)? onSaveError;
  final ValueChanged<String>? onAddressResolved;
  final ValueChanged<SalesAreaRow>? onDetailLoaded;
  final SalesAreaRow? initialDetail;

  @override
  State<SalesAreaEditorMapFrame> createState() => SalesAreaEditorMapFrameState();
}

class SalesAreaEditorMapFrameState extends State<SalesAreaEditorMapFrame> {
  void sendCommand(String cmd) {}
  void searchAddress(String keyword) {}
  void setMapPointerEvents(bool enabled) {}

  void requestSaveFromMap() {}

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '영업지역 지도 편집은 Flutter Web에서 사용할 수 있습니다.',
        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      ),
    );
  }
}
