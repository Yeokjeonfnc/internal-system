// 영업지역 등록(지도·도형 편집 — API 연동 전 골격).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/features/sales_area/sales_area_controller.dart';
import 'package:app_flutter/features/sales_area/sales_area_model.dart';

/// 리스트에서 행을 더블클릭해 진입. [rowId]는 [SalesAreaRow.id]와 대응한다.
class SalesAreaRegisterView extends ConsumerWidget {
  const SalesAreaRegisterView({super.key, required this.rowId});

  final int rowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = ref.watch(salesAreaRepositoryProvider).rowById(rowId);

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppDimensions.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.listScreenHPadding,
              12,
              AppDimensions.listScreenHPadding,
              AppDimensions.listScreenBottomPadding,
            ),
            child: row == null
                ? _NotFoundMessage(rowId: rowId)
                : _RegisterBody(row: row),
          ),
        ),
      ),
    );
  }
}

class _NotFoundMessage extends StatelessWidget {
  const _NotFoundMessage({required this.rowId});

  final int rowId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: const Color(0xFFE2E5EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          '해당 가맹점(행) 정보를 찾을 수 없습니다. (id: $rowId)',
          style: const TextStyle(
            fontSize: 15,
            color: kSearchFilterTextColor,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
    );
  }
}

class _RegisterBody extends StatelessWidget {
  const _RegisterBody({required this.row});

  final SalesAreaRow row;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          row.storeName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: FormStylePalette.textPrimary,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${row.brand} · ${row.region} · ${row.propertyName}',
          style: const TextStyle(
            fontSize: 13,
            color: kDetailHeadlineMuted,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(color: const Color(0xFFE2E5EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopFilterStrip(row: row),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          width: 240,
                          child: _LeftToolColumn(),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _MapPlaceholder(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopFilterStrip extends StatelessWidget {
  const _TopFilterStrip({required this.row});

  final SalesAreaRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '주소',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kSearchFilterTextColor,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                initialValue: '(주소 API 연동 예정 · ${row.region})',
                readOnly: true,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: false,
                onChanged: null,
                activeColor: AppTheme.accentRed,
              ),
            ),
            const Text(
              '화면내 검색',
              style: TextStyle(
                fontSize: 13,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '브랜드',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kSearchFilterTextColor,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                initialValue: row.brand,
                readOnly: true,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '보기',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kSearchFilterTextColor,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                _StubCheck('영업지역표시', true),
                _StubCheck('기준거리표시', true),
                _StubCheck('가맹점 표시', true),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _StubCheck extends StatelessWidget {
  const _StubCheck(this.label, this.value);

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: AppTheme.accentRed,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ],
    );
  }
}

class _LeftToolColumn extends StatelessWidget {
  const _LeftToolColumn();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '영업지역명',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kSearchFilterTextColor,
            ),
          ),
          const SizedBox(height: 4),
          const TextField(
            decoration: InputDecoration(
              hintText: '영업지역명을 입력하세요',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '영업지역 설정',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kSearchFilterTextColor,
            ),
          ),
          const SizedBox(height: 6),
          for (final t in [
            '다각형 그리기',
            '원형 그리기',
            '기준거리로 그리기',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: FilledButton.tonal(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  foregroundColor: AppTheme.accentRed,
                  backgroundColor: const Color(0xFFFFF1F2),
                  side: const BorderSide(color: Color(0xFFFCE7E8)),
                ),
                child: Text(
                  t,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            '거리 측정',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kSearchFilterTextColor,
            ),
          ),
          const SizedBox(height: 6),
          for (final t in ['거리 측정', '반경 측정'])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: FilledButton.tonal(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  foregroundColor: AppTheme.accentRed,
                  backgroundColor: const Color(0xFFFFF1F2),
                  side: const BorderSide(color: Color(0xFFFCE7E8)),
                ),
                child: Text(
                  t,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentRed,
              side: const BorderSide(color: AppTheme.accentRed),
            ),
            child: const Text(
              '영업지역정보',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: const Color(0xFFC9CDD3),
      ),
      child: SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 48,
                color: AppTheme.accentRed.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 10),
              const Text(
                '지도 API 연동 예정',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: FormStylePalette.textPrimary,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '카카오/네이버 등 맵·도형·거리 측정을 이 영역에 붙입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(AppDimensions.tableRadius),
    );
    final path = Path()..addRRect(r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    _drawDashedPath(canvas, path, paint, dashWidth: 6, gap: 4);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashWidth,
    required double gap,
  }) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + dashWidth).clamp(0.0, metric.length);
        final e = metric.extractPath(d, next);
        canvas.drawPath(e, paint);
        d += dashWidth + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}
