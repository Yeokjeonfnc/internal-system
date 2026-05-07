// 대시보드 단순 KPI 숫자 카드.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/dsh001/dsh001_kpi_model.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.item});

  final DashboardKpiModel item;

  @override
  Widget build(BuildContext context) {
    final deltaColor = item.deltaRate >= 0 ? Colors.teal : Colors.redAccent;
    final deltaLabel = item.deltaRate >= 0
        ? '+${item.deltaRate}'
        : '${item.deltaRate}';
    return Card(
      clipBehavior: Clip.antiAlias,
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
                item.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.accentRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.value} ${item.unit}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$deltaLabel%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: deltaColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
