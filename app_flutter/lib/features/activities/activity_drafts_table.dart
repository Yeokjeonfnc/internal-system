// 임시보관(동일 열) — [ErpDataTable].

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';

/// 활동관리·활동관리결재 목록이 공유하는 임시보관 격자.
class ActivityDraftsTable extends StatelessWidget {
  const ActivityDraftsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return ErpDataTable(
      minWidth: AppDimensions.tableMinWidthDefault + 400,
      tableBuilder: (context, w) {
        return Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: kErpTableInnerGridBorder,
          columnWidths: const {
            0: FlexColumnWidth(0.45),
            1: FlexColumnWidth(0.5),
            2: FlexColumnWidth(0.4),
            3: FlexColumnWidth(0.55),
            4: FlexColumnWidth(0.5),
            5: FlexColumnWidth(0.95),
            6: FlexColumnWidth(0.5),
            7: FlexColumnWidth(0.35),
            8: FlexColumnWidth(0.4),
            9: FlexColumnWidth(0.55),
            10: FlexColumnWidth(0.4),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: AppTheme.accentRed),
              children: [
                ErpTableHeaderCell('활동구분'),
                ErpTableHeaderCell('활동일자'),
                ErpTableHeaderCell('브랜드'),
                ErpTableHeaderCell('가맹점명'),
                ErpTableHeaderCell('부진점 판별결과'),
                ErpTableHeaderCell('주요상담내용'),
                ErpTableHeaderCell('담당 수퍼바이저'),
                ErpTableHeaderCell('체크리스트'),
                ErpTableHeaderCell('결재상태'),
                ErpTableHeaderCell('관리'),
                ErpTableHeaderCell('상세'),
              ],
            ),
          ],
        );
      },
    );
  }
}
