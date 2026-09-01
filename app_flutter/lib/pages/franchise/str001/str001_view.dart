// 가맹점 목록 화면: 필터·테이블·상세 이동을 담당한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/api/user_page_filter_api_service.dart';
import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
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
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_pager_bar.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_multi_select.dart';
import 'package:app_flutter/pages/franchise/str001/str001_controller.dart';
import 'package:app_flutter/pages/franchise/str001/str001_filter.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';

const Set<CommonSearchFieldId> kStoreListSupportedSearchFields = {
  CommonSearchFieldId.brandCd,
  CommonSearchFieldId.storeStatus,
  CommonSearchFieldId.regionCd,
};

/// 가맹점 목록 본문에 항상 노출하는 필터(브랜드·계약상태·지역). 통합 검색은 상단 필드로 제공.
/// 가맹점 목록.
class StoreListView extends ConsumerStatefulWidget {
  const StoreListView({super.key});

  @override
  ConsumerState<StoreListView> createState() => _StoreListViewState();
}

class _StoreListViewState extends ConsumerState<StoreListView> {
  late final TextEditingController _keywordCtrl;
  final UserPageFilterApiService _savedFilterApi = UserPageFilterApiService();
  bool _isSavingFilter = false;
  String? _loadedFilterUserId;

  @override
  void initState() {
    super.initState();
    _keywordCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = provider.Provider.of<AuthProvider>(context).userId.trim();
    if (userId.isEmpty || _loadedFilterUserId == userId) return;
    _loadedFilterUserId = userId;
    Future.microtask(() => _loadSavedFilter(userId));
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedFilter(String userId) async {
    try {
      final saved = await _savedFilterApi.load(
        userId: userId,
        pageCode: 'STR001',
      );
      if (!mounted || saved == null) return;
      final filter = StoreFilter.fromJson(saved);
      ref.read(storeProvider.notifier).replaceFilter(filter);
    } catch (e, st) {
      debugPrint('STR001 saved filter load failed: $e\n$st');
    }
  }

  Future<void> _saveFilter() async {
    if (_isSavingFilter) return;
    final userId = provider.Provider.of<AuthProvider>(
      context,
      listen: false,
    ).userId.trim();
    if (userId.isEmpty) return;
    setState(() => _isSavingFilter = true);
    try {
      await _savedFilterApi.save(
        userId: userId,
        pageCode: 'STR001',
        filter: ref.read(storeProvider).toJson(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\uAC80\uC0C9 \uC870\uAC74\uC744 \uC800\uC7A5\uD588\uC2B5\uB2C8\uB2E4.',
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('STR001 saved filter save failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 20),
            content: SelectionArea(
              child: Text(
              formatApiUserMessage(
                e,
                fallback: '검색 조건 저장에 실패했습니다.',
              ),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingFilter = false);
    }
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
    items.add(
      SearchFilterItemData(
        label: '\uC0C1\uC138 \uC870\uAC74',
        child: _StoreDetailedConditions(filter: filter, notifier: n),
      ),
    );
    return items;
  }

  // ignore: unused_element
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
    final pageAsync = ref.watch(storeListPageProvider);
    final paging = ref.watch(storeListPagingProvider);

    return ListPageTemplate(
      activeFilters: const <ActiveFilterChip>[],
      countText: pageAsync.when(
        skipLoadingOnReload: true,
        data: (page) => '총 ${page.total}개의 가맹점이 조회되었습니다.',
        loading: () => '조회 중입니다.',
        error: (error, stack) => '조회에 실패했습니다.',
      ),
      registerMenuCd: kMenuStr001,
      onRegister: () => context.goNamed(AppRouteNames.storeRegister),
      onRefresh: () => n.refresh(),
      table: pageAsync.when(
        skipLoadingOnReload: true,
        data: (page) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _StoreTable(rows: page.rows)),
              CommonPagerBar(
                totalCount: page.total,
                page: paging.page,
                pageSize: paging.pageSize,
                onPageChanged: ref.read(storeListPagingProvider.notifier).setPage,
                onPageSizeChanged: ref
                    .read(storeListPagingProvider.notifier)
                    .setPageSize,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                '데이터를 불러오는 중 오류가 발생했습니다.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                formatApiUserMessage(
                  error,
                  fallback: '가맹점 목록을 불러오지 못했습니다.',
                ),
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
      ),
      mainSearchFields: _StoreConditionFilter(
        filter: filter,
        notifier: n,
        onSave: _saveFilter,
        isSaving: _isSavingFilter,
      ),
      filterSheetBuilder: (sheetCtx) => Consumer(
        builder: (_, sheetRef, _) => _StoreConditionFilter(
          filter: sheetRef.watch(storeProvider),
          notifier: sheetRef.read(storeProvider.notifier),
          onSave: _saveFilter,
          isSaving: _isSavingFilter,
        ),
      ),
    );
  }

  // ignore: unused_element
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
    if (f.conditions.isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label:
              '\uC0C1\uC138 \uC870\uAC74: ${f.conditions.where((e) => e.value.trim().isNotEmpty).length}\uAC1C',
          onClear: () => n.replaceFilter(
            f.copy(conditions: const <StoreFilterCondition>[]),
          ),
        ),
      );
    }
    return chips;
  }
}

class _StoreDetailedConditions extends StatelessWidget {
  const _StoreDetailedConditions({
    required this.filter,
    required this.notifier,
  });

