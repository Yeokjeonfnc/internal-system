// 마스터 — 사원관리 목록(필터·테이블).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/format/korean_phone_display.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/common_status_badge.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/master/mst001/mst001_controller.dart';
import 'package:app_flutter/pages/master/mst001/mst001_filter.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/core/router/app_router.dart';

/// 사원관리 목록.
class UserListView extends ConsumerStatefulWidget {
  const UserListView({super.key});

  @override
  ConsumerState<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends ConsumerState<UserListView> {
  late final TextEditingController _keywordCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(userProvider);
    _keywordCtrl = TextEditingController(text: s.userKeyword);
    Future.microtask(() => ref.read(userProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  /// 목록에 실제로 나타난 부서명·직급명(필터 규칙과 동일하게 문자열 비교).
  List<String> _distinctSorted(Iterable<String> raw) {
    final out = raw
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    out.sort();
    return out;
  }

  SearchFilterItemData _departmentFilterItem(
    UserFilter filter,
    List<String> departmentNames,
    UserNotifier n,
  ) {
    return FilterDropdownSlot<String>(
      label: '부서',
      value: filter.department,
      items: [
        const DropdownMenuItem<String?>(value: '전체', child: Text('전체')),
        for (final name in departmentNames)
          DropdownMenuItem<String?>(value: name, child: Text(name)),
      ],
      onChanged: (v) => n.setDepartment(v ?? '전체'),
    ).toItem();
  }

  SearchFilterItemData _positionFilterItem(
    UserFilter filter,
    List<String> positionNames,
    UserNotifier n,
  ) {
    return FilterStringOptionsSlot(
      label: '직급',
      value: filter.position,
      options: ['전체', ...positionNames],
      onSelected: n.setPosition,
      forceDropdown: true,
    ).toItem();
  }

  Widget _buildFilterRow(
    UserFilter filter,
    List<String> departmentNames,
    List<String> positionNames,
    UserNotifier n,
  ) {
    return SearchFilterStackedItems(
      items: [
        _departmentFilterItem(filter, departmentNames, n),
        _positionFilterItem(filter, positionNames, n),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userProvider);
    final listAsync = ref.watch(userDataProvider);
    return listAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.read(userProvider.notifier).refresh(),
            child: const Text('목록을 불러오지 못했습니다. 다시 시도'),
          ),
        ),
      ),
      data: (users) {
        final filter = ref.watch(userProvider);
        final n = ref.read(userProvider.notifier);
        final rows = n.getFilteredList();
        final departmentNames = _distinctSorted(users.map((u) => u.department));
        final positionNames = _distinctSorted(users.map((u) => u.positionNm));

        final mainBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchFilterTextField(
              controller: _keywordCtrl,
              hint: '키워드 검색',
              borderRadius: 8,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey.shade500,
                size: 22,
              ),
              onChanged: n.setUserKeyword,
            ),
            const SizedBox(height: 8),
            _buildFilterRow(
              filter,
              departmentNames,
              positionNames,
              n,
            ),
          ],
        );

        return ListPageTemplate(
          activeFilters: _chips(filter, n),
          mainSearchFields: mainBlock,
          countText: '총 ${rows.length}명이 조회되었습니다.',
          onRefresh: () => ref.read(userProvider.notifier).refresh(),
          table: _UserTable(rows: rows),
          registerMenuCd: kMenuMst001,
          onRegister: () => context.push(AppRoutes.masterUsersRegister),
        );
      },
    );
  }

  List<ActiveFilterChip> _chips(UserFilter f, UserNotifier n) {
    final chips = <ActiveFilterChip>[];
    if (f.userKeyword.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '통합 검색: ${f.userKeyword}',
          onClear: () {
            setState(() {
              _keywordCtrl.clear();
              n.setUserKeyword('');
            });
          },
        ),
      );
    }
    if (f.department != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '부서: ${f.department}',
          onClear: () => n.setDepartment('전체'),
        ),
      );
    }
    if (f.position != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '직급: ${f.position}',
          onClear: () => n.setPosition('전체'),
        ),
      );
    }
    return chips;
  }
}

class _UserTable extends StatelessWidget {
  const _UserTable({required this.rows});

  final List<User> rows;

  @override
  Widget build(BuildContext context) {
    return ErpVirtualDataTable(
      minWidth: AppDimensions.tableMinWidthStandard,
      columnWidths: const {
        0: FixedColumnWidth(90),
        1: FlexColumnWidth(0.8),
        2: FixedColumnWidth(80),
        3: FixedColumnWidth(140),
        4: FlexColumnWidth(1.0),
        5: FlexColumnWidth(1.2),
        6: FixedColumnWidth(100),
        7: FixedColumnWidth(90),
      },
      headerRow: const TableRow(
        decoration: kErpTableHeaderRowDecoration,
        children: [
          ErpTableHeaderCell('이름'),
          ErpTableHeaderCell('부서'),
          ErpTableHeaderCell('직급'),
          ErpTableHeaderCell('휴대전화'),
          ErpTableHeaderCell('아이디'),
          ErpTableHeaderCell('이메일 주소'),
          ErpTableHeaderCell('입사년월일'),
          ErpTableHeaderCell('태그사용여부 '),
        ],
      ),
      rowCount: rows.length,
      rowBuilder: (rowContext, index) {
        final user = rows[index];
        void openDetail() => rowContext.goNamed(
          AppRouteNames.masterUserDetail,
          pathParameters: {'userIdx': '${user.userIdx}'},
        );
        Widget tap(Widget child) =>
            ErpTableDoubleTapCell(onDoubleTap: openDetail, child: child);
        return TableRow(
          decoration: BoxDecoration(
            color: index.isEven ? AppTheme.tableRowOdd : AppTheme.tableRowEven,
          ),
          children: [
            tap(ErpTableBodyCell(user.name, center: true)),
            tap(
              ErpTableBodyCell(
                user.department.isEmpty ? '-' : user.department,
                center: true,
              ),
            ),
            tap(
              ErpTableBodyCell(
                user.positionNm.isEmpty ? '-' : user.positionNm,
                center: true,
              ),
            ),
            tap(
              ErpTableBodyCell(
                formatKoreanPhoneDisplay(user.mobilePhone),
                center: true,
              ),
            ),
            tap(ErpTableBodyCell(user.userId, center: true)),
            tap(ErpTableBodyCell(user.email, center: true)),
            tap(ErpTableBodyCell(user.joinDt, center: true)),
            tap(_YnFieldChip(active: user.svYn == SvYn.yes)),
          ],
        );
      },
    );
  }
}

/// 읽기 전용 — Y/N 여부를 칩 형태로 표시한다.
class _YnFieldChip extends StatelessWidget {
  const _YnFieldChip({required this.active});

  final bool active;

  static const String activeLabel = '사  용';
  static const String inactiveLabel = '미사용';

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.statusRenewal : AppTheme.textMuted;
    final label = active ? activeLabel : inactiveLabel;

    return Align(
      alignment: Alignment.center,
      child: StatusBadge(label, color: color, showDot: false),
    );
  }
}
