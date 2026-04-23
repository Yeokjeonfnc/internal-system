// 대시보드 요약 데이터 Riverpod ViewModel.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dashboard_kpi_model.dart';
import '../../data/models/dashboard_summary_slot.dart';
import '../../data/models/franchise_contract_card_data.dart';

final dashboardViewModelProvider = NotifierProvider<
    DashboardViewModelNotifier, DashboardViewModel>(
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

  List<String> get groupedTasks => const [
    '가맹점 계약 만료 예정 4건 확인',
    '영업지역 재배정 요청 2건 승인',
    '출입 관리 모바일 정책 점검',
    '활동 일지 미작성 지점 팔로업',
  ];
}
