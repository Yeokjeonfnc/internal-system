import 'package:flutter/material.dart';

class SalesAreaSearchMapFrame extends StatelessWidget {
  const SalesAreaSearchMapFrame({super.key});

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
