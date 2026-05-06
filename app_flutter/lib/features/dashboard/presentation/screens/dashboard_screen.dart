// 메인 대시보드 화면(지표·계약 카드 그리드).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/dashboard_summary_slot.dart';
import '../view_models/dashboard_view_model.dart';
import '../widgets/franchise_contract_card.dart';
import '../widgets/kpi_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(dashboardViewModelProvider);
    return ColoredBox(
      color: AppTheme.appSurface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DashboardSummaryGrid(slots: vm.summarySlots),
          ],
        ),
      ),
    );
  }
}

class _DashboardSummaryGrid extends StatelessWidget {
  const _DashboardSummaryGrid({required this.slots});

  final List<DashboardSummarySlot> slots;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 1500
        ? 4
        : width > 1200
        ? 3
        : 2;

    return GridView.builder(
      itemCount: slots.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final slot = slots[index];
        return switch (slot) {
          DashboardSummarySlotFranchise(:final data) => FranchiseContractCard(
            data: data,
          ),
          DashboardSummarySlotSimple(:final kpi) => KpiCard(item: kpi),
        };
      },
    );
  }
}
