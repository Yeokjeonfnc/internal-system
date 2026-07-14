// 물건 기본정보 — 문서(사진) 첨부·미리보기(특이사항 아래 인라인).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/file/store_document_file_picker.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/form/common_accent_outline_button.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/pages/development/dev002/dev002_controller.dart';
import 'package:app_flutter/pages/development/dev002/dev002_model.dart';
import 'package:app_flutter/pages/franchise/str001/dialogs/str001_dialog_store_document_preview.dart';
import 'package:app_flutter/pages/franchise/str001/store_document_preview_kind.dart';
import 'package:app_flutter/pages/franchise/str001/str001_view_detail_tabs.dart';

int? resolvePropertyDocPropIdx({
  required Property? property,
  required int? createdPropIdx,
}) {
  final fromProperty = property?.propIdx;
  if (fromProperty != null && fromProperty > 0) {
    return fromProperty;
  }
  if (createdPropIdx != null && createdPropIdx > 0) {
    return createdPropIdx;
  }
  return null;
}

class PropertyDocumentsTab extends ConsumerStatefulWidget {
  const PropertyDocumentsTab({
    super.key,
    this.property,
    this.createdPropIdx,
    this.embedded = false,
  });

  final Property? property;

  /// 등록 화면: 저장 직후 [property] 갱신 전 fallback.
  final int? createdPropIdx;

  /// 기본정보 폼 안에 넣을 때 — 부모 [SingleChildScrollView]와 여백 중복 방지.
  final bool embedded;

  @override
  ConsumerState<PropertyDocumentsTab> createState() =>
      _PropertyDocumentsTabState();
}

class _PropertyDocumentsTabState extends ConsumerState<PropertyDocumentsTab> {
  static const int _maxUploadBytes = 52_428_800;

  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = '전체';
  String _committedQuery = '';
  PropertyDocument? _selectedRow;
  bool _uploading = false;

  static const List<String> _typeOptions = ['전체', '이미지', '문서'];

  int? get _propIdx => resolvePropertyDocPropIdx(
        property: widget.property,
        createdPropIdx: widget.createdPropIdx,
      );

  @override
  void initState() {
    super.initState();
    final idx = _propIdx;
    if (idx != null) {
      Future.microtask(() => ref.invalidate(propertyDocumentsProvider(idx)));
    }
  }

  @override
  void didUpdateWidget(covariant PropertyDocumentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idx = _propIdx;
    final oldIdx = resolvePropertyDocPropIdx(
      property: oldWidget.property,
      createdPropIdx: oldWidget.createdPropIdx,
    );
    if (idx != null && idx > 0 && idx != oldIdx) {
      ref.invalidate(propertyDocumentsProvider(idx));
      setState(() => _selectedRow = null);
    }
  }

  String _inferDocType(String fileName) {
    return propertyDocumentIsImage(fileName) ? '이미지' : '문서';
  }

