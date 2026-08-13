// 전자결재 양식 코드(formCode) 관리 패널.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';

class EapFormConfigPanel extends ConsumerWidget {
  const EapFormConfigPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formsAsync = ref.watch(eapFormsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppTheme.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '양식 코드 관리',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(eapFormsProvider),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('새로고침'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _showFormDialog(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('양식 등록'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '다우오피스 관리자에서 시스템 연동(v4)으로 발급한 코드를 등록합니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(height: 16),
              formsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => Text(
                  '양식 목록을 불러오지 못했습니다.\nDB 마이그레이션(20260715_eap_daou_schema.sql) 적용 여부를 확인하세요.\n$e',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.accentRed,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                data: (forms) {
                  if (forms.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        '등록된 양식 코드가 없습니다. [양식 등록]으로 추가하세요.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    );
                  }
                  return ErpDataTable(
                    minWidth: 900,
                    tableBuilder: (context, width) {
                      const cols = <int, TableColumnWidth>{
                        0: FlexColumnWidth(1.4),
                        1: FlexColumnWidth(1.4),
                        2: FixedColumnWidth(72),
                        3: FixedColumnWidth(100),
                        4: FixedColumnWidth(56),
                        5: FixedColumnWidth(140),
                      };
                      return Table(
                        columnWidths: erpTableColumnWidths(context, cols),
                        border: kErpTableInnerGridBorder,
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          const TableRow(
                            decoration: kErpTableHeaderRowDecoration,
                            children: [
                              ErpTableHeaderCell('코드'),
                              ErpTableHeaderCell('표시명'),
                              ErpTableHeaderCell('연동'),
                              ErpTableHeaderCell('ERP 메뉴'),
                              ErpTableHeaderCell('사용'),
                              ErpTableHeaderCell('작업'),
                            ],
                          ),
                          for (var i = 0; i < forms.length; i++)
                            TableRow(
                              decoration: BoxDecoration(
                                color: i.isEven
                                    ? AppTheme.tableRowEven
                                    : AppTheme.tableRowOdd,
                              ),
                              children: [
                                ErpTableBodyCell(forms[i].formCode),
                                ErpTableBodyCell(forms[i].formName),
                                ErpTableBodyCell(forms[i].integrationType,
                                    center: true),
                                ErpTableBodyCell(
                                  forms[i].erpSourceMenu.isEmpty
                                      ? '-'
                                      : forms[i].erpSourceMenu,
                                  center: true,
                                ),
                                ErpTableBodyCell(
                                  forms[i].enabled ? 'Y' : 'N',
                                  center: true,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                        onPressed: () => _showFormDialog(
                                          context,
                                          ref,
                                          existing: forms[i],
                                        ),
                                        child: const Text('수정'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _confirmDelete(context, ref, forms[i]),
                                        child: const Text(
                                          '삭제',
                                          style: TextStyle(
                                            color: AppTheme.accentRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EapFormConfig form,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('양식 삭제'),
        content: Text('양식 코드 "${form.formCode}"를 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final api = ref.read(eapApiProvider);
    final deleted = await api.deleteForm(form.formCode);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(deleted ? '삭제되었습니다.' : '삭제에 실패했습니다.')),
    );
    if (deleted) {
      ref.invalidate(eapFormsProvider);
      ref.invalidate(eapEnabledFormsProvider);
    }
  }

  Future<void> _showFormDialog(
    BuildContext context,
    WidgetRef ref, {
    EapFormConfig? existing,
  }) async {
    final result = await showDialog<EapFormConfig>(
      context: context,
      builder: (ctx) => _EapFormEditDialog(existing: existing),
    );
    if (result == null || !context.mounted) return;

    final api = ref.read(eapApiProvider);
    try {
      if (existing == null) {
        await api.createForm(result);
      } else {
        await api.updateForm(result);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing == null ? '등록되었습니다.' : '수정되었습니다.')),
      );
      ref.invalidate(eapFormsProvider);
      ref.invalidate(eapEnabledFormsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiUserMessage(e, fallback: '저장에 실패했습니다.'))),
      );
    }
  }
}

class _EapFormEditDialog extends StatefulWidget {
  const _EapFormEditDialog({this.existing});

  final EapFormConfig? existing;

  @override
  State<_EapFormEditDialog> createState() => _EapFormEditDialogState();
}

class _EapFormEditDialogState extends State<_EapFormEditDialog> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _menuCtrl;
  late final TextEditingController _templateCtrl;
  late final TextEditingController _sortCtrl;
  late bool _enabled;
  late bool _useEmail;
  late bool _useBoard;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.formCode ?? '');
    _nameCtrl = TextEditingController(text: e?.formName ?? '');
    _menuCtrl = TextEditingController(text: e?.erpSourceMenu ?? 'eap001');
    _templateCtrl = TextEditingController(text: e?.htmlTemplateKey ?? '');
    _sortCtrl = TextEditingController(text: '${e?.sortOrder ?? 0}');
    _enabled = e?.enabled ?? true;
    _useEmail = e?.useEmail ?? false;
    _useBoard = e?.useBoard ?? false;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _menuCtrl.dispose();
    _templateCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing ? '양식 수정' : '양식 등록'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _codeCtrl,
                enabled: !editing,
                decoration: const InputDecoration(
                  labelText: '양식 코드 (다우 formCode)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '표시명',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _menuCtrl,
                decoration: const InputDecoration(
                  labelText: 'ERP 메뉴 코드',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _templateCtrl,
                decoration: const InputDecoration(
                  labelText: 'HTML 템플릿 키',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sortCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '정렬 순서',
                  border: OutlineInputBorder(),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('사용'),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v ?? true),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('메일 발송(참고)'),
                value: _useEmail,
                onChanged: (v) => setState(() => _useEmail = v ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('게시판 등록(참고)'),
                value: _useBoard,
                onChanged: (v) => setState(() => _useBoard = v ?? false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: () {
            final code = _codeCtrl.text.trim();
            final name = _nameCtrl.text.trim();
            if (code.isEmpty || name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('코드와 표시명은 필수입니다.')),
              );
              return;
            }
            Navigator.pop(
              context,
              EapFormConfig(
                formCode: code,
                formName: name,
                erpSourceMenu: _menuCtrl.text.trim(),
                htmlTemplateKey: _templateCtrl.text.trim(),
                sortOrder: int.tryParse(_sortCtrl.text.trim()) ?? 0,
                enabled: _enabled,
                useEmail: _useEmail,
                useBoard: _useBoard,
              ),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
          child: Text(editing ? '저장' : '등록'),
        ),
      ],
    );
  }
}
