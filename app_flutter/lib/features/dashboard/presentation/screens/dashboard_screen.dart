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
            const SizedBox(height: 12),
            _BoardSection(tasks: vm.groupedTasks),
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

class _BoardSection extends StatelessWidget {
  const _BoardSection({required this.tasks});

  final List<String> tasks;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _DarkPanel(
            title: 'Task Board',
            child: ListView.separated(
              itemCount: tasks.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white12, height: 14),
              itemBuilder: (context, index) => Text(
                '- ${tasks[index]}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DarkPanel(
            title: 'Notice Board',
            child: Text(
              '2026-04-15  Notice  System maintenance\n2026-04-12  Notice  Mobile app update',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkPanel extends StatelessWidget {
  const _DarkPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A2F36), Color(0xFF20242A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(color: AppTheme.accentRed),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(14), child: child),
          ],
        ),
      ),
    );
  }
}
