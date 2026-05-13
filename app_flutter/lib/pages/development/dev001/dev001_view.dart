// 예비창업자 목록 화면(필터·테이블).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/widgets/common/common_detail_button.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/pages/development/dev001/dev001_controller.dart';
import 'package:app_flutter/pages/development/dev001/dev001_filter.dart';
import 'package:app_flutter/pages/development/dev001/dev001_model.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_multi_select.dart';
import 'package:app_flutter/pages/franchise/str001/str001_controller.dart';

const List<String> _partnerStatusOptions = ['전체', '예비창업자', '가맹점사업자'];

/// 예비창업자 목록 본문에 항상 노출하는 검색 항목(통합 텍스트 검색은 상단 필드).
const Set<CommonSearchFieldId> kPartnerListSupportedSearchFields = {
  CommonSearchFieldId.partnerStatus,
  CommonSearchFieldId.regionCd,
};

/// 예비창업자 목록.
class PartnerListView extends ConsumerStatefulWidget {
  const PartnerListView({super.key});

  @override
  ConsumerState<PartnerListView> createState() => _PartnerListViewState();
}

class _PartnerListViewState extends ConsumerState<PartnerListView> {
  late final TextEditingController _keywordCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(partnerProvider);
    _keywordCtrl = TextEditingController(text: s.partnerKeyword);
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  List<SearchFilterItemData> _inlineFilters(
    BuildContext context,
    PartnerFilter filter,
    List<String> regions,
    PartnerNotifier n,
  ) {
    final items = <SearchFilterItemData>[];
    final regionOpts = regions.where((e) => e != '전체').toList();
    for (final def in commonSearchDefsOrdered(
      kPartnerListSupportedSearchFields,
    )) {
      switch (def.id) {
        case CommonSearchFieldId.partnerName:
        case CommonSearchFieldId.mobilePhone:
        case CommonSearchFieldId.founderEvaluation:
          break;
        case CommonSearchFieldId.regionCd:
          items.add(
            SearchFilterItemData(
              label: def.label,
              child: SearchFilterMultiSelectField(
                summaryText: searchFilterMultiSelectSummary(
                  filter.regionNms,
                  formatMultiple: searchFilterMultiSelectSummarySortedPreview,
                ),
                onTap: () => showDialogWithRef(
                  context: context,
                  options: regionOpts,
                  bindings: (ref) => SearchFilterMultiPickBindings(
                    selected: ref.watch(partnerProvider).regionNms,
                    onToggle: ref.read(partnerProvider.notifier).toggleRegion,
                  ),
                  title: '지역 검색',
                  searchHint: '지역명을 검색해주세요',
                  emptyOptionsMessage: '등록된 지역이 없습니다.',
                  emptySearchMessage: '검색 결과가 없습니다.',
                ),
              ),
            ),
          );
          break;
        case CommonSearchFieldId.partnerStatus:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.partnerStatus,
              options: _partnerStatusOptions,
              onSelected: n.setStatus,
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
        case CommonSearchFieldId.registrationDate:
        case CommonSearchFieldId.propertyName:
        case CommonSearchFieldId.propertyOwnership:
        case CommonSearchFieldId.propertyStatus:
        case CommonSearchFieldId.propertyAddress:
        case CommonSearchFieldId.activityConsultMemo:
        case CommonSearchFieldId.activityDateRange:
        case CommonSearchFieldId.salesAreaName:
        case CommonSearchFieldId.salesAreaStrategicOnly:
        case CommonSearchFieldId.salesAreaIncludeNonFranchise:
        case CommonSearchFieldId.salesAreaIncludeUnset:
        case CommonSearchFieldId.salesAreaSettingDateRange:
        case CommonSearchFieldId.userName:
        case CommonSearchFieldId.userDepartment:
        case CommonSearchFieldId.userPosition:
        case CommonSearchFieldId.userEmail:
        case CommonSearchFieldId.userPhone:
          break;
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(partnerDataProvider);
    final filter = ref.watch(partnerProvider);
    final n = ref.read(partnerProvider.notifier);
    final rows = n.getFilteredList();
    final regionOptions = ref.watch(regionNamesProvider);
    final mainFields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchFilterTextField(
          controller: _keywordCtrl,
          hint: '성명, 휴대전화, 이메일 검색',
          borderRadius: 8,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade500,
            size: 22,
          ),
          onChanged: n.setKeyword,
        ),
        const SizedBox(height: 8),
        SearchFilterStackedItems(
          items: _inlineFilters(context, filter, regionOptions.value ?? [], n),
        ),
      ],
    );

