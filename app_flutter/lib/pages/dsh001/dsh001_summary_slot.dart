// 대시보드 요약 그리드 칸(KPI 또는 계약 카드) sealed 타입.

import 'package:app_flutter/pages/dsh001/dsh001_kpi_model.dart';
import 'package:app_flutter/pages/dsh001/dsh001_franchise_contract_card_data.dart';

/// 대시보드 지표 그리드의 한 칸(단순 KPI 또는 가맹계약 카드).
sealed class DashboardSummarySlot {
  const DashboardSummarySlot();
}

final class DashboardSummarySlotFranchise extends DashboardSummarySlot {
  const DashboardSummarySlotFranchise(this.data);
  final FranchiseContractCardData data;
}

final class DashboardSummarySlotSimple extends DashboardSummarySlot {
  const DashboardSummarySlotSimple(this.kpi);
  final DashboardKpiModel kpi;
}
