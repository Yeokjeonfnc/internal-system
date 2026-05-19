// 폼 필드 2열·3열 가로 배치 행.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';

/// 한 행에 두 개의 필드 블록을 가로로 균등 배치하는 레이아웃.
class FormRowTwo extends StatelessWidget {
  const FormRowTwo({
    super.key,
    required this.left,
    required this.right,
    this.spacing = 16,
  });

  final Widget left;
  final Widget right;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (useCompactErpLayout(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          SizedBox(height: spacing),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: spacing),
        Expanded(child: right),
      ],
    );
  }
}

/// 한 행에 세 개의 필드 블록을 가로로 균등 배치하는 레이아웃.
class FormRowThree extends StatelessWidget {
  const FormRowThree({
    super.key,
    required this.a,
    required this.b,
    required this.c,
    this.spacing = 12,
  });

  final Widget a;
  final Widget b;
  final Widget c;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (useCompactErpLayout(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          a,
          SizedBox(height: spacing),
          b,
          SizedBox(height: spacing),
          c,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        SizedBox(width: spacing),
        Expanded(child: b),
        SizedBox(width: spacing),
        Expanded(child: c),
      ],
    );
  }
}
