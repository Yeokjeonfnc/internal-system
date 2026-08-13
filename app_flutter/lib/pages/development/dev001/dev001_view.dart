// 예비창업자 목록 화면(필터·테이블).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_status_badge.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/pages/development/dev001/dev001_controller.dart';
import 'package:app_flutter/pages/development/dev001/dev001_filter.dart';
import 'package:app_flutter/pages/development/dev001/dev001_model.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_multi_select.dart';
import 'package:app_flutter/pages/franchise/str001/str001_controller.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/menu/menu_access.dart';

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
          hint: '키워드 검색',
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
      registerMenuCd: kMenuDev001,
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
}

String _evalLabel(EvaluationStatus s) => switch (s) {
  EvaluationStatus.pending => '평가전',
  EvaluationStatus.completed => '평가완료',
};

class _PartnerTable extends ConsumerWidget {
  const _PartnerTable({required this.rows});

  final List<Partner> rows;
  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    Partner partner,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('예비창업자 삭제'),
        content: Text('${partner.partnerNm} 데이터를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await ref
        .read(partnerApiServiceProvider)
        .deletePartner(partner.partnerIdx);
    if (!context.mounted) return;

    if (deleted) {
      await ref.refresh(partnerDataProvider.future).then<void>((_) {});
      if (!context.mounted) return;
      await showAlertDialog(context, '삭제되었습니다.');
    } else {
      await showAlertDialog(context, '삭제에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionOptions =
        ref.watch(partnerCodeOptionsProvider(20)).value ?? const <CodeOption>[];
    final showDelete = context.menuCanDelete(kMenuDev001);
    return ErpVirtualDataTable(
      minWidth: AppDimensions.tableMinWidthStandard,
      columnWidths: <int, TableColumnWidth>{
        0: const FixedColumnWidth(50),
        1: const FixedColumnWidth(100),
        2: const FlexColumnWidth(0.9),
        // '가맹점사업자' StatusBadge 가 100px 에서 overflow 됨
        3: const FixedColumnWidth(130),
        4: const FixedColumnWidth(150),
        5: const FlexColumnWidth(1.2),
        6: const FixedColumnWidth(80),
        7: const FixedColumnWidth(70),
        if (showDelete) 8: const FixedColumnWidth(100),
      },
      headerRow: TableRow(
        decoration: kErpTableHeaderRowDecoration,
        children: [
          const ErpTableHeaderCell('No'),
          const ErpTableHeaderCell('등록일자'),
          const ErpTableHeaderCell('이름'),
          const ErpTableHeaderCell('상태'),
          const ErpTableHeaderCell('휴대전화'),
          const ErpTableHeaderCell('이메일'),
          const ErpTableHeaderCell('지역'),
          const ErpTableHeaderCell('성별'),
          if (showDelete) const ErpTableHeaderCell('삭제'),
        ],
      ),
      rowCount: rows.length,
      rowBuilder: (rowContext, index) {
        final partner = rows[index];
        void openDetail() => rowContext.goNamed(
          AppRouteNames.founderDetail,
          pathParameters: {'partnerIdx': '${partner.partnerIdx}'},
        );
        Widget tap(Widget child) =>
            ErpTableDoubleTapCell(onDoubleTap: openDetail, child: child);
        return TableRow(
          decoration: BoxDecoration(
            color: index.isEven ? AppTheme.tableRowOdd : AppTheme.tableRowEven,
          ),
          children: [
            tap(ErpTableBodyCell('${index + 1}', center: true)),
            tap(ErpTableBodyCell(partner.createDt, center: true)),
            tap(ErpTableBodyCell(partner.partnerNm, center: true)),
            tap(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatusBadge(
                      statusLabelKo(partner.partnerStatus),
                      color: _partnerStatusColor(partner.partnerStatus),
                    ),
                  ),
                ),
              ),
            ),
            tap(ErpTableBodyCell(partner.partnerTel, center: true)),
            tap(ErpTableBodyCell(partner.partnerEmail, center: true)),
            tap(
              ErpTableBodyCell(
                _regionNm(partner.pRegion, regionOptions),
                center: true,
              ),
            ),
            tap(
              ErpTableBodyCell(
                partner.gender == Gender.male ? '남성' : '여성',
                center: true,
              ),
            ),
            if (showDelete)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Center(
                  child: _PartnerDeleteButton(
                    onPressed: () =>
                        _confirmAndDelete(rowContext, ref, partner),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _regionNm(String code, List<CodeOption> options) {
    if (code.isEmpty) return '-';
    for (final option in options) {
      if (option.codeCd == code) return option.codeNm;
    }
    return code;
  }

  /// 구분 배지 색(02_screens.md §7) — 예비창업자=파랑, 가맹점사업자=초록.
  Color _partnerStatusColor(PartnerStatus status) {
    return status == PartnerStatus.prospect
        ? AppTheme.statusRenewal
        : AppTheme.statusNew;
  }
}

class _PartnerDeleteButton extends StatelessWidget {
  const _PartnerDeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text('삭제'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppTheme.accentRed,
        side: const BorderSide(color: AppTheme.accentRed),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
