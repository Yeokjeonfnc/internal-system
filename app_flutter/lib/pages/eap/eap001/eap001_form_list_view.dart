// 전자결재 서식 목록.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001FormListView extends ConsumerStatefulWidget {
  const Eap001FormListView({super.key});

  @override
  ConsumerState<Eap001FormListView> createState() => _Eap001FormListViewState();
}

class _Eap001FormListViewState extends ConsumerState<Eap001FormListView> {
  final _nameCtrl = TextEditingController();
  String _category = '전체';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formsAsync = ref.watch(eapFormsProvider);
    final forms = formsAsync.valueOrNull ?? const <EapFormConfig>[];
    final keyword = _nameCtrl.text.trim().toLowerCase();
    final filtered = forms.where((f) {
      if (_category != '전체' && f.category != _category) return false;
      if (keyword.isEmpty) return true;
      return f.formName.toLowerCase().contains(keyword) ||
          f.formCode.toLowerCase().contains(keyword);
    }).toList();

    return ListPageTemplate(
      activeFilters: [
        if (_category != '전체')
          ActiveFilterChip(
            label: '문서분류: $_category',
            onClear: () => setState(() => _category = '전체'),
          ),
        if (keyword.isNotEmpty)
          ActiveFilterChip(
            label: '서식명: ${_nameCtrl.text.trim()}',
            onClear: () => setState(_nameCtrl.clear),
          ),
      ],
      mainSearchFields: SearchFilterStackedItems(
        items: [
          FilterStringOptionsSlot(
            label: '문서분류',
            value: _category,
            options: const ['전체', ...kEapFormCategories],
            onSelected: (v) => setState(() => _category = v),
            forceDropdown: true,
          ).toItem(),
          FilterTextSlot(
            label: '서식명',
            hint: '서식명·문서번호',
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
          ).toItem(),
        ],
      ),
      countText: formsAsync.isLoading
          ? '조회 중입니다.'
          : '총 ${filtered.length}건이 조회되었습니다.',
      registerMenuCd: kMenuMst007,
      onRegister: () => context.go(EapRoutes.formNew),
      onRefresh: () => ref.invalidate(eapFormsProvider),
      table: formsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '서식 목록을 불러오지 못했습니다.\n$e',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        data: (_) => _FormTable(rows: filtered),
      ),
    );
  }
}

class _FormTable extends ConsumerWidget {
  const _FormTable({required this.rows});

  final List<EapFormConfig> rows;

  Future<void> _duplicate(BuildContext context, WidgetRef ref, EapFormConfig form) async {
    final auth = provider.Provider.of<AuthProvider>(context, listen: false);
    try {
      await ref.read(eapApiProvider).createForm(
        form.copyWith(
          formCode: '',
          formName: '${form.formName} (복사)',
          createdBy: auth.userId,
          createdByNm: auth.userName,
        ),
      );
      ref.invalidate(eapFormsProvider);
      ref.invalidate(eapEnabledFormsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서식을 복제했습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('복제에 실패했습니다.\n$e')),
        );
      }
    }
  }

  Future<void> _toggleEnabled(
    BuildContext context,
    WidgetRef ref,
    EapFormConfig form,
  ) async {
    try {
      await ref.read(eapApiProvider).updateForm(form.copyWith(enabled: !form.enabled));
      ref.invalidate(eapFormsProvider);
      ref.invalidate(eapEnabledFormsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(form.enabled ? '서식을 숨겼습니다.' : '서식을 사용으로 변경했습니다.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('변경에 실패했습니다.\n$e')),
        );
      }
    }
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    EapFormConfig form,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('서식 삭제'),
        content: Text('${form.formName} 서식을 삭제하시겠습니까?'),
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

    try {
      await ref.read(eapApiProvider).deleteForm(form.formCode);
      ref.invalidate(eapFormsProvider);
      ref.invalidate(eapEnabledFormsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서식을 삭제했습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제에 실패했습니다.\n$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            '등록된 서식이 없습니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
      );
    }

    final canDelete = provider.Provider.of<AuthProvider>(context).isSuperAdmin;

    return ErpDataTable(
      minWidth: canDelete ? 1140 : 1080,
      tableBuilder: (context, width) {
        return Table(
          columnWidths: erpTableColumnWidths(context, {
            0: const FixedColumnWidth(120),
            1: const FixedColumnWidth(140),
            2: const FlexColumnWidth(),
            3: const FixedColumnWidth(72),
            4: const FixedColumnWidth(100),
            5: const FixedColumnWidth(100),
            6: FixedColumnWidth(canDelete ? 180 : 140),
          }),
          border: kErpTableInnerGridBorder,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow(
              decoration: kErpTableHeaderRowDecoration,
              children: [
                ErpTableHeaderCell('문서분류'),
                ErpTableHeaderCell('문서번호'),
                ErpTableHeaderCell('서식명'),
                ErpTableHeaderCell('상태'),
                ErpTableHeaderCell('등록일자'),
                ErpTableHeaderCell('등록자'),
                ErpTableHeaderCell('관리'),
              ],
            ),
            for (var i = 0; i < rows.length; i++)
              _row(context, ref, rows[i], i),
          ],
        );
      },
    );
  }

  TableRow _row(
    BuildContext context,
    WidgetRef ref,
    EapFormConfig form,
    int index,
  ) {
    final bg = index.isEven ? AppTheme.tableRowEven : AppTheme.tableRowOdd;
    final auth = provider.Provider.of<AuthProvider>(context);
    final canCreate = auth.canCreateMenu(kMenuMst007);
    final canUpdate = auth.canUpdateMenu(kMenuMst007);
    final canDelete = auth.isSuperAdmin;
    void open() => context.go(EapRoutes.formEdit(form.formCode));
    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        ErpTableBodyCell(form.category, center: true),
        ErpTableBodyCell(form.formCode, center: true),
        _NameCell(name: form.formName, onTap: open, dimmed: !form.enabled),
        ErpTableBodyCell(
          form.enabled ? '사용' : '숨김',
          center: true,
        ),
        ErpTableBodyCell(form.createdDateLabel, center: true),
        ErpTableBodyCell(
          form.createdByNm.isEmpty ? form.createdBy : form.createdByNm,
          center: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.tableCellPaddingH,
            vertical: AppDimensions.tableCellPaddingV,
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              if (canCreate)
                TextButton(
                  onPressed: () => _duplicate(context, ref, form),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('복제', style: TextStyle(fontSize: 12)),
                ),
              if (canUpdate)
                TextButton(
                  onPressed: () => _toggleEnabled(context, ref, form),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    form.enabled ? '숨김' : '사용',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (canDelete)
                TextButton(
                  onPressed: () => _confirmAndDelete(context, ref, form),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppTheme.accentRed,
                  ),
                  child: const Text('삭제', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({
    required this.name,
    required this.onTap,
    this.dimmed = false,
  });

  final String name;
  final VoidCallback onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.tableCellPaddingH,
          vertical: AppDimensions.tableCellPaddingV,
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: dimmed ? AppTheme.textMuted : AppTheme.accentRed,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
    );
  }
}
