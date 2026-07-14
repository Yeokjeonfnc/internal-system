import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/format/korean_phone_display.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/master/mst006/mst006_controller.dart';
import 'package:app_flutter/pages/master/mst006/mst006_filter.dart';
import 'package:app_flutter/pages/master/mst006/mst006_model.dart';

/// 가맹주관리 목록.
class OwnerUserListView extends ConsumerStatefulWidget {
  const OwnerUserListView({super.key});

  @override
  ConsumerState<OwnerUserListView> createState() => _OwnerUserListViewState();
}

class _OwnerUserListViewState extends ConsumerState<OwnerUserListView> {
  late final TextEditingController _keywordCtrl;

  @override
  void initState() {
    super.initState();
    _keywordCtrl = TextEditingController(text: ref.read(ownerUserProvider).keyword);
    Future.microtask(() => ref.read(ownerUserProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ownerUserProvider);
    final listAsync = ref.watch(ownerUserDataProvider);
    return listAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.read(ownerUserProvider.notifier).refresh(),
            child: const Text('목록을 불러오지 못했습니다. 다시 시도'),
          ),
        ),
      ),
      data: (_) {
        final filter = ref.watch(ownerUserProvider);
        final n = ref.read(ownerUserProvider.notifier);
        final rows = n.getFilteredList();

        return ListPageTemplate(
          activeFilters: _chips(filter, n),
          mainSearchFields: SearchFilterTextField(
            controller: _keywordCtrl,
            hint: '점주명·가맹점명·아이디·이메일·전화번호 검색',
            borderRadius: 8,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey.shade500,
              size: 22,
            ),
            onChanged: n.setKeyword,
          ),
          countText: '총 ${rows.length}명이 조회되었습니다.',
          onRefresh: () => ref.read(ownerUserProvider.notifier).refresh(),
          table: _OwnerUserTable(rows: rows),
          registerMenuCd: kMenuMst006,
          onRegister: () => context.push(AppRoutes.masterOwnerUsersRegister),
        );
      },
    );
  }

  List<ActiveFilterChip> _chips(OwnerUserFilter f, OwnerUserNotifier n) {
    final chips = <ActiveFilterChip>[];
    if (f.keyword.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '검색: ${f.keyword}',
          onClear: () {
            setState(() {
              _keywordCtrl.clear();
              n.setKeyword('');
            });
          },
        ),
      );
    }
    return chips;
  }
}

class _OwnerUserTable extends StatelessWidget {
  const _OwnerUserTable({required this.rows});

  final List<OwnerUser> rows;

  @override
  Widget build(BuildContext context) {
    return ErpVirtualDataTable(
      minWidth: AppDimensions.tableMinWidthStandard,
      columnWidths: const {
        0: FlexColumnWidth(1.0),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.0),
        3: FlexColumnWidth(1.2),
        4: FixedColumnWidth(120),
      },
      headerRow: const TableRow(
        decoration: kErpTableHeaderRowDecoration,
        children: [
          ErpTableHeaderCell('점주명'),
          ErpTableHeaderCell('가맹점명'),
          ErpTableHeaderCell('아이디'),
          ErpTableHeaderCell('이메일 주소'),
          ErpTableHeaderCell('전화번호'),
        ],
      ),
      rowCount: rows.length,
      rowBuilder: (rowContext, index) {
        final user = rows[index];
        void openDetail() => rowContext.goNamed(
          AppRouteNames.masterOwnerUserDetail,
          pathParameters: {'userIdx': '${user.userIdx}'},
        );
        Widget tap(Widget child) =>
            ErpTableDoubleTapCell(onDoubleTap: openDetail, child: child);
        return TableRow(
          decoration: BoxDecoration(
            color: index.isEven ? AppTheme.tableRowOdd : AppTheme.tableRowEven,
          ),
          children: [
            tap(ErpTableBodyCell(user.ownerName, center: true)),
            tap(ErpTableBodyCell(user.storeNm, center: true)),
            tap(ErpTableBodyCell(user.userId, center: true)),
            tap(ErpTableBodyCell(user.email, center: true)),
            tap(
              ErpTableBodyCell(
                formatKoreanPhoneDisplay(user.mobilePhone),
                center: true,
              ),
            ),
          ],
        );
      },
    );
  }
}
