// 가맹점 목록 화면: 필터·테이블·상세 이동을 담당한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_multi_select.dart';
import 'package:app_flutter/pages/franchise/str001/str001_controller.dart';
import 'package:app_flutter/pages/franchise/str001/str001_filter.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';

/// 가맹점 목록 본문에 항상 노출하는 필터(브랜드·계약상태·지역). 통합 검색은 상단 필드로 제공.
const Set<CommonSearchFieldId> kStoreListSupportedSearchFields = {
  CommonSearchFieldId.brandCd,
  CommonSearchFieldId.storeStatus,
  CommonSearchFieldId.regionCd,
};

/// 가맹점 목록.
class StoreListView extends ConsumerStatefulWidget {
  const StoreListView({super.key});

  @override
  ConsumerState<StoreListView> createState() => _StoreListViewState();
}

class _StoreListViewState extends ConsumerState<StoreListView> {
  late final TextEditingController _keywordCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(storeProvider);
    _keywordCtrl = TextEditingController(text: s.storeKeyword);
    // 진입 시에는 목록만 배경 갱신(이전 데이터는 그대로 보이므로 스피너 없음).
    Future.microtask(
      () => ref.read(storeProvider.notifier).refresh(includeCodes: false),
    );
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  List<SearchFilterItemData> _mainFilterItems(
    BuildContext context,
    StoreFilter filter,
    List<String> brands,
    List<String> regions,
    StoreNotifier n,
  ) {
    final items = <SearchFilterItemData>[];
    final regionOpts = regions.where((e) => e != '전체').toList();

    for (final def in commonSearchDefsOrdered(
      kStoreListSupportedSearchFields,
    )) {
      if (def.id == CommonSearchFieldId.brandCd) {
        items.add(
          SearchFilterItemData(
            label: def.label,
            child: Consumer(
              builder: (context, ref, _) {
                final brandFilter = ref.watch(storeProvider);
                return FilterStringOptionsSlot(
                  label: def.label,
                  value: brandFilter.brandCd,
                  options: brands,
                  onSelected: ref.read(storeProvider.notifier).setBrand,
                ).buildField();
              },
            ),
          ),
        );
      } else if (def.id == CommonSearchFieldId.storeStatus) {
        items.add(
          const _StoreContractStatusMultiSlot(
            availableStatuses: ['신규계약', '재계약', '양수도', '폐점'],
          ).toItem(),
        );
      } else if (def.id == CommonSearchFieldId.regionCd) {
        items.add(
          SearchFilterItemData(
            label: def.label,
            child: Consumer(
              builder: (context, ref, _) {
                final regionFilter = ref.watch(storeProvider);
                return SearchFilterMultiSelectField(
                  summaryText: searchFilterMultiSelectSummary(
                    regionFilter.regionNms,
                    formatMultiple: searchFilterMultiSelectSummarySortedPreview,
                  ),
                  onTap: () => showDialogWithRef(
                    context: context,
                    options: regionOpts,
                    bindings: (ref) => SearchFilterMultiPickBindings(
                      selected: ref.watch(storeProvider).regionNms,
                      onToggle: ref.read(storeProvider.notifier).toggleRegion,
                    ),
                    title: '지역 검색',
                    searchHint: '지역명을 검색해주세요',
                    emptyOptionsMessage: '등록된 지역이 없습니다.',
                    emptySearchMessage: '검색 결과가 없습니다.',
                  ),
                );
              },
            ),
          ),
        );
      }
    }
    return items;
  }

