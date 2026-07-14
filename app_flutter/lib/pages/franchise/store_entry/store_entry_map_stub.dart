import 'package:flutter/material.dart';

class StoreEntryMapFrame extends StatelessWidget {
  const StoreEntryMapFrame({
    super.key,
    required this.latitude,
    required this.longitude,
    this.onAddressResolved,
  });

  final double latitude;
  final double longitude;
  final ValueChanged<String>? onAddressResolved;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE8EAED),
      child: Center(
        child: Text(
          '출입 관리 지도는 모바일 앱에서만 지원합니다.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}
