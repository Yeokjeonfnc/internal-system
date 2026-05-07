// 대시보드 요약 데이터 Riverpod ViewModel.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/pages/dsh001/dsh001_franchise_contract_card_data.dart';
import 'package:app_flutter/pages/dsh001/dsh001_kpi_model.dart';
import 'package:app_flutter/pages/dsh001/dsh001_summary_slot.dart';

final dashboardViewModelProvider =
    NotifierProvider<DashboardViewModelNotifier, DashboardViewModel>(
      DashboardViewModelNotifier.new,
    );

class DashboardViewModelNotifier extends Notifier<DashboardViewModel> {
  @override
  DashboardViewModel build() => const DashboardViewModel();
}

class DashboardViewModel {
  const DashboardViewModel();

  /// 사이드바 하단 프로필 (추후 인증 연동 시 교체).
  String get sessionUserName => '김민효';
  String get sessionUserRole => '관리자';

  static const FranchiseContractCardData _franchiseContract =
      FranchiseContractCardData(
        title: '가맹계약/개점',
        numerator: 2,
        denominator: 3,
        numeratorPrefix: '+',
        unit: '건',
        totalStores: 1037,
        consultCount: 0,
        newCount: 2,
        openCount: 3,
        expiringSoonCount: 44,
        terminatedCount: 0,
      );

  /// 그리드 한 칸씩: 가맹계약 카드 + 기존 단순 KPI.
  List<DashboardSummarySlot> get summarySlots => const [
    DashboardSummarySlotFranchise(_franchiseContract),
    DashboardSummarySlotSimple(
      DashboardKpiModel(label: '활동 등록', value: 142, unit: '건', deltaRate: 5.6),
    ),
    DashboardSummarySlotSimple(
      DashboardKpiModel(
        label: '출입 이벤트',
        value: 624,
        unit: '건',
        deltaRate: -1.2,
      ),
    ),
  ];
}
