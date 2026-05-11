import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

/// 화면/다이얼로그 공통 로딩 인디케이터.
class CommonLoadingIndicator extends StatelessWidget {
  const CommonLoadingIndicator({super.key, this.size = 30, this.strokeWidth = 3});

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: AppTheme.accentRed,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
