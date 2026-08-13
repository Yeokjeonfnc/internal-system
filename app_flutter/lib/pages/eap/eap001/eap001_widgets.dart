// 전자결재 화면 공용 위젯 — 좌측 네비·문서 테이블·상태 뱃지.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_api.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';

class EapPageHeader extends StatelessWidget {
  const EapPageHeader({
    super.key,
    required this.title,
    this.showSearch = true,
    this.trailing,
  });

  final String title;
  final bool showSearch;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 18, 14, compact ? 12 : 18, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.chromeBlack,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const Spacer(),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 4),
          ],
          if (showSearch && !compact)
            SizedBox(
              width: 280,
              height: 36,
              child: TextField(
                decoration: InputDecoration(
                  hintText: '전자결재 검색',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPlaceholder,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.inputBorder),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EapEmptyBanner extends StatelessWidget {
  const EapEmptyBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.chipNeutralBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EapSectionTitle extends StatelessWidget {
  const EapSectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.chromeBlack,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EapDocumentTable extends StatelessWidget {
  const EapDocumentTable({
    super.key,
    required this.documents,
    this.showDocNum = false,
    this.onRowTap,
  });

  final List<EapDocument> documents;
  final bool showDocNum;
  final void Function(EapDocument doc)? onRowTap;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Center(
          child: Text(
            '표시할 문서가 없습니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: ErpDataTable(
        minWidth: showDocNum ? 900 : 780,
        tableBuilder: (context, width) {
          final cols = <int, TableColumnWidth>{
            0: const FixedColumnWidth(100),
            1: const FixedColumnWidth(120),
            2: const FixedColumnWidth(48),
            3: FlexColumnWidth(showDocNum ? 2 : 3),
            4: const FixedColumnWidth(52),
            if (showDocNum) 5: const FixedColumnWidth(140),
            if (showDocNum) 6: const FixedColumnWidth(88),
            if (!showDocNum) 5: const FixedColumnWidth(88),
          };

          return Table(
            columnWidths: erpTableColumnWidths(context, cols),
            border: kErpTableInnerGridBorder,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: kErpTableHeaderRowDecoration,
                children: [
                  const ErpTableHeaderCell('기안일'),
                  const ErpTableHeaderCell('결재양식'),
                  const ErpTableHeaderCell('긴급'),
                  const ErpTableHeaderCell('제목'),
                  const ErpTableHeaderCell('첨부'),
                  if (showDocNum) const ErpTableHeaderCell('문서번호'),
                  const ErpTableHeaderCell('결재상태'),
                ],
              ),
              for (var i = 0; i < documents.length; i++)
                _docRow(context, documents[i], i),
            ],
          );
        },
      ),
    );
  }

  TableRow _docRow(BuildContext context, EapDocument doc, int index) {
    final bg = index.isEven ? AppTheme.tableRowEven : AppTheme.tableRowOdd;
    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        ErpTableBodyCell(doc.draftDateLabel, center: true),
        ErpTableBodyCell(doc.formName, center: true),
        ErpTableBodyCell(doc.urgent ? 'Y' : '', center: true),
        _TitleCell(title: doc.title, onTap: () => onRowTap?.call(doc)),
        _AttachmentCell(count: doc.attachmentCount),
        if (showDocNum) ErpTableBodyCell(doc.docNum, center: true),
        EapStatusBadge(status: doc.status),
      ],
    );
  }
}

class _TitleCell extends StatelessWidget {
  const _TitleCell({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 8,
        vertical: compact ? 4 : 6,
      ),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2563C7),
            fontWeight: FontWeight.w500,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _AttachmentCell extends StatelessWidget {
  const _AttachmentCell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const ErpTableBodyCell('', center: true);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.attach_file, size: 14, color: AppTheme.textMuted),
          Text(
            '$count',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class EapStatusBadge extends StatelessWidget {
  const EapStatusBadge({super.key, required this.status});

  final EapDocStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      EapDocStatus.writing => (
          const Color(0xFFFFF7E8),
          const Color(0xFFB45309),
        ),
      EapDocStatus.inProgress => (
          const Color(0xFFE8F5EC),
          const Color(0xFF1E8E4E),
        ),
      EapDocStatus.complete => (
          AppTheme.chipNeutralBackground,
          AppTheme.textSecondary,
        ),
      EapDocStatus.returned => (
          const Color(0xFFFDEEEE),
          AppTheme.accentRed,
        ),
      EapDocStatus.cancelled => (
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280),
        ),
      EapDocStatus.tempSave => (
          const Color(0xFFEFF6FF),
          const Color(0xFF2563C7),
        ),
      _ => (
          AppTheme.chipNeutralBackground,
          AppTheme.textMuted,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
      ),
    );
  }
}

class EapSettingsPanel extends StatefulWidget {
  const EapSettingsPanel({super.key});

  @override
  State<EapSettingsPanel> createState() => _EapSettingsPanelState();
}

class _EapSettingsPanelState extends State<EapSettingsPanel> {
  final _api = EapApiService();
  EapConnectionTestResult? _result;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.connectionTest();
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
        if (result == null) {
          _error = '백엔드 /eap/connection-test 응답을 읽지 못했습니다.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'API 연결 실패: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppTheme.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'API 연동 테스트',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _loading ? null : _runTest,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: Text(_loading ? '테스트 중…' : '다시 테스트'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _statusRow('ERP API', r?.erpApiOk ?? false, r?.erpApiBaseUrl ?? '-'),
              _statusRow(
                '다우 인증키 설정',
                r?.daouConfigured ?? false,
                r?.daouConfigured == true ? '환경변수 등록됨' : '미설정',
              ),
              _statusRow(
                '다우 서버 접속',
                r?.daouReachable ?? false,
                r?.daouApiBaseUrl ?? 'https://api.daouoffice.com',
              ),
              _statusRow(
                '다우 인증/기안',
                r?.daouAuthOk ?? false,
                r?.daouMessage ?? (_error ?? '테스트 대기'),
              ),
              if (r != null) ...[
                const SizedBox(height: 12),
                _settingRow('formCode', r.formCode),
                _settingRow('callbackUrl', r.callbackUrl),
              ],
              const SizedBox(height: 16),
              Text(
                'Client ID·Secret은 백엔드 환경변수 DAOU_CLIENT_ID / DAOU_CLIENT_SECRET 에 설정합니다.\n'
                '설정 후 백엔드를 재시작하고 [다시 테스트]를 누르세요.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.grey.shade600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusRow(String label, bool ok, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: ok ? const Color(0xFF1E8E4E) : AppTheme.accentRed,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          Expanded(
            child: Text(
              detail,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
