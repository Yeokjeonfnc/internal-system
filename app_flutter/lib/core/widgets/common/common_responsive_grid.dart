// 카드형 위젯을 화면 너비에 맞춰 자동으로 줄바꿈하는 반응형 그리드.
//
// 카드마다 최소 너비를 기준으로 열 수를 계산해 Wrap 으로 배치한다.
// 좁아질수록 1100px 같은 단일 기준점에서 갑자기 전부 세로로 쌓이는 대신,
// 너비에 맞춰 4열→3열→2열→1열로 매끄럽게 줄어든다.

import 'package:flutter/widgets.dart';

class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.children,
    required this.minItemWidth,
    this.spacing = 16,
    this.runSpacing = 16,
    this.maxColumns,
  });

  final List<Widget> children;

  /// 카드 하나가 가질 수 있는 최소 너비. 이보다 좁아지면 다음 줄로 넘어간다.
  final double minItemWidth;
  final double spacing;
  final double runSpacing;

  /// 지정하면 너비가 아무리 넓어도 이 열 수를 넘지 않는다.
  final int? maxColumns;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var columns = ((width + spacing) / (minItemWidth + spacing)).floor();
        if (columns < 1) columns = 1;
        if (columns > children.length) columns = children.length;
        if (maxColumns != null && columns > maxColumns!) columns = maxColumns!;

        final itemWidth =
            ((width - spacing * (columns - 1)) / columns).floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
