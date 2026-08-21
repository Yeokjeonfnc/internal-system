// 결재정보 표 — 활동등록·전자결재 기안이 같은 위젯을 쓴다.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_approval_line.dart';

enum _ApprovalSealKind { none, filled }

class ApprovalInfoNameRow {
  const ApprovalInfoNameRow({
    required this.label,
    required this.names,
    this.titles = const [],
    this.userIds = const [],
    this.useSeals = false,
    this.onPick,
  });

  final String label;
  final List<String> names;
  final List<String> titles;
  final List<String> userIds;

  /// true면 결재와 같이 완료 시 빨간 원 도장을 그린다.
  final bool useSeals;
  final VoidCallback? onPick;
}

/// 브랜드 레드 라벨 열 + 직급/결재/결재일자 격자. 데스크톱은 가로 550 중앙 정렬.
class ApprovalInfoTable extends StatelessWidget {
  const ApprovalInfoTable({
    super.key,
    required this.approvalStampSlots,
    required this.rankStampSlots,
    required this.approvalUserIds,
    required this.apprAckUserIds,
    required this.apprAckDateByUserId,
    required this.documentWrittenAt,
    required this.writerSealDate,
    required this.loadedApprStatus,
    required this.deptNm,
    required this.drafterNm,
    this.onPickApproval,
    this.extraNameRows = const [],
    this.rankUnderName = false,
    this.approvalSlot0IsDrafter = true,
    this.embedInDocument = false,
  });

  final List<String> approvalStampSlots;
  final List<String> rankStampSlots;
  final List<String> approvalUserIds;
  final Set<String> apprAckUserIds;
  final Map<String, String> apprAckDateByUserId;
  final String documentWrittenAt;
  final String writerSealDate;
  final String? loadedApprStatus;
  final String deptNm;
  final String drafterNm;
  final VoidCallback? onPickApproval;
  final List<ApprovalInfoNameRow> extraNameRows;

  /// true면 직급 행을 빼고, 이름 아래에 `(사원)` 형태로 표시한다.
  final bool rankUnderName;

  /// 활동등록: 결재 0번=기안자. 전자결재: 0번부터 실제 결재자.
  final bool approvalSlot0IsDrafter;

  /// true면 문서 본문 위에 붙여 넣을 때 좌측 여백·별도 카드 정렬을 쓰지 않는다.
  final bool embedInDocument;

  static const double _labelW = 95;
  static const double _slotMinW = 96;
  /// 7칸 결재선 최소 너비(95 + 7×96).
  static double get tableMaxWidth =>
      _labelW + kActivityApprovalLineSlotCount * _slotMinW;
  static const double _rowSingleH = 40;
  static const double _rowDeptH = 30;
  static const double _rowRankGridH = 40;
  static const double _rowSealGridH = 60;
  static const double _compactTableScrollHeightBase =
      _rowSingleH + _rowDeptH + _rowSingleH + _rowRankGridH + _rowSealGridH + 6;
  static int get _slotCount => kActivityApprovalLineSlotCount;
  static const double _textSize = 15.0;
  static const double _sealDiameter = 40;

  List<String> _padList(List<String> src) {
    final a = <String>[];
    for (var i = 0; i < _slotCount; i++) {
      a.add(i < src.length ? src[i] : '');
    }
    return a;
  }

  List<String> get _paddedApprovalNames => _padList(approvalStampSlots);
  List<String> get _paddedRank => _padList(rankStampSlots);
  List<String> get _paddedUserIds => _padList(approvalUserIds);

  String get _normApprStatus => (loadedApprStatus ?? '').trim().toUpperCase();

  bool _peerHasConfirmedApproval(String uidRaw) {
    final u = uidRaw.trim();
    if (u.isEmpty) return false;
    String? ackId;
    for (final id in apprAckUserIds) {
      final t = id.trim();
      if (t.isEmpty) continue;
      if (t == u) {
        ackId = id;
        break;
      }
    }
    if (ackId == null) return false;
    return true;
  }

  bool _slotUsesDrafterSeal(int i) => approvalSlot0IsDrafter && i == 0;

  _ApprovalSealKind _sealKind(int i) {
    final name = _paddedApprovalNames[i].trim();
    if (name.isEmpty) return _ApprovalSealKind.none;
    if (_slotUsesDrafterSeal(i)) {
      final st = _normApprStatus;
      if ((st == 'PENDING' || st == 'APPROVED') &&
          writerSealDate.trim().isNotEmpty) {
        return _ApprovalSealKind.filled;
      }
      return _ApprovalSealKind.none;
    }
    final uid = _paddedUserIds[i].trim();
    return _sealKindForUid(uid);
  }