  final StoreFilter filter;
  final StoreNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < filter.conditions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<StoreFilterField>(
                    initialValue: filter.conditions[i].field,
                    isExpanded: true,
                    decoration: const InputDecoration(isDense: true),
                    items: StoreFilterField.values
                        .map(
                          (field) => DropdownMenuItem<StoreFilterField>(
                            value: field,
                            child: Text(field.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (field) {
                      if (field == null) return;
                      notifier.updateCondition(
                        i,
                        filter.conditions[i].copyWith(field: field),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    key: ValueKey<String>(
                      'store-filter-$i-${filter.conditions[i].field.name}',
                    ),
                    initialValue: filter.conditions[i].value,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '\uD3EC\uD568 \uAC80\uC0C9',
                    ),
                    onChanged: (value) => notifier.updateCondition(
                      i,
                      filter.conditions[i].copyWith(value: value),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '\uC870\uAC74 \uC0AD\uC81C',
                  onPressed: () => notifier.removeCondition(i),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: notifier.addCondition,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('\uC0C1\uC138 \uC870\uAC74 \uCD94\uAC00'),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '\uC0C1\uC138 \uC870\uAC74\uC740 \uBAA8\uB450 \uB3D9\uC2DC\uC5D0 \uB9CC\uC871\uD574\uC57C \uD569\uB2C8\uB2E4.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _StoreConditionFilter extends StatelessWidget {
  const _StoreConditionFilter({
    required this.filter,
    required this.notifier,
    required this.onSave,
    required this.isSaving,
  });

  final StoreFilter filter;
  final StoreNotifier notifier;
  final Future<void> Function() onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 19,
                  color: AppTheme.accentRed,
                ),
                const SizedBox(width: 7),
                Text(
                  '\uAC80\uC0C9 \uC870\uAC74',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bookmark_outline_rounded, size: 18),
                  label: const Text('\uAC80\uC0C9 \uC870\uAC74 \uC800\uC7A5'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (filter.conditions.isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        notifier.replaceFilter(const StoreFilter()),
                    child: const Text('\uCD08\uAE30\uD654'),
                  ),
              ],
            ),
            if (filter.conditions.isNotEmpty) const SizedBox(height: 12),
            for (var i = 0; i < filter.conditions.length; i++) ...[
              _StoreConditionRow(
                key: ValueKey<String>(
                  'store-condition-$i-${filter.conditions[i].field.name}',
                ),
                condition: filter.conditions[i],
                onChanged: (value) => notifier.updateCondition(i, value),
                onRemove: () => notifier.removeCondition(i),
              ),
              if (i != filter.conditions.length - 1) const SizedBox(height: 8),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: notifier.addCondition,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('\uC870\uAC74 \uCD94\uAC00'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentRed,
                  side: const BorderSide(color: AppTheme.accentRed),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreConditionRow extends StatelessWidget {
  const _StoreConditionRow({
    super.key,
    required this.condition,
    required this.onChanged,
    required this.onRemove,
  });

  final StoreFilterCondition condition;
  final ValueChanged<StoreFilterCondition> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final field = DropdownButtonFormField<StoreFilterField>(
      initialValue: condition.field,
      isExpanded: true,
      decoration: const InputDecoration(isDense: true),
      items: StoreFilterField.values
          .map(
            (value) => DropdownMenuItem<StoreFilterField>(
              value: value,
              child: Text(value.label),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) onChanged(condition.copyWith(field: value));
      },
    );
    final value = _StoreConditionValueField(
      initialValue: condition.value,
      onChanged: (next) => onChanged(condition.copyWith(value: next)),
    );
    final remove = IconButton(
      tooltip: '\uC870\uAC74 \uC0AD\uC81C',
      onPressed: onRemove,
      icon: const Icon(Icons.close_rounded),
      color: AppTheme.textMuted,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              field,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: value),
                  remove,
                ],
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: field),
            const SizedBox(width: 10),
            Expanded(flex: 6, child: value),
            remove,
          ],
        );
      },
    );
  }
}

class _StoreConditionValueField extends StatefulWidget {
  const _StoreConditionValueField({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_StoreConditionValueField> createState() =>
      _StoreConditionValueFieldState();
}

class _StoreConditionValueFieldState extends State<_StoreConditionValueField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void didUpdateWidget(covariant _StoreConditionValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    decoration: const InputDecoration(
      isDense: true,
      hintText: '\uAC80\uC0C9\uD560 \uAC12 \uC785\uB825',
      prefixIcon: Icon(Icons.search_rounded, size: 19),
    ),
    onChanged: widget.onChanged,
  );
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

    // 실패 사유(연결된 점주 계정·NFC 태그 등)는 서버가 message 로 내려준다.
    String? serverMessage;
    final deleted = await ref
        .read(storeApiServiceProvider)
        .deleteStore(
          store.storeIdx,
          onServerMessage: (m) => serverMessage = m,
        );
    if (!context.mounted) return;

    if (deleted) {
      ref.invalidate(storeDataProvider);
      ref.invalidate(storeListPageProvider);
      await showAlertDialog(context, '삭제되었습니다.');
    } else {
      await showAlertDialog(context, serverMessage ?? '삭제에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDelete = context.menuCanDelete(kMenuStr001);
    final compact = useCompactErpLayout(context);

    // 앱(컴팩트): 계약 만료일자·삭제만 빼고 9열·좁은 Fixed 폭 — 가맹점명이 잘리지 않게.
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
              // 헤더와 셀 개수가 어긋나면 ErpVirtualDataTable 은 헤더·본문을 별개
              // Table 로 그려 예외 없이 조용히 한 칸씩 밀린다. 소유자 칸 필수.
              tap(ErpTableBodyCell(row.ownerNm, center: true)),
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