  Widget _buildMainSearchColumn(
    BuildContext context,
    WidgetRef watchRef,
    List<String> brands,
    List<String> regions,
  ) {
    final filter = watchRef.watch(storeProvider);
    final n = watchRef.read(storeProvider.notifier);
    return Column(
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
          onChanged: n.setStoreKeyword,
        ),
        const SizedBox(height: 8),
        SearchFilterStackedItems(
          items: _mainFilterItems(context, filter, brands, regions, n),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(storeProvider);
    final n = ref.read(storeProvider.notifier);
    final storesAsync = ref.watch(storeDataProvider);
    final regionsAsync = ref.watch(regionNamesProvider);
    final brandsAsync = ref.watch(brandNamesProvider);

    return storesAsync.when(
      data: (stores) {
        return regionsAsync.when(
          data: (regions) {
            return brandsAsync.when(
              data: (brands) {
                // 로드된 데이터로 필터링
                final rows = n.getFilteredList();

                return ListPageTemplate(
                  activeFilters: _activeFilterChips(filter, n),
                  countText: '총 ${rows.length}개의 가맹점이 조회되었습니다.',
                  registerMenuCd: kMenuStr001,
                  onRegister: () =>
                      context.goNamed(AppRouteNames.storeRegister),
                  onRefresh: () => n.refresh(),
                  table: _StoreTable(rows: rows),
                  mainSearchFields: _buildMainSearchColumn(
                    context,
                    ref,
                    brands,
                    regions,
                  ),
                  filterSheetBuilder: (sheetCtx) => Consumer(
                    builder: (_, sheetRef, _) => _buildMainSearchColumn(
                      sheetCtx,
                      sheetRef,
                      brands,
                      regions,
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('브랜드 데이터를 불러오는 중 오류가 발생했습니다: $error')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  '지역 데이터를 불러오는 중 오류가 발생했습니다.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(regionNamesProvider);
                    n.refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러오는 중 오류가 발생했습니다.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => n.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  List<ActiveFilterChip> _activeFilterChips(StoreFilter f, StoreNotifier n) {
    final chips = <ActiveFilterChip>[];
    if (f.storeKeyword.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '통합 검색: ${f.storeKeyword}',
          onClear: () {
            setState(() {
              _keywordCtrl.clear();
              n.setStoreKeyword('');
            });
          },
        ),
      );
    }
    if (f.brandCd != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '브랜드: ${f.brandCd}',
          onClear: () => n.setBrand('전체'),
        ),
      );
    }
    if (f.regionNms.isNotEmpty) {
      final sorted = f.regionNms.toList()..sort();
      final label = sorted.length <= 3
          ? sorted.join(', ')
          : '${sorted.take(3).join(', ')} 외 ${sorted.length - 3}건';
      chips.add(ActiveFilterChip(label: '지역: $label', onClear: n.clearRegions));
    }
    if (f.storeStatus.isNotEmpty) {
      final joined = f.storeStatus.join(', ');
      chips.add(
        ActiveFilterChip(
          label: '계약상태: $joined',
          onClear: () => n.clearContractStatuses(),
        ),
      );
    }
    return chips;
  }
}

Color _contractStatusChipColor(String label, {required bool selected}) {
  if (!selected) return kSearchFilterTextColor;
  return switch (label) {
    '신규계약' => AppTheme.statusNew,
    '재계약' => AppTheme.statusRenewal,
    '양수도' => AppTheme.statusTransfer,
    '폐점' => AppTheme.statusClosed,
    _ => AppTheme.accentRed,
  };
}

Color _contractStatusChipBorder(String label, bool selected) {
  if (!selected) return const Color(0xFFE5E7EB);
  return _contractStatusChipColor(label, selected: true);
}

Color _contractStatusChipSelectedBg(String label) {
  return switch (label) {
    '신규계약' => const Color(0xFFE8F5E9),
    '재계약' => const Color(0xFFE3F2FD),
    '양수도' => const Color(0xFFF3E8FF),
    '폐점' => const Color(0xFFFFF1F2),
    _ => const Color(0xFFFFF1F2),
  };
}

/// 계약상태: [FilterChip] 으로 중복 선택.
class _StoreContractStatusMultiSlot implements FilterSlotConfig {
  const _StoreContractStatusMultiSlot({required this.availableStatuses});

  final List<String> availableStatuses;

  @override
  SearchFilterItemData toItem() {
    return SearchFilterItemData(
      label: '계약상태',
      child: Consumer(
        builder: (context, ref, _) {
          final filter = ref.watch(storeProvider);
          final notifier = ref.read(storeProvider.notifier);
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                showCheckmark: false,
                label: Text(
                  '전체',
                  style: TextStyle(
                    fontSize: kSearchFilterFontSize,
                    fontWeight: filter.storeStatus.isEmpty
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: filter.storeStatus.isEmpty
                        ? AppTheme.accentRed
                        : kSearchFilterTextColor,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                selected: filter.storeStatus.isEmpty,
                onSelected: (_) => notifier.clearContractStatuses(),
                selectedColor: const Color(0xFFFFF1F2),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: filter.storeStatus.isEmpty
                      ? AppTheme.accentRed
                      : const Color(0xFFE5E7EB),
                  width: filter.storeStatus.isEmpty ? 1.4 : 1,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              ),
              for (final s in availableStatuses)
                FilterChip(
                  showCheckmark: false,
                  label: Text(
                    s,
                    style: TextStyle(
                      fontSize: kSearchFilterFontSize,
                      fontWeight: filter.storeStatus.contains(s)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _contractStatusChipColor(
                        s,
                        selected: filter.storeStatus.contains(s),
                      ),
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  selected: filter.storeStatus.contains(s),
                  onSelected: (_) => notifier.toggleContractStatus(s),
                  selectedColor: _contractStatusChipSelectedBg(s),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: _contractStatusChipBorder(
                      s,
                      filter.storeStatus.contains(s),
                    ),
                    width: filter.storeStatus.contains(s) ? 1.4 : 1,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 0,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StoreTable extends ConsumerWidget {
  const _StoreTable({required this.rows});

  final List<Store> rows;

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    Store store,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('가맹점 삭제'),
        content: Text('${store.storeNm} 데이터를 삭제하시겠습니까?'),
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
        .read(storeApiServiceProvider)
        .deleteStore(store.storeIdx);
    if (!context.mounted) return;

    if (deleted) {
      ref.invalidate(storeDataProvider);
      await showAlertDialog(context, '삭제되었습니다.');
    } else {
      await showAlertDialog(context, '삭제에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDelete = context.menuCanDelete(kMenuStr001);
    final compact = useCompactErpLayout(context);

    // 앱(컴팩트): 영업지역 목록과 동일 8열·좁은 Fixed 폭 — 가맹점명이 잘리지 않게.
    final columnWidths = compact
        ? <int, TableColumnWidth>{
            0: const FixedColumnWidth(40),
            1: const FixedColumnWidth(120),
            2: const FlexColumnWidth(1),
            3: const FixedColumnWidth(120),
            4: const FixedColumnWidth(88),
            5: const FixedColumnWidth(100),
            6: const FixedColumnWidth(150),
            7: const FlexColumnWidth(2),
            8: const FixedColumnWidth(100),
            9: const FixedColumnWidth(100),
          }
        : <int, TableColumnWidth>{
            0: const FixedColumnWidth(40),
            1: const FixedColumnWidth(120),
            2: const FlexColumnWidth(1),
            3: const FixedColumnWidth(120),
            4: const FixedColumnWidth(88),
            5: const FixedColumnWidth(100),
            6: const FixedColumnWidth(150),
            7: const FlexColumnWidth(2),
            8: const FixedColumnWidth(100),
            9: const FixedColumnWidth(100),
            if (showDelete) 10: const FixedColumnWidth(80),
          };

    final headerRow = TableRow(
      decoration: kErpTableHeaderRowDecoration,
      children: compact
          ? const [
              ErpTableHeaderCell('No'),
              ErpTableHeaderCell('브랜드'),
              ErpTableHeaderCell('가맹점명'),
              ErpTableHeaderCell('가맹점코드'),
              ErpTableHeaderCell('계약상태'),
              ErpTableHeaderCell('가맹점 소유자'),
              ErpTableHeaderCell('연락처'),
              ErpTableHeaderCell('주소'),
              ErpTableHeaderCell('개업일자'),
            ]
          : [
              const ErpTableHeaderCell('No'),
              const ErpTableHeaderCell('브랜드'),
              const ErpTableHeaderCell('가맹점명'),
              const ErpTableHeaderCell('가맹점코드'),
              const ErpTableHeaderCell('계약상태'),
              const ErpTableHeaderCell('가맹점 소유자'),
              const ErpTableHeaderCell('연락처'),
              const ErpTableHeaderCell('주소'),
              const ErpTableHeaderCell('개업일자'),
              const ErpTableHeaderCell('계약 만료일자'),
              if (showDelete) const ErpTableHeaderCell('삭제'),
            ],
    );

    return ErpVirtualDataTable(
      minWidth: AppDimensions.tableMinWidthStandard,
      columnWidths: columnWidths,
      headerRow: headerRow,
      rowCount: rows.length,
      rowBuilder: (rowContext, index) {
        final row = rows[index];
        void openDetail() => context.goNamed(
          AppRouteNames.storeDetail,
          pathParameters: {'storeIdx': '${row.storeIdx}'},
        );
        Widget tap(Widget child) =>
            ErpTableDoubleTapCell(onDoubleTap: openDetail, child: child);
        final statusCell = tap(
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: _StatusChip(
                storeStatus: row.storeStatus,
                storeStatusNm: row.storeStatusNm,
              ),
            ),
          ),
        );

        if (compact) {
          return TableRow(
            decoration: BoxDecoration(
              color: index.isEven
                  ? AppTheme.tableRowOdd
                  : AppTheme.tableRowEven,
            ),
            children: [
              tap(ErpTableBodyCell('${index + 1}', center: true)),
              tap(ErpTableBodyCell(row.brandNm, center: true)),
              tap(ErpTableBodyCell(row.storeNm, center: true)),
              tap(ErpTableBodyCell(row.storeCd, center: true)),
              statusCell,
              tap(ErpTableBodyCell(row.storeTel, center: true)),
              tap(ErpTableBodyCell(row.address)),
              tap(ErpTableBodyCell(row.contStartDt, center: true)),
            ],
          );
        }

        return TableRow(
          decoration: BoxDecoration(
            color: index.isEven ? AppTheme.tableRowOdd : AppTheme.tableRowEven,
          ),
          children: [
            tap(ErpTableBodyCell('${index + 1}', center: true)),
            tap(ErpTableBodyCell(row.brandNm, center: true)),
            tap(ErpTableBodyCell(row.storeNm, center: true)),
            tap(ErpTableBodyCell(row.storeCd, center: true)),
            statusCell,
            tap(ErpTableBodyCell(row.ownerNm, center: true)),
            tap(ErpTableBodyCell(row.storeTel, center: true)),
            tap(ErpTableBodyCell(row.address)),
            tap(ErpTableBodyCell(row.contStartDt, center: true)),
            tap(ErpTableBodyCell(row.contEndDt, center: true)),
            if (showDelete)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: _StoreDeleteButton(
                    onPressed: () => _confirmAndDelete(context, ref, row),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StoreDeleteButton extends StatelessWidget {
  const _StoreDeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text('삭제'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 24),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        foregroundColor: AppTheme.accentRed,
        side: const BorderSide(color: AppTheme.accentRed),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.storeStatus, required this.storeStatusNm});

  final String storeStatus;
  final String storeStatusNm;
  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.textMuted;
    String displayName = storeStatusNm.isNotEmpty ? storeStatusNm : storeStatus;
    // 영어 코드로 색상 결정
    final statusLower = storeStatus.toLowerCase();
    if (statusLower == 'new') {
      color = AppTheme.statusNew;
      displayName = '신규계약';
    } else if (statusLower == 'renewal') {
      color = AppTheme.statusRenewal;
      displayName = '재계약';
    } else if (statusLower == 'transfer') {
      color = AppTheme.statusTransfer;
      displayName = '양수도';
    } else if (statusLower == 'closed') {
      color = AppTheme.statusClosed;
      displayName = '폐점';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ],
      ),
    );
  }
}