  List<PropertyDocument> _filteredRows(List<PropertyDocument> allRows) {
    final query = _committedQuery.trim().toLowerCase();
    return allRows.where((row) {
      if (_typeFilter != '전체' && _inferDocType(row.fileName) != _typeFilter) {
        return false;
      }
      if (query.isNotEmpty && !row.fileName.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _applyFilter() {
    setState(() => _committedQuery = _searchController.text);
  }

  void _applyTypeFilter(String? value) {
    if (value == null) return;
    setState(() => _typeFilter = value);
  }

  int? _selectedIndexIn(List<PropertyDocument> rows) {
    final selected = _selectedRow;
    if (selected?.propertyDocIdx == null) return null;
    final idx = rows.indexWhere(
      (r) => r.propertyDocIdx == selected!.propertyDocIdx,
    );
    return idx >= 0 ? idx : null;
  }

  void _onRowTap(int i, List<PropertyDocument> rows) {
    setState(() {
      final current = _selectedIndexIn(rows);
      if (current == i) {
        _selectedRow = null;
      } else {
        _selectedRow = rows[i];
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    showAlertDialog(context, message);
  }

  Future<void> _uploadDocument() async {
    final propIdx = _propIdx;
    if (propIdx == null) {
      _snack('기본정보에서 물건을 저장한 뒤 문서를 첨부할 수 있습니다.');
      return;
    }
    if (_uploading) return;

    final userId = context.read<AuthProvider>().userId.trim();
    final picked = await pickStoreDocumentFiles();
    if (!mounted || picked.isEmpty) return;

    setState(() => _uploading = true);
    try {
      var successCount = 0;
      for (final file in picked) {
        if (!mounted) return;
        if (file.bytes.length > _maxUploadBytes) {
          _snack('${file.name}: 파일 크기는 50MB까지 가능합니다.');
          continue;
        }

        final uploaded = await ref
            .read(propertyApiServiceProvider)
            .uploadPropertyDocument(
              propIdx: propIdx,
              fileName: file.name,
              bytes: file.bytes,
              userId: userId,
              onServerMessage: _snack,
            );
        if (uploaded != null) successCount++;
      }
      if (!mounted) return;
      if (successCount > 0) {
        ref.invalidate(propertyDocumentsProvider(propIdx));
        _snack(
          successCount == picked.length
              ? '$successCount개 문서가 업로드되었습니다.'
              : '$successCount/${picked.length}개 문서가 업로드되었습니다.',
        );
      }
    } catch (e, st) {
      debugPrint('property upload document failed: $e\n$st');
      if (mounted) {
        _snack('파일 선택 또는 업로드 중 오류가 발생했습니다.\n$e');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _previewSelected(
    PropertyDocument? selected,
    List<PropertyDocument> rows,
  ) async {
    if (selected == null) {
      _snack('문서를 먼저 선택해주세요.');
      return;
    }
    final propIdx = _propIdx;
    final docIdx = selected.propertyDocIdx;
    if (propIdx == null || docIdx == null) {
      _snack('미리보기할 문서 정보가 없습니다.');
      return;
    }
    if (storeDocumentPreviewKindFor(selected.fileName) ==
        StoreDocumentPreviewKind.unsupported) {
      _snack('이 파일 형식은 미리보기를 지원하지 않습니다.\n(이미지·PDF만 가능)');
      return;
    }
    // 미리보기 가능한 문서만 모아 좌우로 넘겨볼 수 있게 한다(선택 문서에서 시작).
    final api = ref.read(propertyApiServiceProvider);
    final previewable = rows
        .where(
          (r) =>
              r.propertyDocIdx != null &&
              storeDocumentPreviewKindFor(r.fileName) !=
                  StoreDocumentPreviewKind.unsupported,
        )
        .toList(growable: false);
    final initialIndex = previewable.indexWhere(
      (r) => r.propertyDocIdx == docIdx,
    );
    if (!mounted) return;
    await showStoreDocumentGalleryPreviewDialog(
      context: context,
      items: previewable
          .map(
            (r) => StoreDocumentPreviewItem(
              fileName: r.fileName,
              loadBytes: () =>
                  api.downloadPropertyDocumentBytes(propIdx, r.propertyDocIdx!),
            ),
          )
          .toList(growable: false),
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
    );
  }

  Future<void> _deleteSelected(PropertyDocument? selected) async {
    if (!context.menuCanDelete(kMenuDev002)) {
      _snack('삭제 권한이 없습니다.');
      return;
    }
    if (selected == null) {
      _snack('문서를 먼저 선택해주세요.');
      return;
    }
    final propIdx = _propIdx;
    final docIdx = selected.propertyDocIdx;
    if (propIdx == null || docIdx == null) {
      _snack('삭제할 문서 정보가 없습니다.');
      return;
    }

    final ok = await ref
        .read(propertyApiServiceProvider)
        .deletePropertyDocument(propIdx, docIdx);
    if (!mounted) return;
    if (!ok) {
      _snack('문서 삭제에 실패했습니다.');
      return;
    }
    ref.invalidate(propertyDocumentsProvider(propIdx));
    setState(() => _selectedRow = null);
    _snack('문서가 삭제되었습니다.');
  }

  Future<void> _downloadSelected(PropertyDocument? selected) async {
    if (selected == null) {
      _snack('문서를 먼저 선택해주세요.');
      return;
    }
    final propIdx = _propIdx;
    final docIdx = selected.propertyDocIdx;
    if (propIdx == null || docIdx == null) {
      _snack('다운로드할 문서 정보가 없습니다.');
      return;
    }

    final href = ref
        .read(propertyApiServiceProvider)
        .propertyDocumentDownloadUrl(propIdx, docIdx);
    final uri = href.startsWith('http')
        ? Uri.parse(href)
        : Uri.parse('${Uri.base.origin}$href');
    if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
      _snack('다운로드를 시작할 수 없습니다.');
    }
  }

  Widget _buildDocumentBody(List<PropertyDocument> allRows) {
    final rows = _filteredRows(allRows);
    final selectedIndex = _selectedIndexIn(rows);
    final selected = selectedIndex == null ? null : rows[selectedIndex];
    final canDelete = context.menuCanDelete(kMenuDev002);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocumentsFilterRow(
          typeValue: _typeFilter,
          typeOptions: _typeOptions,
          onTypeChanged: _applyTypeFilter,
          searchController: _searchController,
          onSearch: _applyFilter,
        ),
        const SizedBox(height: 10),
        _PropertyDocumentsActionBar(
          selectedFileName: selected?.fileName ?? '',
          onPreview: () => _previewSelected(selected, rows),
          onDownload: () => _downloadSelected(selected),
          onDelete: canDelete ? () => _deleteSelected(selected) : null,
        ),
        const SizedBox(height: 12),
        _PropertyDocumentsTable(
          rows: rows,
          selectedIndex: selectedIndex,
          onRowTap: (i) => _onRowTap(i, rows),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _emptyPropIdxMessage() {
    return const Text(
      '기본정보에서 물건을 저장한 뒤 문서를 첨부할 수 있습니다.',
      style: TextStyle(
        color: FormStylePalette.textMuted,
        fontSize: 14,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propIdx = _propIdx;
    if (propIdx == null) {
      return widget.embedded
          ? _emptyPropIdxMessage()
          : Center(child: _emptyPropIdxMessage());
    }

    final docsAsync = ref.watch(propertyDocumentsProvider(propIdx));
    final body = docsAsync.when(
      data: (rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DocumentsTopBar(onUpload: _uploading ? null : _uploadDocument),
          const SizedBox(height: 14),
          _buildDocumentBody(rows),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('문서 목록을 불러오지 못했습니다: $e')),
    );

    if (widget.embedded) {
      return body;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: body,
    );
  }
}

class _PropertyDocumentsTable extends StatelessWidget {
  const _PropertyDocumentsTable({
    required this.rows,
    required this.selectedIndex,
    required this.onRowTap,
  });

  final List<PropertyDocument> rows;
  final int? selectedIndex;
  final ValueChanged<int> onRowTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FormStylePalette.panelBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FormStylePalette.panelBorder),
      ),
      child: Column(
        children: [
          const _PropertyDocumentsTableHeader(),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '표시할 문서가 없습니다.',
                style: TextStyle(
                  color: FormStylePalette.textMuted,
                  fontSize: 13,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            )
          else
            for (var i = 0; i < rows.length; i++)
              _PropertyDocumentsTableRow(
                row: rows[i],
                selected: selectedIndex == i,
                onTap: () => onRowTap(i),
              ),
        ],
      ),
    );
  }
}

class _PropertyDocumentsTableHeader extends StatelessWidget {
  const _PropertyDocumentsTableHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['파일명', '수정일자', '수정자', '문서 첨부', '첨부 기준일', '첨부일'];
    const flexes = [5, 2, 1, 1, 2, 2];
    return Container(
      decoration: const BoxDecoration(
        color: FormStylePalette.tableHeaderBg,
        border: Border(
          bottom: BorderSide(color: FormStylePalette.panelBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFE2E5EB),
              ),
            Expanded(
              flex: flexes[i],
              child: Text(
                labels[i],
                textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                  color: FormStylePalette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PropertyDocumentsTableRow extends StatelessWidget {
  const _PropertyDocumentsTableRow({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  final PropertyDocument row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? FormStylePalette.accent.withValues(alpha: 0.18)
        : Colors.transparent;
    final values = <String>[
      row.fileName,
      row.modifiedAt,
      row.modifiedBy,
      row.attached ? 'O' : 'X',
      row.attachmentBaseDate,
      row.attachedAt,
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: FormStylePalette.accent.withValues(alpha: 0.12),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: const Border(
              bottom: BorderSide(color: FormStylePalette.rowDivider, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              for (var i = 0; i < values.length; i++) ...[
                if (i > 0)
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFFE2E5EB),
                  ),
                Expanded(
                  flex: [5, 2, 1, 1, 2, 2][i],
                  child: Text(
                    values[i],
                    textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i == 3 && !row.attached
                          ? FormStylePalette.danger
                          : FormStylePalette.textPrimary,
                      fontSize: 13,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyDocumentsActionBar extends StatelessWidget {
  const _PropertyDocumentsActionBar({
    required this.selectedFileName,
    required this.onPreview,
    required this.onDownload,
    required this.onDelete,
  });

  final String selectedFileName;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final fileName = ReadonlyInputShell(
      child: Text(
        selectedFileName,
        style: FormStylePalette.valueStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    final actions = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        OutlinedButton(
          onPressed: onPreview,
          style: accentOutlineButtonStyle(iconOnly: false),
          child: const Text(
            '미리보기',
            style: TextStyle(
              color: FormStylePalette.accent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: onDownload,
          style: accentOutlineButtonStyle(iconOnly: false),
          child: const Text(
            '다운로드',
            style: TextStyle(
              color: FormStylePalette.accent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: onDelete,
          style: accentOutlineButtonStyle(iconOnly: false),
          child: const Text(
            '삭제',
            style: TextStyle(
              color: FormStylePalette.accent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
      ],
    );

    return Row(
      children: [
        Expanded(child: fileName),
        const SizedBox(width: 8),
        actions,
      ],
    );
  }
}