  _ApprovalSealKind _sealKindForUid(String uidRaw) {
    final uid = uidRaw.trim();
    if (uid.isEmpty) return _ApprovalSealKind.none;
    if (_peerHasConfirmedApproval(uid)) return _ApprovalSealKind.filled;
    return _ApprovalSealKind.none;
  }

  bool _dateCellEmphasis(int i) {
    if (_slotUsesDrafterSeal(i)) {
      return _slotDateLabel(i).trim().isNotEmpty;
    }
    return _sealKind(i) == _ApprovalSealKind.filled;
  }

  String _slotDateLabel(int i) {
    if (_slotUsesDrafterSeal(i)) return writerSealDate;
    return _dateForUid(_paddedUserIds[i]);
  }

  String _dateForUid(String uidRaw) {
    final uid = uidRaw.trim();
    if (uid.isEmpty) return '';
    for (final entry in apprAckDateByUserId.entries) {
      if (entry.key.trim().toLowerCase() == uid.toLowerCase()) {
        return entry.value.trim();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    const edge = FormStylePalette.approvalTableBorder;
    final ranks = _paddedRank;
    final names = _paddedApprovalNames;
    final table = ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: edge, width: 3),
          color: FormStylePalette.approvalTableDataBg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _singleRow('작성일자', documentWrittenAt, showTop: true, edge: edge),
            _singleRow(
              '기안부서',
              deptNm,
              showTop: false,
              edge: edge,
              height: _rowDeptH,
              valueCompact: true,
            ),
            _singleRow('기안자', drafterNm, showTop: false, edge: edge),
            if (!rankUnderName) _rankGridRow(ranks, edge),
            _maybeTappable(_sealGridRow(names, ranks, edge), onPickApproval),
            for (final row in extraNameRows)
              _maybeTappable(
                _nameGridRow(
                  row.label,
                  _padList(row.names),
                  _padList(row.titles),
                  _padList(row.userIds),
                  edge,
                  useSeals: row.useSeals,
                ),
                row.onPick,
              ),
          ],
        ),
      ),
    );

    if (embedInDocument) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: tableMaxWidth),
          child: table,
        ),
      );
    }

    if (!useCompactErpLayout(context)) {
      final scrollH =
          _compactTableScrollHeightBase +
          extraNameRows.length * _rowSealGridH -
          (rankUnderName ? _rowRankGridH : 0);
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : tableMaxWidth;
          final Widget inner;
          if (tableMaxWidth <= maxW) {
            inner = Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: tableMaxWidth, child: table),
            );
          } else {
            inner = SizedBox(
              height: scrollH,
              child: Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: tableMaxWidth, child: table),
                ),
              ),
            );
          }
          return SizedBox(width: maxW, child: inner);
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : tableMaxWidth;
        final scrollH =
            _compactTableScrollHeightBase +
            extraNameRows.length * _rowSealGridH -
            (rankUnderName ? _rowRankGridH : 0);
        return SizedBox(
          width: maxW,
          height: scrollH,
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: tableMaxWidth, child: table),
            ),
          ),
        );
      },
    );
  }

  Widget _maybeTappable(Widget child, VoidCallback? onTap) {
    if (onTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }

  Widget _nameGridRow(
    String label,
    List<String> names,
    List<String> titles,
    List<String> userIds,
    Color edge, {
    required bool useSeals,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: edge, width: 1)),
      ),
      height: _rowSealGridH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labelCol(label),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _slotCount; i++)
                  Expanded(
                    child: useSeals
                        ? _sealCell(
                            i < names.length ? names[i] : '',
                            title: i < titles.length ? titles[i] : '',
                            dateLabel: _dateForUid(
                              i < userIds.length ? userIds[i] : '',
                            ),
                            kind: _sealKindForUid(
                              i < userIds.length ? userIds[i] : '',
                            ),
                            edge: edge,
                            isLast: i == _slotCount - 1,
                          )
                        : _personCell(
                            i < names.length ? names[i] : '',
                            i < titles.length ? titles[i] : '',
                            edge,
                            isLast: i == _slotCount - 1,
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankGridRow(List<String> ranks, Color edge) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: edge, width: 1)),
      ),
      height: _rowRankGridH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labelCol('직급(직책)'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _slotCount; i++)
                  Expanded(
                    child: _textGridCell(
                      i < ranks.length ? ranks[i] : '',
                      edge,
                      isLast: i == _slotCount - 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sealGridRow(List<String> names, List<String> ranks, Color edge) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: edge, width: 1)),
      ),
      height: _rowSealGridH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labelCol('결재'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _slotCount; i++)
                  Expanded(
                    child: _sealCell(
                      i < names.length ? names[i] : '',
                      title: rankUnderName && i < ranks.length ? ranks[i] : '',
                      dateLabel: _dateCellEmphasis(i) ? _slotDateLabel(i) : '',
                      kind: _sealKind(i),
                      edge: edge,
                      isLast: i == _slotCount - 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _singleRow(
    String label,
    String value, {
    required bool showTop,
    required Color edge,
    double? height,
    bool valueCompact = false,
  }) {
    final h = height ?? _rowSingleH;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: showTop ? BorderSide.none : BorderSide(color: edge, width: 1),
        ),
      ),
      height: h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labelCol(label, compact: h < _rowSingleH),
          Expanded(
            child: _valueCol(
              value,
              textHeight: valueCompact ? 1.2 : 2,
              compact: valueCompact,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _labelCol(String t, {bool compact = false}) {
    return SizedBox(
      width: _labelW,
      child: Container(
        decoration: const BoxDecoration(
          color: FormStylePalette.approvalTableLabelColumn,
          border: Border(
            right: BorderSide(
              color: FormStylePalette.approvalTableBorder,
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text(
              t,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: compact ? 1.05 : 1.15,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _valueCol(
    String t, {
    double textHeight = 2,
    bool compact = false,
  }) {
    return ColoredBox(
      color: FormStylePalette.approvalTableDataBg,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: compact ? 0 : 2,
          ),
          child: Text(
            t,
            style: TextStyle(
              color: FormStylePalette.textPrimary,
              fontSize: _textSize,
              fontWeight: FontWeight.w600,
              height: textHeight,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
      ),
    );
  }

  Widget _textGridCell(String t, Color edge, {required bool isLast}) {
    return ColoredBox(
      color: FormStylePalette.approvalTableDataBg,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: isLast ? BorderSide.none : BorderSide(color: edge, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          t.trim(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FormStylePalette.textPrimary,
            fontSize: _textSize,
            fontWeight: FontWeight.w600,
            height: 1.1,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
    );
  }

  Widget _personCell(
    String nameRaw,
    String titleRaw,
    Color edge, {
    required bool isLast,
  }) {
    return ColoredBox(
      color: FormStylePalette.approvalTableDataBg,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: isLast ? BorderSide.none : BorderSide(color: edge, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: _personStack(nameRaw, titleRaw),
      ),
    );
  }

  Widget _personStack(String nameRaw, String titleRaw) {
    final name = nameRaw.trim();
    if (name.isEmpty) return const SizedBox.shrink();
    final title = titleRaw.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FormStylePalette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          if (title.isNotEmpty)
            Text(
              '($title)',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color.fromARGB(255, 106, 106, 116),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.1,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sealCell(
    String nameRaw, {
    String title = '',
    String dateLabel = '',
    required _ApprovalSealKind kind,
    required Color edge,
    required bool isLast,
  }) {
    final name = nameRaw.trim();
    final date = dateLabel.trim();
    const sealRed = Color.fromARGB(255, 238, 92, 92);
    final nameTextStyle = TextStyle(
      color: kind == _ApprovalSealKind.filled
          ? Colors.white
          : FormStylePalette.textPrimary,
      fontSize: kind == _ApprovalSealKind.filled ? 12 : 14,
      fontWeight: FontWeight.w800,
      height: 1.05,
      fontFamilyFallback: AppTheme.koreanFontFallback,
    );
    return ColoredBox(
      color: FormStylePalette.approvalTableDataBg,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: isLast ? BorderSide.none : BorderSide(color: edge, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: name.isEmpty
            ? const SizedBox.shrink()
            : kind == _ApprovalSealKind.none
            ? _personStack(name, title)
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: _sealDiameter,
                      height: _sealDiameter,
                      decoration: const BoxDecoration(
                        color: sealRed,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: nameTextStyle,
                      ),
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        date,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FormStylePalette.textPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
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
