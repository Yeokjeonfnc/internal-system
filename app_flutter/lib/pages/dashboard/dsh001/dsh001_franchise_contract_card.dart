// 대시보드 가맹계약/개점 요약 카드 UI.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/dashboard/dsh001/dsh001_franchise_contract_card_data.dart';

/// 본문·보조 숫자용 (파일 전역 — 서브위젯에서도 동일 참조).
const Color _kFranchiseBodyMuted = Color(0xFF6B7280);
const Color _kFranchiseDivider = Color(0xFFE5E7EB);

/// 가맹계약/개점 요약 — [KpiCard]와 동일한 밝은 카드·빨간 포인트 테마.
class FranchiseContractCard extends StatelessWidget {
  const FranchiseContractCard({super.key, required this.data});

  final FranchiseContractCardData data;

  @override
  Widget build(BuildContext context) {
    final headline = Theme.of(context).textTheme.headlineSmall;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                data.title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.accentRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${data.numeratorPrefix}${data.numerator}',
                        style: headline?.copyWith(
                          color: AppTheme.accentRed,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: '/${data.denominator}',
                        style: headline?.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: data.unit,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.accentRed,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _DottedRule(color: _kFranchiseDivider.withValues(alpha: 0.9)),
            const SizedBox(height: 8),
            _DetailLine(
              children: [
                const TextSpan(text: '총 '),
                TextSpan(
                  text: '${data.totalStores}',
                  style: const TextStyle(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '개점'),
              ],
            ),
            const SizedBox(height: 8),
            _DottedRule(color: _kFranchiseDivider.withValues(alpha: 0.9)),
            const SizedBox(height: 8),
            _DetailLine(
              children: [
                const TextSpan(text: '상담 '),
                TextSpan(text: '${data.consultCount}'),
                const TextSpan(text: ', 신규 '),
                TextSpan(
                  text: '${data.newCount}',
                  style: const TextStyle(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ', 개점 '),
                TextSpan(
                  text: '${data.openCount}',
                  style: const TextStyle(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DottedRule(color: _kFranchiseDivider.withValues(alpha: 0.9)),
            const SizedBox(height: 8),
            _DetailLine(
              children: [
                const TextSpan(text: '만료예정 '),
                TextSpan(
                  text: '${data.expiringSoonCount}',
                  style: const TextStyle(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ', 해지 '),
                TextSpan(
                  text: '${data.terminatedCount}',
                  style: const TextStyle(
                    color: _kFranchiseBodyMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.children});

  final List<InlineSpan> children;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _kFranchiseBodyMuted,
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
        children: children,
      ),
    );
  }
}

class _DottedRule extends StatelessWidget {
  const _DottedRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, 1),
          painter: _DottedLinePainter(color: color),
        );
      },
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double x = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
