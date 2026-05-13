// 마스터 — 사원관리 목록(필터·테이블).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/format/korean_phone_display.dart';
import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/common_detail_button.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/master/mst001/mst001_controller.dart';
import 'package:app_flutter/pages/master/mst001/mst001_filter.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/core/router/app_router.dart';

/// 사원관리 목록 본문에 항상 노출하는 검색 항목(통합 텍스트 검색은 상단 필드).
const Set<CommonSearchFieldId> kUserListSupportedSearchFields = {
  CommonSearchFieldId.userDepartment,
  CommonSearchFieldId.userPosition,
};

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
    final out = raw.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    out.sort();
    return out;
  }

  List<SearchFilterItemData> _mainFilterItems(
    UserFilter filter,
    List<String> departmentNames,
    List<String> positionNames,
    UserNotifier n,
  ) {
    final items = <SearchFilterItemData>[];
    for (final def in commonSearchDefsOrdered(kUserListSupportedSearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.userName:
        case CommonSearchFieldId.userEmail:
        case CommonSearchFieldId.userPhone:
          break;
        case CommonSearchFieldId.userDepartment:
          items.add(
            FilterDropdownSlot<String>(
              label: def.label,
              value: filter.department,
              items: [
                const DropdownMenuItem<String?>(value: '전체', child: Text('전체')),
                for (final name in departmentNames)
                  DropdownMenuItem<String?>(
                    value: name,
                    child: Text(name),
                  ),
              ],
              onChanged: (v) => n.setDepartment(v ?? '전체'),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.userPosition:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.position,
              options: ['전체', ...positionNames],
              onSelected: n.setPosition,
              forceDropdown: true,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.storeNm:
        case CommonSearchFieldId.storeCd:
        case CommonSearchFieldId.brandCd:
        case CommonSearchFieldId.storeStatus:
        case CommonSearchFieldId.supervisorCd:
        case CommonSearchFieldId.storeType:
        case CommonSearchFieldId.prospectName:
        case CommonSearchFieldId.entrepreneurStatus:
        case CommonSearchFieldId.regionCd:
        case CommonSearchFieldId.mobilePhone:
        case CommonSearchFieldId.registrationDate:
        case CommonSearchFieldId.propertyName:
        case CommonSearchFieldId.propertyOwnership:
        case CommonSearchFieldId.propertyStatus:
        case CommonSearchFieldId.propertyAddress:
        case CommonSearchFieldId.partnerName:
        case CommonSearchFieldId.founderEvaluation:
        case CommonSearchFieldId.partnerStatus:
        case CommonSearchFieldId.activityConsultMemo:
        case CommonSearchFieldId.activityDateRange:
        case CommonSearchFieldId.salesAreaName:
        case CommonSearchFieldId.salesAreaStrategicOnly:
        case CommonSearchFieldId.salesAreaIncludeNonFranchise:
        case CommonSearchFieldId.salesAreaIncludeUnset:
        case CommonSearchFieldId.salesAreaSettingDateRange:
          break;
      }
    }
    return items;
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
            SearchFilterStackedItems(
              items: _mainFilterItems(filter, departmentNames, positionNames, n),
            ),
          ],
        );

        return ListPageTemplate(
          activeFilters: _chips(filter, n),
          mainSearchFields: mainBlock,
          countText: '총 ${rows.length}명이 조회되었습니다.',
          onRefresh: () => ref.read(userProvider.notifier).refresh(),
          table: _UserTable(rows: rows),
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
    return ErpDataTable(
      minWidth: AppDimensions.tableMinWidthDefault,
      tableBuilder: (context, _) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: const {
          0: FixedColumnWidth(200),
          1: FlexColumnWidth(0.5),
          2: FixedColumnWidth(130),
          3: FixedColumnWidth(180),
          4: FixedColumnWidth(200),
          5: FlexColumnWidth(1.4),
          6: FixedColumnWidth(120),
          7: FixedColumnWidth(100),
          8: FixedColumnWidth(130),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: AppTheme.accentRed),
            children: [
              ErpTableHeaderCell('이름'),
              ErpTableHeaderCell('부서'),
              ErpTableHeaderCell('직급'),
              ErpTableHeaderCell('휴대전화'),
              ErpTableHeaderCell('아이디'),
              ErpTableHeaderCell('이메일 주소'),
              ErpTableHeaderCell('입사년월일'),
              ErpTableHeaderCell('태그사용여부'),
              ErpTableHeaderCell('상세보기'),
            ],
          ),
          ...rows.asMap().entries.map(
            (e) => TableRow(
              decoration: BoxDecoration(
                color: e.key.isEven
                    ? AppTheme.tableRowOdd
                    : AppTheme.tableRowEven,
              ),
              children: [
                ErpTableBodyCell(e.value.name, center: true),
                ErpTableBodyCell(e.value.department, center: true),
                ErpTableBodyCell(e.value.positionNm, center: true),
                ErpTableBodyCell(
                  formatKoreanPhoneDisplay(e.value.mobilePhone),
                  center: true,
                ),
                ErpTableBodyCell(e.value.userId, center: true),
                ErpTableBodyCell(e.value.email, center: true),
                ErpTableBodyCell(e.value.joinDt, center: true),
                _TagYnFieldChip(tagYn: e.value.tagYn),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: DetailButton(
                      onPressed: () => context.goNamed(
                        AppRouteNames.masterUserDetail,
                        pathParameters: {'userIdx': '${e.value.userIdx}'},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 읽기 전용 — 태그 사용 여부를 칩 형태로 표시한다.
class _TagYnFieldChip extends StatelessWidget {
  const _TagYnFieldChip({required this.tagYn});

  final TagYn tagYn;

  @override
  Widget build(BuildContext context) {
    final tagged = tagYn == TagYn.tagged;
    final (Color fg, Color bg, Color border) = tagged
        ? (
            const Color.fromARGB(255, 238, 36, 70),
            const Color.fromARGB(255, 253, 195, 198),
            const Color.fromARGB(255, 237, 233, 254),
          )
        : (
            const Color(0xFF065F46),
            const Color(0xFFD1FAE5),
            const Color(0xFFA7F3D0),
          );
    final label = tagged ? '사용' : '미사용';

    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
    );
  }
}