    return ListPageTemplate(
      activeFilters: _chips(filter, n),
      mainSearchFields: mainFields,
      countText: partnersAsync.isLoading
          ? '조회 중입니다.'
          : '총 ${rows.length}명이 조회되었습니다.',
      onRegister: () => context.goNamed(AppRouteNames.founderRegister),
      onRefresh: () {
        n.refresh();
        setState(() {});
      },
      table: _PartnerTable(rows: rows),
    );
  }

  List<ActiveFilterChip> _chips(PartnerFilter f, PartnerNotifier n) {
    final chips = <ActiveFilterChip>[];
    if (f.partnerKeyword.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '통합 검색: ${f.partnerKeyword}',
          onClear: () {
            setState(() {
              _keywordCtrl.clear();
              n.setKeyword('');
            });
          },
        ),
      );
    }
    if (f.evaluation != null) {
      chips.add(
        ActiveFilterChip(
          label: '평가상태: ${_evalLabel(f.evaluation!)}',
          onClear: () => n.setEvaluation(null),
        ),
      );
    }
    if (f.regionNms.isNotEmpty) {
      final sorted = f.regionNms.toList()..sort();
      final label = sorted.length <= 3
          ? sorted.join(', ')
          : '${sorted.take(3).join(', ')} 외 ${sorted.length - 3}건';
      chips.add(
        ActiveFilterChip(label: '지역: $label', onClear: () => n.clearRegions()),
      );
    }
    if (f.partnerStatus != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '상태: ${f.partnerStatus}',
          onClear: () => n.setStatus('전체'),
        ),
      );
    }
    return chips;
  }

  // String _regionNm(String code, List<String> options) {
  //   if (code.isEmpty || code == '전체') return '전체';
  //   for (final option in options) {
  //     if (option.codeCd == code) return option.codeNm;
  //   }
  //   return code;
  // }
}

String _evalLabel(EvaluationStatus s) => switch (s) {
  EvaluationStatus.pending => '평가전',
  EvaluationStatus.completed => '평가완료',
};

class _PartnerTable extends ConsumerWidget {
  const _PartnerTable({required this.rows});

  final List<Partner> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionOptions =
        ref.watch(partnerCodeOptionsProvider(20)).value ?? const <CodeOption>[];
    return ErpDataTable(
      minWidth: 1600,
      tableBuilder: (context, _) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: const {
          0: FixedColumnWidth(50),
          1: FixedColumnWidth(140),
          2: FlexColumnWidth(0.2),
          3: FixedColumnWidth(150),
          4: FlexColumnWidth(0.3),
          5: FixedColumnWidth(300),
          6: FlexColumnWidth(0.3),
          7: FixedColumnWidth(130),
          8: FixedColumnWidth(150),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: AppTheme.accentRed),
            children: [
              ErpTableHeaderCell('No'), // 0
              ErpTableHeaderCell('등록일자'), // 1
              ErpTableHeaderCell('이름'), // 2
              ErpTableHeaderCell('상태'), // 3
              ErpTableHeaderCell('휴대전화'), // 4
              ErpTableHeaderCell('이메일'), // 5
              ErpTableHeaderCell('지역'), // 6
              ErpTableHeaderCell('성별'), // 7
              ErpTableHeaderCell('상세보기'), //8
            ],
          ),
          ...rows.asMap().entries.map(
            (entry) => TableRow(
              decoration: BoxDecoration(
                color: entry.key.isEven
                    ? AppTheme.tableRowOdd
                    : AppTheme.tableRowEven,
              ),
              children: [
                ErpTableBodyCell('${entry.value.partnerIdx}', center: true),
                ErpTableBodyCell(entry.value.createDt, center: true),
                ErpTableBodyCell(entry.value.partnerNm, center: true),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Center(
                    child: Text(
                      statusLabelKo(entry.value.partnerStatus),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _partnerStatusColor(entry.value.partnerStatus),
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                ),
                ErpTableBodyCell(entry.value.partnerTel, center: true),
                ErpTableBodyCell(entry.value.partnerEmail, center: true),
                ErpTableBodyCell(
                  _regionNm(entry.value.pRegion, regionOptions),
                  center: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Center(
                    child: Text(
                      entry.value.gender == Gender.male ? '남성' : '여성',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _genderColor(entry.value.gender),
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: DetailButton(
                      onPressed: () => context.goNamed(
                        AppRouteNames.founderDetail,
                        pathParameters: {
                          'partnerIdx': '${entry.value.partnerIdx}',
                        },
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

  String _regionNm(String code, List<CodeOption> options) {
    if (code.isEmpty) return '-';
    for (final option in options) {
      if (option.codeCd == code) return option.codeNm;
    }
    return code;
  }

  Color _genderColor(Gender gender) {
    return gender == Gender.female
        ? const Color(0xFFE91E63)
        : const Color(0xFF1E3A8A);
  }

  Color _partnerStatusColor(PartnerStatus status) {
    return status == PartnerStatus.prospect
        ? const Color(0xFFC2185B)
        : const Color(0xFF7B1FA2);
  }
}
