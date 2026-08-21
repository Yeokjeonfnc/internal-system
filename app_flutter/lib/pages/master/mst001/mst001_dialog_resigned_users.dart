// 사원관리 — 퇴사자 목록 팝업.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/format/korean_phone_display.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/master/mst001/mst001_api.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';

/// 퇴사자 목록을 표 형태로 보여준다(관리자 전용).
Future<void> showResignedUsersDialog(
  BuildContext context,
  Mst001ApiService api,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _ResignedUsersDialog(api: api),
  );
}

class _ResignedUsersDialog extends StatefulWidget {
  const _ResignedUsersDialog({required this.api});

  final Mst001ApiService api;

  @override
  State<_ResignedUsersDialog> createState() => _ResignedUsersDialogState();
}

class _ResignedUsersDialogState extends State<_ResignedUsersDialog> {
  late Future<List<User>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getResignedUsers();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final dialogWidth = (screen.width * 0.88).clamp(750.0, 850.0);

    return AlertDialog(
      title: const Text('퇴사자 관리'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      content: SizedBox(
        width: dialogWidth,
        child: FutureBuilder<List<User>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 96,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '퇴사자 목록을 불러오지 못했습니다.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              );
            }
            final rows = snapshot.data ?? const [];
            if (rows.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('퇴사 처리된 사원이 없습니다.'),
              );
            }
            return _ResignedUsersBody(rows: rows, screenHeight: screen.height);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _ResignedUsersBody extends StatelessWidget {
  const _ResignedUsersBody({required this.rows, required this.screenHeight});

  final List<User> rows;
  final double screenHeight;

  static const _rowHeight = 36.0;
  static const _headerHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    const columnWidths = {
      0: FixedColumnWidth(88),
      1: FixedColumnWidth(120),
      2: FixedColumnWidth(72),
      3: FixedColumnWidth(150),
      4: FixedColumnWidth(100),
      5: FixedColumnWidth(190),
      6: FixedColumnWidth(120),
    };

    final contentHeight = _headerHeight + rows.length * _rowHeight;
    final maxHeight = (screenHeight * 0.45).clamp(180.0, 360.0);
    final tableHeight = contentHeight > maxHeight ? maxHeight : contentHeight;

    final table = Table(
      columnWidths: columnWidths,
      border: const TableBorder(
        verticalInside: BorderSide(color: AppTheme.tableRowBorder, width: 1),
        bottom: BorderSide(color: AppTheme.tableRowBorder, width: 1),
      ),
      children: [
        const TableRow(
          decoration: kErpTableHeaderRowDecoration,
          children: [
            ErpTableHeaderCell('이름'),
            ErpTableHeaderCell('부서'),
            ErpTableHeaderCell('직급'),
            ErpTableHeaderCell('휴대전화'),
            ErpTableHeaderCell('로그인ID'),
            ErpTableHeaderCell('이메일 주소'),
            ErpTableHeaderCell('퇴사일자'),
          ],
        ),
        for (var i = 0; i < rows.length; i++) _dataRow(rows[i], i),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '총 ${rows.length}명',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppTheme.hairline),
                right: BorderSide(color: AppTheme.hairline),
                bottom: BorderSide(color: AppTheme.hairline),
              ),
            ),
            child: SizedBox(
              height: tableHeight,
              child: Scrollbar(
                thumbVisibility: contentHeight > maxHeight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    thumbVisibility: true,
                    notificationPredicate: (n) => n.depth == 1,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: table,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _dataRow(User user, int index) {
    return TableRow(
      decoration: BoxDecoration(
        color: index.isEven ? AppTheme.tableRowOdd : AppTheme.tableRowEven,
      ),
      children: [
        ErpTableBodyCell(user.name, center: true),
        ErpTableBodyCell(
          user.department.isEmpty ? '-' : user.department,
          center: true,
        ),
        ErpTableBodyCell(
          user.positionNm.isEmpty ? '-' : user.positionNm,
          center: true,
        ),
        ErpTableBodyCell(
          formatKoreanPhoneDisplay(user.mobilePhone),
          center: true,
        ),
        ErpTableBodyCell(user.userId.isEmpty ? '-' : user.userId, center: true),
        ErpTableBodyCell(user.email.isEmpty ? '-' : user.email, center: true),
        ErpTableBodyCell(
          user.leaveDt.isEmpty ? '-' : user.leaveDt,
          center: true,
        ),
      ],
    );
  }
}
