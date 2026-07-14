// 활동 관리 등록 — 제공 화면 구조·[FormStylePalette] 톤.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart'
    show CalendarPickButton, showAccentDatePicker;
import 'package:app_flutter/core/active_mst/active_mst_write_request.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/pages/active/act002/act002_api.dart';
import 'package:app_flutter/pages/active/act002/act002_model.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_approval_line.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_instructions.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_tag_history.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_visit_history.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_electronic_signature.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_lookup.dart';
import 'package:app_flutter/pages/active/act002/act002_model_checklist.dart';
import 'package:app_flutter/core/notifications/notification_api_service.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/pages/master/mst001/mst001_api.dart';
import 'package:app_flutter/core/file/store_document_file_picker.dart';
import 'package:app_flutter/core/widgets/common/form/common_accent_outline_button.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/pages/franchise/str001/dialogs/str001_dialog_store_document_preview.dart';
import 'package:app_flutter/pages/franchise/str001/store_document_preview_kind.dart';
import 'package:app_flutter/pages/franchise/str001/str001_api.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';

/// 가맹점 기본정보 읽기 전용 값 칸: 내용에 맞게 줄이되 긴 문구·숫자는 이 폭을 넘지 않게.
const double _kStoreReadonlyMaxWidth = 280;

/// 빈 값(—)·짧은 글자일 때도 칸이 지나치게 좁아지지 않도록.
const double _kStoreReadonlyMinWidth = 112;

/// 2열 행: 긴 한글 라벨이 잘리지 않도록(… 방지).
const double _kStoreLabelWidth = 212;

/// 3열 행(금액·면적): 라벨은 짧은 편이라 값 칸 너비를 확보.
const double _kStoreLabelWidthTight = 108;

/// 검색·입력: 텍스트 / 드롭다운 / 날짜 / 읽기전용 **동일** 박스·글자(13).
const TextStyle kActivityFormValueStyle = TextStyle(
  fontSize: 14,
  height: 1.3,
  color: FormStylePalette.textPrimary,
  fontFamilyFallback: AppTheme.koreanFontFallback,
);

Widget _fieldShell(Widget child) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: FormStylePalette.inputBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: FormStylePalette.panelBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: child,
    ),
  );
}

/// 가맹점 기본정보: API 연동 전 표시용 읽기 전용 (칸 너비는 내용 + 상한, 한 줄·세로 가운데).
Widget _roVal(String? text, {bool expand = false}) {
  final empty = text == null || text.trim().isEmpty;
  final s = empty
      ? kActivityFormValueStyle.copyWith(
          color: const Color.fromARGB(255, 96, 103, 116),
        )
      : kActivityFormValueStyle;
  final display = empty ? '' : text.trim();
  final valueText = Text(
    display,
    maxLines: expand ? 3 : 1,
    overflow: expand ? TextOverflow.visible : TextOverflow.ellipsis,
    softWrap: expand,
    strutStyle: StrutStyle(
      fontSize: s.fontSize,
      height: s.height,
      fontFamily: s.fontFamily,
      fontFamilyFallback: s.fontFamilyFallback,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    style: s,
  );

  if (expand) {
    return _fieldShell(_StoreFieldLineContent(child: valueText));
  }

  return Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: _kStoreReadonlyMinWidth,
        maxWidth: _kStoreReadonlyMaxWidth,
      ),
      child: IntrinsicWidth(
        child: _fieldShell(_StoreFieldLineContent(child: valueText)),
      ),
    ),
  );
}

/// 값 + 우측 단위(원, m², 평, 층) — [kActivityFormValueStyle] 맞춤.
///
/// [Expanded] / 좁은 [Row] 내부에 둘 때 [IntrinsicWidth]를 쓰지 않아 가로 오버플로를 막는다.
Widget _roUnit(String value, String unit) {
  const uStyle = TextStyle(
    fontSize: 13,
    color: FormStylePalette.textMuted,
    fontFamilyFallback: AppTheme.koreanFontFallback,
  );
  return _fieldShell(
    _StoreFieldLineContent(
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              strutStyle: StrutStyle(
                fontSize: kActivityFormValueStyle.fontSize,
                height: kActivityFormValueStyle.height,
                fontFamily: kActivityFormValueStyle.fontFamily,
                fontFamilyFallback: kActivityFormValueStyle.fontFamilyFallback,
                leadingDistribution: TextLeadingDistribution.even,
              ),
              style: kActivityFormValueStyle,
            ),
          ),
          const SizedBox(width: 6),
          Text(unit, style: uStyle),
        ],
      ),
    ),
  );
}

/// 읽기 전용 셸 안에서 한 줄 텍스트를 **세로 가운데**에 둔다.
class _StoreFieldLineContent extends StatelessWidget {
  const _StoreFieldLineContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }
}

/// [검색·입력] 2열에서 빈 **오른쪽 칸**을 맞출 때 쓰는 placeholder.
class _FormColSpacer extends StatelessWidget {
  const _FormColSpacer();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// 텍스트필드·읽기전용·[_fieldShell] 과 동일한 높이감·달력 피킹.
class _ActivityFormDateField extends StatelessWidget {
  const _ActivityFormDateField({required this.labelText, required this.onPick});

  final String labelText;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final dateField = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(8),
        child: _fieldShell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              labelText,
              style: kActivityFormValueStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );

    if (useCompactErpLayout(context)) {
      return Row(
        children: [
          Expanded(child: dateField),
          const SizedBox(width: 4),
          CalendarPickButton(onPressed: onPick),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: dateField),
        const SizedBox(width: 8),
        CalendarPickButton(onPressed: onPick),
      ],
    );
  }
}

/// 활동을 신규 등록하는 화면(상신·임시보관·결재라인).
///
/// [ActivityManagementView]의 「활동관리 등록」 탭 또는 `/activities/manage/register` 등에 동일 위젯을 쓴다.
class ActivityRegisterView extends StatefulWidget {
  const ActivityRegisterView({super.key, this.actIdx});

  final int? actIdx;

  @override
  State<ActivityRegisterView> createState() => _ActivityRegisterViewState();
}

class _ActivityRegisterViewState extends State<ActivityRegisterView> {
  static const _kinds = <String>['상담', '방문', '점검', '전화'];

  String _activityKind = '방문';
  late DateTime _activityDate;
  Store? _selectedStore;
  bool _saving = false;
  bool _autoSaving = false;
  bool _submitted = false;
  bool _approving = false;
  int? _draftActIdx;
  Timer? _autoSaveTimer;

  /// 상세 로드 후 서버 [apprStatus]. 신규 등록만 열면 null.
  String? _loadedApprStatus;

  String _loadedCreateDtLabel = '';
  String _loadedApprDtLabel = '';
  Set<String> _apprAckUserIds = {};
  Map<String, String> _apprAckDateByUserId = {};

  // 기안 정보
  String _deptNm = ''; // 기안부서
  String _drafterNm = ''; // 기안자

  final _specialNotesController = TextEditingController();
  final _activityNotesController = TextEditingController();
  final _suggestionsController = TextEditingController();
  final _apprNotesController = TextEditingController();
  final _svNotesController = TextEditingController();

  /// 전자서명 PNG — 서버 저장 후 조회 시에도 사용.
  Uint8List? _electronicSignaturePng;

  List<ActAttachment> _attachments = const [];
  bool _uploadingAttachment = false;
  int? _selectedUsageLogIdx;

  // 체크리스트 블록에 접근하기 위한 GlobalKey
  final _checklistKey = GlobalKey<_ChecklistBlockState>();

  /// 결재 절차선 — [결재라인 설정]에서 반영. `결재` 행(칸 수 [kActivityApprovalLineSlotCount]).
  List<String> _approvalLineStampSlots = const ['', '', '', '', '', '', ''];

  /// 결재 슬롯별 `user_mst.user_id` (이름과 동일 인덱스).
  List<String> _approvalLineUserIds = List<String>.filled(
    kActivityApprovalLineSlotCount,
    '',
  );

  /// [직급(직책)]. [_approvalLineStampSlots]과 같은 인덱스.
  List<String> _rankLineStampSlots = const ['', '', '', '', '', '', ''];

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// 결재대기·결재완료 문서 — 임시저장/상신 숨김·결재하기 노출.
  bool get _isApprovalWorkflowView {
    final s = _loadedApprStatus?.trim().toUpperCase();
    return s == 'PENDING' || s == 'APPROVED';
  }

  /// 임시보관·자동 임시저장 건을 상신(PENDING)할 때 — 활동일자를 오늘로 맞춘다.
  bool get _isSubmittingFromDraft {
    if (_loadedApprStatus?.trim().toUpperCase() == 'DRAFT') return true;
    if (_draftActIdx != null) return true;
    // 임시보관 상세 진입 직후(로드 전) 포함
    return widget.actIdx != null && !_isApprovalWorkflowView;
  }

  /// 결재하기 버튼은 결재대기에서만 표시 (완료 후 재클릭 방지).
  /// 기안자(0번 슬롯)는 결재자가 아니므로 버튼을 숨긴다.
  bool get _canSubmitApproval {
    final s = _loadedApprStatus?.trim().toUpperCase();
    if (s != 'PENDING') return false;
    final self = context.read<AuthProvider>().userId.trim();
    if (self.isEmpty) return false;
    final writer = _approvalLineUserIds.isNotEmpty
        ? _approvalLineUserIds[0].trim()
        : '';
    if (writer.isNotEmpty && self == writer) return false;
    return true;
  }

  String _todayYmd() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  String get _docWrittenAtDisplay =>
      _loadedCreateDtLabel.isNotEmpty ? _loadedCreateDtLabel : _todayYmd();

  /// 작성자 슬롯 결재일자 칸 — 결재일시 우선, 없으면 작성일자, 신규는 오늘
  String get _writerSealDateDisplay {
    if (_loadedApprDtLabel.isNotEmpty) return _loadedApprDtLabel;
    if (_loadedCreateDtLabel.isNotEmpty) return _loadedCreateDtLabel;
    return _todayYmd();
  }

  @override
  void initState() {
    super.initState();
    _activityDate = _today;
    _draftActIdx = widget.actIdx;
    // 신규 등록: 로그인 사용자를 기안·0번 슬롯에 둔다.
    // 상세(actIdx 있음): API 전까지 잘못된 이름이 잠깐 보이는 깜빡임 방지 — 빈 상태로 두고 _loadAct 가 채운다.
    if (widget.actIdx == null) {
      _initApprovalLine();
    } else {
      _deptNm = '';
      _drafterNm = '';
      _approvalLineStampSlots = List<String>.filled(
        kActivityApprovalLineSlotCount,
        '',
      );
      _rankLineStampSlots = List<String>.filled(
        kActivityApprovalLineSlotCount,
        '',
      );
      _approvalLineUserIds = List<String>.filled(
        kActivityApprovalLineSlotCount,
        '',
      );
    }
    if (widget.actIdx != null) {
      _loadAct(widget.actIdx!);
    }
    // 자동 저장: 5분마다 DRAFT로 서버 반영(가맹점 선택·일반 등록/임시보관 흐름에서만).
    // 결재대기·결재완료 상세 모드, 저장/상신 처리 중, 가맹점 미선택 시에는 실행하지 않는다.
    _autoSaveTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _autosaveDraft(),
    );
  }

  void _initApprovalLine() {
    final authProvider = context.read<AuthProvider>();
    final p = authProvider.profile;

    if (p != null) {
      final userName = p.userNm;
      final positionNm = p.positionNm;
      final deptNm = p.deptNm;

      setState(() {
        _deptNm = deptNm; // 기안부서 설정
        _drafterNm = userName; // 기안자 설정
        _approvalLineStampSlots = [userName, '', '', '', '', '', ''];
        _rankLineStampSlots = [positionNm, '', '', '', '', '', ''];
        _approvalLineUserIds = List<String>.filled(
          kActivityApprovalLineSlotCount,
          '',
        );
        final uid = authProvider.userId.trim();
        if (uid.isNotEmpty) {
          _approvalLineUserIds[0] = uid;
        }
      });
    }
  }

  Future<void> _loadAct(int actIdx) async {
    final detail = await Act002Api().fetchOne(actIdx);
    if (!mounted || detail == null) return;

    Store? store;
    if (detail.storeIdx != null) {
      store = await StoreApiService().getStoreByIndex(detail.storeIdx!);
    }
    if (!mounted) return;

    setState(() {
      _selectedStore = store;
      final actType = detail.actType;
      _activityKind = actType.isNotEmpty ? actType : _activityKind;
      _activityDate = _parseDate(detail.actDt) ?? _activityDate;
      _specialNotesController.text = detail.memoTxt;
      _activityNotesController.text = detail.actNotes;
      _suggestionsController.text = detail.suggestions;
      _svNotesController.text = detail.svNotes;
      _apprNotesController.text = detail.apprNotes;
      final appr = detail.apprStatus.trim();
      _loadedApprStatus = appr.isEmpty ? null : appr;
      _loadedCreateDtLabel = ActivityDetail.toYmd(detail.createDtIso);
      _loadedApprDtLabel = ActivityDetail.toYmd(detail.apprDtIso);
      _apprAckUserIds = detail.apprAckUserIds;
      _apprAckDateByUserId = detail.apprAckDateByUserId;
      // 기안부서·기안자: active_mst.sv_id 기준 user_mst·dept_mst (API svNm / svDeptNm)
      if (detail.svId.isNotEmpty) {
        _deptNm = detail.svDeptNm;
        _drafterNm = detail.svNm;
      } else {
        // 구 데이터 등 sv_id 없을 때만 로그인 프로필로 표시(상세 진입 시 김민효→기안자 깜빡임과 구분)
        final authProvider = context.read<AuthProvider>();
        final p = authProvider.profile;
        _deptNm = p?.deptNm ?? '';
        _drafterNm = p?.userNm ?? '';
      }
    });

    await _syncApprovalFromAct(detail);

    if (detail.hasSignature) {
      final sigBytes = await Act002Api().downloadSignatureBytes(actIdx);
      if (mounted && sigBytes != null) {
        setState(() => _electronicSignaturePng = sigBytes);
      }
    } else if (mounted) {
      setState(() => _electronicSignaturePng = null);
    }

    await _reloadAttachments(actIdx);

    // 체크리스트 결과 로드
    _pullChkResults(actIdx);
  }

  Future<void> _reloadAttachments(int actIdx) async {
    final rows = await Act002Api().fetchAttachments(actIdx);
    if (!mounted) return;
    setState(() {
      _attachments = rows.where((e) => e.attached).toList(growable: false);
    });
  }

  Future<int?> _ensureActIdxForFiles() async {
    final existing = _draftActIdx ?? widget.actIdx;
    if (existing != null) return existing;
    if (_selectedStore == null) return null;
    final saved = await _pushAct('DRAFT');
    if (saved?.actIdx != null) {
      _draftActIdx = saved!.actIdx;
      return saved.actIdx;
    }
    return null;
  }

  Future<void> _pullChkResults(int actIdx) async {
    try {
      final results = await Act002Api().chkResults(actIdx);
      if (!mounted) return;

      // 체크리스트 블록이 준비되면 결과 설정
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checklistKey.currentState?.setChecklistResults(results);
      });
    } catch (e) {
      debugPrint('체크리스트 결과 로드 에러: $e');
    }
  }

  DateTime? _parseDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _specialNotesController.dispose();
    _activityNotesController.dispose();
    _suggestionsController.dispose();
    _svNotesController.dispose();
    _apprNotesController.dispose();
    super.dispose();
  }

  Future<void> _syncApprovalFromAct(ActivityDetail detail) async {
    final ids = detail.resolvedApproverIds;

    final svId = detail.svId;
    final authProvider = context.read<AuthProvider>();
    final authId = authProvider.userId.trim();

    try {
      final users = await Mst001ApiService().getUsers();
      final byId = <String, User>{};
      for (final u in users) {
        if (u.userId.isNotEmpty) byId[u.userId] = u;
      }
      if (!mounted) return;
      setState(() {
        _approvalLineUserIds = List<String>.filled(
          kActivityApprovalLineSlotCount,
          '',
        );
        _approvalLineStampSlots = List<String>.filled(
          kActivityApprovalLineSlotCount,
          '',
        );
        _rankLineStampSlots = List<String>.filled(
          kActivityApprovalLineSlotCount,
          '',
        );

        final writerId = svId.isNotEmpty ? svId : authId;
        _approvalLineUserIds[0] = writerId;
        final wEmp = byId[writerId];
        _approvalLineStampSlots[0] = wEmp?.name.isNotEmpty == true
            ? wEmp!.name
            : _drafterNm;
        _rankLineStampSlots[0] = wEmp?.positionNm ?? '';

        var slot = 1;
        for (final uid in ids) {
          if (slot >= kActivityApprovalLineSlotCount) break;
          if (uid == writerId) continue;
          _approvalLineUserIds[slot] = uid;
          final emp = byId[uid];
          _approvalLineStampSlots[slot] = emp?.name.isNotEmpty == true
              ? emp!.name
              : uid;
          _rankLineStampSlots[slot] = emp?.positionNm ?? '';
          slot++;
        }
      });
    } catch (e) {
      debugPrint('결재선 복원 실패: $e');
    }
  }

  List<String> _peerApproverIds() {
    final self = context.read<AuthProvider>().userId.trim();
    final out = <String>[];
    // 0열은 기안(작성자) 표시용 — 상신 시 결재자 CSV에는 1열부터만 포함한다.
    for (var i = 1; i < kActivityApprovalLineSlotCount; i++) {
      final id = _approvalLineUserIds[i].trim();
      final nm = _approvalLineStampSlots[i].trim();
      if (nm.isEmpty || id.isEmpty) continue;
      if (id == self) continue;
      if (!out.contains(id)) out.add(id);
    }
    return out;
  }

  Future<void> _submitApprove() async {
    final actIdx = _draftActIdx ?? widget.actIdx;
    final uid = context.read<AuthProvider>().userId.trim();
    if (actIdx == null || uid.isEmpty) {
      _toast('로그인 정보 또는 활동 번호가 없습니다.');
      return;
    }
    setState(() => _approving = true);
    final result = await NotificationApiService().acknowledgeActivityApproval(
      actIdx: actIdx,
      userId: uid,
      apprNotes: _apprNotesController.text,
    );
    if (!mounted) return;
    setState(() => _approving = false);
    if (result.ok) {
      await _loadAct(actIdx);
    }
    if (!mounted) return;
    await showAlertDialog(
      context,
      result.ok ? '결재 처리되었습니다.' : (result.errorMessage ?? '결재 처리에 실패했습니다.'),
    );
  }

  Future<void> _pickActDate() async {
    final d = await showAccentDatePicker(
      context: context,
      initialDate: _activityDate,
    );
    if (!mounted || d == null) return;
    setState(() => _activityDate = DateTime(d.year, d.month, d.day));
  }

  String _formatYmd(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openApprovers() async {
    final r = await showActivityApprovalLineDialog(
      context,
      initialNames: _approvalLineStampSlots,
      initialTitles: _rankLineStampSlots,
      initialUserIds: _approvalLineUserIds,
    );
    if (!mounted || r == null) return;
    setState(() {
      _approvalLineStampSlots = r.names;
      _rankLineStampSlots = r.titles;
      _approvalLineUserIds = List<String>.from(r.userIds);
    });
  }

  Future<void> _openStoreLookup() async {
    final selected = await showDialog<Store>(
      context: context,
      builder: (dialogContext) => const StoreLookupDialog(),
    );
    if (!mounted || selected == null) return;
    final detail =
        await StoreApiService().getStoreByIndex(selected.storeIdx) ?? selected;
    if (!mounted) return;
    setState(() => _selectedStore = detail);
  }

  ActivityWriteRequest? _payload(String apprStatus) {
    final store = _selectedStore;
    if (store == null) return null;

    // 로그인 유저 ID 가져오기
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    // 체크리스트 결과 수집
    final checklistResults = _chkSavePayload();
    final approvers = _peerApproverIds();
    // 임시저장(DRAFT)은 저장 시점의 작성일(오늘)로 act_dt 반영.
    final actDate = apprStatus == 'DRAFT' ? _today : _activityDate;

    return ActivityWriteRequest(
      storeIdx: store.storeIdx,
      actType: _activityKind,
      actDt: _formatYmd(actDate),
      memoTxt: _specialNotesController.text.trim(),
      actNotes: _activityNotesController.text.trim(),
      svId: userId.isEmpty ? null : userId,
      apprStatus: apprStatus,
      suggestions: _suggestionsController.text.trim(),
      svNotes: _svNotesController.text.trim(),
      apprUserIds: approvers.isEmpty ? null : approvers,
      checklistResults: checklistResults,
      usageLogIdx: _selectedUsageLogIdx,
    );
  }

  Future<bool> _pickTagHistoryIfPending(String apprStatus) async {
    if (apprStatus != 'PENDING') return true;
    final store = _selectedStore;
    if (store == null) return true;
    final userId = context.read<AuthProvider>().userId.trim();
    if (userId.isEmpty) return true;

    final picked = await showActivityTagHistoryPicker(
      context: context,
      userId: userId,
      storeIdx: store.storeIdx,
      storeNm: store.storeNm,
    );
    if (!mounted) return false;
    if (picked == null) return false;
    if (picked > 0) {
      setState(() => _selectedUsageLogIdx = picked);
    }
    return true;
  }

  /// 체크리스트 결과를 JSON 형식으로 반환
  List<ChkResultDtlSave>? _chkSavePayload() {
    final checklistState = _checklistKey.currentState;
    if (checklistState == null) return null;

    final items = checklistState._items;
    final results = checklistState._result;

    if (items.isEmpty || results.isEmpty) return null;

    final checklistResults = <ChkResultDtlSave>[];
    for (var i = 0; i < items.length; i++) {
      final answerVal = results[i];
      // "미평가"는 제외하고 실제 평가된 항목만 저장 (미평가는 빈 문자열이 아님)
      if (answerVal.isNotEmpty && answerVal != '미평가') {
        final base = items[i].baseScore ?? 0;
        checklistResults.add(
          ChkResultDtlSave(
            chkIdx: items[i].chkIdx,
            answerVal: answerVal,
            answerScore: answerVal == 'Y' ? base : 0,
          ),
        );
      }
    }

    return checklistResults.isEmpty ? null : checklistResults;
  }

  /// 체크리스트에 미평가 항목이 있는지 확인
  bool _chkHasGaps() {
    final checklistState = _checklistKey.currentState;
    if (checklistState == null) return false;

    final items = checklistState._items;
    final results = checklistState._result;

    // 체크리스트 항목이 있는데 미평가가 있으면 true
    if (items.isNotEmpty && results.contains('미평가')) {
      return true;
    }

    return false;
  }

  static const String _kChecklistGapStrictConfirmMessage =
      '미평가 체크리스트가 존재합니다.\n'
      '전자서명을 저장하면 입력된 내용 수정 불가합니다.\n'
      '바로 상신 하시겠습니까?';

  /// 미평가가 없으면 `true`, 있으면 동일 문구 확인 후 사용자 선택.
  Future<bool> _confirmChecklistGapsBeforeStrictAction() async {
    if (!_chkHasGaps()) return true;
    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '확인',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          _kChecklistGapStrictConfirmMessage,
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '취소',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text(
              '예',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _autosaveDraft() async {
    if (_isApprovalWorkflowView) return;
    if (_submitted || _autoSaving || _saving || _selectedStore == null) return;
    _autoSaving = true;
    final saved = await _pushAct('DRAFT');
    _autoSaving = false;
    if (saved != null) {
      final id = saved.actIdx;
      if (id != null) {
        _draftActIdx = id;
      }
    }
  }

  Future<void> _submitAct(String apprStatus) async {
    if (_selectedStore == null) {
      _toast('가맹점을 먼저 선택해 주세요.');
      return;
    }

    // 임시저장 건 상신 시 활동일자는 상신일(오늘)로 반영
    if (apprStatus == 'PENDING' && _isSubmittingFromDraft) {
      setState(() => _activityDate = _today);
    }

    // 상신 시 결재자(본인 제외) 및 체크리스트 검증
    if (apprStatus == 'PENDING') {
      final approvers = _peerApproverIds();
      if (approvers.isEmpty) {
        _toast('결재자를 한 명 이상(본인 제외) 지정해 주세요.');
        return;
      }
      for (var i = 1; i < kActivityApprovalLineSlotCount; i++) {
        final nm = _approvalLineStampSlots[i].trim();
        final rk = _rankLineStampSlots[i].trim();
        final id = _approvalLineUserIds[i].trim();
        if ((nm.isNotEmpty || rk.isNotEmpty) && id.isEmpty) {
          _toast('결재란 ${i + 1}열에 이름·직급이 있으면 결재자(사용자)를 선택한 뒤 상신해 주세요.');
          return;
        }
      }
      if (!await _confirmChecklistGapsBeforeStrictAction()) return;
      if (!await _pickTagHistoryIfPending(apprStatus)) return;
    }

    if (_saving) return;
    setState(() => _saving = true);
    final saved = await _pushAct(apprStatus);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      _toast('저장에 실패했습니다.');
      return;
    }
    final id = saved.actIdx;
    if (id != null) {
      _draftActIdx = id;
    }
    if (apprStatus == 'PENDING') {
      _submitted = true;
      _autoSaveTimer?.cancel();
    }

    // 저장 성공 메시지 표시 후 뒤로가기
    await showAlertDialog(
      context,
      apprStatus == 'PENDING' ? '상신되었습니다.' : '임시보관되었습니다.',
    );

    // 저장 후 화면 초기화 (새로운 활동 등록 준비)
    if (mounted && apprStatus == 'PENDING') {
      // 상신의 경우 폼 초기화
      setState(() {
        _selectedStore = null;
        _activityDate = _today;
        _activityKind = '방문';
        _activityNotesController.clear();
        _suggestionsController.clear();
        _specialNotesController.clear();
        _svNotesController.clear();
        _draftActIdx = null;
        _submitted = false;
      });
      // 체크리스트 초기화
      _checklistKey.currentState?.setChecklistResults(<ChkResultRow>[]);
      _initApprovalLine();
    }
  }

  Future<ActivitySaveResult?> _pushAct(String apprStatus) async {
    if (apprStatus == 'DRAFT' && mounted) {
      setState(() => _activityDate = _today);
    }
    final payload = _payload(apprStatus);
    if (payload == null) return null;
    final api = Act002Api();
    final actIdx = _draftActIdx;
    if (actIdx != null) {
      return api.update(actIdx, payload);
    }

    if (apprStatus == 'DRAFT' && _selectedStore != null) {
      final writerId = context.read<AuthProvider>().userId.trim();
      final rows = await api.fetchDraftRowsForStore(
        _selectedStore!.storeIdx,
        svId: writerId.isEmpty ? null : writerId,
      );
      int? existingDraftActIdx;
      for (final row in rows) {
        if (row.apprStatus.trim().toUpperCase() != 'DRAFT') continue;
        final rowStoreIdx = row.storeIdx;
        if (rowStoreIdx != _selectedStore!.storeIdx) continue;
        final rowActIdx = row.actIdx;
        if (rowActIdx == null) continue;
        if (existingDraftActIdx == null || rowActIdx > existingDraftActIdx) {
          existingDraftActIdx = rowActIdx;
        }
      }
      if (existingDraftActIdx != null) {
        return api.update(existingDraftActIdx, payload);
      }
    }

    return api.create(payload);
  }

  void _toast(String message) {
    if (!mounted) return;
    showAlertDialog(context, message);
  }

  Future<void> _openElectronicSignatureDialog() async {
    if (_isApprovalWorkflowView) return;
    final bytes = await showAct002ElectronicSignatureDialog(
      context,
      hasChecklistGaps: _chkHasGaps,
    );
    if (!mounted || bytes == null) return;
    await _submitWithSignature(bytes);
  }

  Future<void> _submitWithSignature(Uint8List bytes) async {
    if (_selectedStore == null) {
      _toast('가맹점을 먼저 선택해 주세요.');
      return;
    }

    final approvers = _peerApproverIds();
    if (approvers.isEmpty) {
      _toast('결재자를 한 명 이상(본인 제외) 지정해 주세요.');
      return;
    }
    for (var i = 1; i < kActivityApprovalLineSlotCount; i++) {
      final nm = _approvalLineStampSlots[i].trim();
      final rk = _rankLineStampSlots[i].trim();
      final id = _approvalLineUserIds[i].trim();
      if ((nm.isNotEmpty || rk.isNotEmpty) && id.isEmpty) {
        _toast('결재란 ${i + 1}열에 이름·직급이 있으면 결재자(사용자)를 선택한 뒤 상신해 주세요.');
        return;
      }
    }
    if (_saving) return;

    // 서명 이미지는 우선 미리보기로만 둔다. 서버 업로드는 상신(PENDING) 저장이
    // 성공한 뒤에만 수행한다. (저장 실패·취소 시 임시저장 건에 서명이 남는 문제 방지)
    setState(() {
      _electronicSignaturePng = bytes;
      _saving = true;
    });

    // 임시저장 건 상신 시 활동일자는 상신일(오늘)로 반영
    if (_isSubmittingFromDraft) {
      setState(() => _activityDate = _today);
    }

    // 1) 태그이력 선택 — 취소하면 상신·서명 업로드 모두 하지 않는다.
    if (!await _pickTagHistoryIfPending('PENDING')) {
      setState(() => _saving = false);
      return;
    }

    // 2) 상신(PENDING) 저장 — 성공한 경우에만 서명을 업로드한다.
    final saved = await _pushAct('PENDING');
    if (!mounted) return;
    if (saved == null) {
      setState(() => _saving = false);
      _toast('상신에 실패했습니다.');
      return;
    }
    final id = saved.actIdx;
    if (id != null) {
      _draftActIdx = id;
    }

    // 3) 서명 업로드 — 상신이 확정된 문서에만 저장한다.
    if (id != null) {
      final sigOk = await Act002Api().uploadSignature(id, bytes);
      if (!mounted) return;
      if (!sigOk) {
        setState(() => _saving = false);
        _toast('상신은 완료되었으나 전자서명 저장에 실패했습니다. 잠시 후 다시 시도해 주세요.');
        return;
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    _submitted = true;
    _autoSaveTimer?.cancel();

    await showAlertDialog(context, '상신되었습니다.');
    if (!mounted) return;

    setState(() {
      _selectedStore = null;
      _activityDate = _today;
      _activityKind = '방문';
      _activityNotesController.clear();
      _suggestionsController.clear();
      _specialNotesController.clear();
      _svNotesController.clear();
      _draftActIdx = null;
      _submitted = false;
      _electronicSignaturePng = null;
      _attachments = const [];
    });
    _checklistKey.currentState?.setChecklistResults(<ChkResultRow>[]);
    _initApprovalLine();
  }

  Future<void> _pickAttachment() async {
    if (_isApprovalWorkflowView) return;
    if (_selectedStore == null) {
      _toast('가맹점을 먼저 선택해 주세요.');
      return;
    }
    if (_uploadingAttachment) return;

    final picked = await pickStoreDocumentFiles();
    if (!mounted || picked.isEmpty) return;

    for (final file in picked) {
      if (file.bytes.length > Act002Api.maxAttachmentTotalBytes) {
        _toast('${file.name}: 첨부파일은 200MB 이하만 가능합니다.');
        return;
      }
    }

    setState(() => _uploadingAttachment = true);
    final actIdx = await _ensureActIdxForFiles();
    if (!mounted) return;
    if (actIdx == null) {
      setState(() => _uploadingAttachment = false);
      _toast('임시 저장에 실패했습니다. 다시 시도해 주세요.');
      return;
    }

    final userId = context.read<AuthProvider>().userId.trim();
    var successCount = 0;
    String? lastError;
    try {
      for (final file in picked) {
        if (!mounted) return;
        String? serverMsg;
        final uploaded = await Act002Api().uploadAttachment(
          actIdx: actIdx,
          fileName: file.name,
          bytes: file.bytes,
          userId: userId,
          onServerMessage: (m) => serverMsg = m,
        );
        if (uploaded != null) {
          successCount++;
        } else {
          lastError = serverMsg ?? '첨부 업로드에 실패했습니다.';
        }
      }
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
    if (!mounted) return;
    if (successCount == 0) {
      _toast(lastError ?? '첨부 업로드에 실패했습니다.');
      return;
    }
    if (successCount < picked.length) {
      _toast('$successCount/${picked.length}개 첨부가 업로드되었습니다.');
    }
    await _reloadAttachments(actIdx);
  }

  Future<void> _previewAttachment(ActAttachment row) async {
    final actIdx = _draftActIdx ?? widget.actIdx;
    if (actIdx == null) {
      _toast('미리보기할 활동 정보가 없습니다.');
      return;
    }
    final previewable = _attachments
        .where(
          (a) =>
              storeDocumentPreviewKindFor(a.fileName) !=
              StoreDocumentPreviewKind.unsupported,
        )
        .toList(growable: false);
    if (previewable.isEmpty) {
      _toast('이 파일 형식은 미리보기를 지원하지 않습니다.\n(이미지·PDF만 가능)');
      return;
    }
    final initialIndex = previewable.indexWhere(
      (a) => a.actAttIdx == row.actAttIdx,
    );
    if (!mounted) return;
    final api = Act002Api();
    await showStoreDocumentGalleryPreviewDialog(
      context: context,
      items: previewable
          .map(
            (a) => StoreDocumentPreviewItem(
              fileName: a.fileName,
              loadBytes: () => api.downloadAttachmentBytes(actIdx, a.actAttIdx),
            ),
          )
          .toList(growable: false),
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
    );
  }

  Future<void> _deleteAttachment(ActAttachment row) async {
    if (_isApprovalWorkflowView) return;
    final actIdx = _draftActIdx ?? widget.actIdx;
    if (actIdx == null) return;
    final ok = await Act002Api().deleteAttachment(actIdx, row.actAttIdx);
    if (!mounted) return;
    if (!ok) {
      _toast('첨부 삭제에 실패했습니다.');
      return;
    }
    await _reloadAttachments(actIdx);
  }

  Widget _buildAttachmentSection() {
    final canEdit = !_isApprovalWorkflowView;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton(
              onPressed: canEdit && !_uploadingAttachment
                  ? _pickAttachment
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.statusNew,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: Text(_uploadingAttachment ? '업로드 중...' : '첨부'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '* 전체 200MB까지 첨부 가능',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.statusNew,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._attachments.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: ReadonlyInputShell(
                      child: Text(
                        row.fileName,
                        style: FormStylePalette.valueStyle.copyWith(
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _previewAttachment(row),
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
                  if (canEdit) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _deleteAttachment(row),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: '삭제',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  static const TextStyle _signatureLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: FormStylePalette.textPrimary,
    fontFamilyFallback: AppTheme.koreanFontFallback,
  );

  static const TextStyle _signatureDisclaimerStyle = TextStyle(
    fontSize: 14,
    color: AppTheme.accentRed,
    height: 1.4,
    fontWeight: FontWeight.w600,
    fontFamilyFallback: AppTheme.koreanFontFallback,
  );

  Widget _buildSignatureBox() {
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FormStylePalette.panelBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isApprovalWorkflowView
              ? null
              : _openElectronicSignatureDialog,
          child: Center(
            child: _electronicSignaturePng != null
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.memory(
                      _electronicSignaturePng!,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.medium,
                    ),
                  )
                : Text(
                    '(서명)',
                    style: TextStyle(
                      color: FormStylePalette.textMuted,
                      fontSize: 14,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildElectronicSignatureSection(BuildContext context) {
    final compact = useCompactErpLayout(context);
    const disclaimer =
        '* 전자서명을 저장하면 입력된 내용 수정 불가하며 자동 상신됩니다.\n'
        '   저장 전에 활동관리 작성을 완료하세요.';

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('전자 서명', style: _signatureLabelStyle),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: _buildSignatureBox()),
          const SizedBox(height: 8),
          Text(disclaimer, style: _signatureDisclaimerStyle),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: FormStylePalette.labelWidth,
          child: Text('전자 서명', style: _signatureLabelStyle),
        ),
        _buildSignatureBox(),
        const SizedBox(width: 16),
        Expanded(child: Text(disclaimer, style: _signatureDisclaimerStyle)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.listScreenHPadding,
          8,
          AppDimensions.listScreenHPadding,
          AppDimensions.listScreenBottomPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FormStylePalette.formMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionTitle('결재 정보'),
                      const SizedBox(height: 20),
                      _ApprovalTable(
                        approvalStampSlots: _approvalLineStampSlots
                            .take(kActivityApprovalLineSlotCount)
                            .toList(),
                        rankStampSlots: _rankLineStampSlots
                            .take(kActivityApprovalLineSlotCount)
                            .toList(),
                        approvalUserIds: List<String>.from(
                          _approvalLineUserIds.take(
                            kActivityApprovalLineSlotCount,
                          ),
                        ),
                        apprAckUserIds: _apprAckUserIds,
                        apprAckDateByUserId: _apprAckDateByUserId,
                        documentWrittenAt: _docWrittenAtDisplay,
                        writerSealDate: _writerSealDateDisplay,
                        loadedApprStatus: _loadedApprStatus,
                        deptNm: _deptNm,
                        drafterNm: _drafterNm,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: useCompactErpLayout(context) ? 8 : 12),
                Text(
                  '• 모바일 앱에서 가맹점출입관리 실행 후 태깅을 진행해주세요.\n'
                  '내용 입력 후 상신하기 버튼을 클릭하여 태그 이력을 선택해 주세요.\n'
                  '• 태그 이력은 다음날 12시전에 활동관리를 상신해야 실적으로 인정됩니다.',
                  textAlign: useCompactErpLayout(context)
                      ? TextAlign.left
                      : TextAlign.right,
                  style: TextStyle(
                    fontSize: useCompactErpLayout(context) ? 12 : 13,
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                SizedBox(height: useCompactErpLayout(context) ? 8 : 16),
                _PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SearchInputSectionHeader(
                        isApprovalWorkflowView: _isApprovalWorkflowView,
                        onOpenApprovers: _openApprovers,
                      ),
                      SizedBox(height: 12),
                      _TwoColRow(
                        left: _LabeledField(
                          label: '가맹점',
                          requiredMark: true,
                          child: _SearchLikeField(
                            hint: '',
                            value: _selectedStore?.storeNm,
                            onTap: _openStoreLookup,
                            enabled: !_isApprovalWorkflowView,
                          ),
                        ),
                        right: _LabeledField(
                          label: '브랜드',
                          requiredMark: true,
                          child: _outlineInput(
                            hint: _selectedStore?.brandNm ?? '',
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      _TwoColRow(
                        left: _LabeledField(
                          label: '가맹점코드',
                          child: _outlineInput(
                            hint: _selectedStore?.storeCd ?? '',
                          ),
                        ),
                        right: const _FormColSpacer(),
                      ),
                      SizedBox(height: 12),
                      _TwoColRow(
                        left: _LabeledField(
                          label: '활동구분',
                          requiredMark: true,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            isDense: true,
                            // ignore: deprecated_member_use
                            value: _kinds.contains(_activityKind)
                                ? _activityKind
                                : '방문',
                            decoration: _inputDeco('선택'),
                            // 드롭다운 메뉴 항목: [itemHeight]는 null이 아니면 >= kMinInteractiveDimension(48) 필수.
                            itemHeight: kMinInteractiveDimension,
                            style: kActivityFormValueStyle,
                            borderRadius: BorderRadius.circular(8),
                            items: const [
                              DropdownMenuItem(value: '상담', child: Text('상담')),
                              DropdownMenuItem(value: '방문', child: Text('방문')),
                              DropdownMenuItem(value: '점검', child: Text('점검')),
                              DropdownMenuItem(value: '전화', child: Text('전화')),
                            ],
                            onChanged: !_isApprovalWorkflowView
                                ? (v) {
                                    if (v == null) return;
                                    setState(() => _activityKind = v);
                                  }
                                : null,
                          ),
                        ),
                        right: _LabeledField(
                          label: '활동일자',
                          requiredMark: true,
                          child: _ActivityFormDateField(
                            labelText: _formatYmd(_activityDate),
                            onPick: !_isApprovalWorkflowView
                                ? _pickActDate
                                : () {},
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      _TwoColRow(
                        left: _LabeledField(
                          label: '등록일자',
                          child: _fieldShell(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                !_isApprovalWorkflowView
                                    ? _formatYmd(_today)
                                    : _formatYmd(_activityDate),
                                style: kActivityFormValueStyle,
                              ),
                            ),
                          ),
                        ),
                        right: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _StoreBasicInfoPanel(store: _selectedStore),
                const SizedBox(height: 20),
                _PanelCard(
                  child: _LabeledField(
                    label: '특이사항',
                    child: _outlineInput(
                      hint: '',
                      maxLines: 4,
                      controller: _specialNotesController,
                      readOnly: !_isApprovalWorkflowView ? false : true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ChecklistBlock(
                  key: _checklistKey,
                  store: _selectedStore,
                  readOnly: _isApprovalWorkflowView,
                ),
                const SizedBox(height: 20),
                _PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LabeledField(
                        label: '주요상담내용',
                        requiredMark: true,
                        child: _outlineInput(
                          hint: '',
                          maxLines: 7,
                          controller: _activityNotesController,
                          readOnly: !_isApprovalWorkflowView ? false : true,
                        ),
                      ),
                      SizedBox(height: 16),
                      _LabeledField(
                        label: '건의사항',
                        child: _outlineInput(
                          hint: '',
                          maxLines: 7,
                          controller: _suggestionsController,
                          readOnly: !_isApprovalWorkflowView ? false : true,
                        ),
                      ),
                      SizedBox(height: 16),
                      _LabeledField(
                        label: '담당 수퍼바이저 의견',
                        child: _outlineInput(
                          hint: '',
                          maxLines: 7,
                          controller: _svNotesController,
                          readOnly: !_isApprovalWorkflowView ? false : true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildAttachmentSection(),
                SizedBox(height: useCompactErpLayout(context) ? 12 : 20),
                _buildElectronicSignatureSection(context),
                SizedBox(height: useCompactErpLayout(context) ? 8 : 10),
                _PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LabeledField(
                        label: '     지시사항\n(결재특이사항)',
                        child: _outlineInput(
                          hint: '',
                          maxLines: 7,
                          controller: _apprNotesController,
                          readOnly: _canSubmitApproval
                              ? false
                              : true, // 결재 대기 중에만 작성가능
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isApprovalWorkflowView) ...[
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _saving ? null : () => _submitAct('PENDING'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accentRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: Text(_saving ? '저장 중...' : '상신하기'),
                      ),
                      OutlinedButton(
                        onPressed: _saving ? null : () => _submitAct('DRAFT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accentRed,
                          side: const BorderSide(color: AppTheme.accentRed),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('임시보관'),
                      ),
                    ],
                  ),
                ],
                if (_canSubmitApproval) ...[
                  const SizedBox(height: 15),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 30,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _approving ? null : () => _submitApprove(),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF047857),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: Text(_approving ? '처리 중...' : '결재하기'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FormStylePalette.panelBg,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: FormStylePalette.panelBorder),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SearchInputSectionHeader extends StatelessWidget {
  const _SearchInputSectionHeader({
    required this.isApprovalWorkflowView,
    required this.onOpenApprovers,
  });

  final bool isApprovalWorkflowView;
  final VoidCallback onOpenApprovers;

  @override
  Widget build(BuildContext context) {
    final hint = Text(
      '(* 가맹점을 먼저 선택해 주세요.)',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.accentRed,
        height: 1.35,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
    );
    final lineButton = FilledButton(
      onPressed: isApprovalWorkflowView ? null : onOpenApprovers,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.accentRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: const Text('결재라인'),
    );

    if (useCompactErpLayout(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('검색·입력'),
          const SizedBox(height: 8),
          hint,
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: lineButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _SectionTitle('검색·입력'),
        const SizedBox(width: 12),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: hint),
        ),
        const SizedBox(width: 12),
        lineButton,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: FormStylePalette.textPrimary,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
    );
  }
}

class _StoreBasicInfoPanel extends StatelessWidget {
  const _StoreBasicInfoPanel({required this.store});

  final Store? store;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [const Expanded(child: _SectionTitle('가맹점 기본정보'))]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton(
                onPressed: store == null
                    ? null
                    : () {
                        showDialog<void>(
                          context: context,
                          builder: (_) => VisitHistoryDialog(
                            storeIdx: store!.storeIdx,
                            brandNm: store!.brandNm,
                            storeNm: store!.storeNm,
                          ),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color.fromARGB(255, 230, 68, 117),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 230, 68, 117),
                  ),
                ),
                child: const Text('방문이력 보기'),
              ),
              OutlinedButton(
                onPressed: store == null
                    ? null
                    : () {
                        showActivityInstructionsDialog(
                          context,
                          storeIdx: store!.storeIdx,
                          brandNm: store!.brandNm,
                          storeNm: store!.storeNm,
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color.fromARGB(255, 230, 68, 117),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 230, 68, 117),
                  ),
                ),
                child: const Text('지시사항 보기'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            store == null
                ? '가맹점 검색 후 선택하면 사업자·계약·임대·면적 정보가 자동 입력됩니다.'
                : '선택한 가맹점의 기본정보가 자동 입력되었습니다.',
            style: const TextStyle(
              fontSize: 12,
              color: FormStylePalette.textSecondary,
              height: 1.35,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const SizedBox(height: 8),
          _StoreBasicInfoFields(store: store),
        ],
      ),
    );
  }

  static String _intText(int? value) {
    if (value == null || value == 0) return '—';
    return value.toString();
  }

  static String _moneyText(int? value) {
    if (value == null || value == 0) return '—';
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(',');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  static String _decimalText(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed == 0) return '—';
    return parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 2);
  }

  static String _pyeongText(String? sqmText) {
    final sqm = double.tryParse(sqmText ?? '');
    if (sqm == null || sqm == 0) return '—';
    return (sqm / 3.305785).toStringAsFixed(2);
  }
}

class _StoreBasicInfoFields extends StatelessWidget {
  const _StoreBasicInfoFields({required this.store});

  final Store? store;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    final labelW = compact ? 132.0 : _kStoreLabelWidth;
    final labelTight = compact ? 96.0 : _kStoreLabelWidthTight;

    final ownerRow = _LabeledField(
      label: compact ? '사업자 성명' : '가맹점 사업자 성명',
      valignWithField: !compact,
      labelWidth: labelW,
      labelMaxLines: 2,
      stacked: compact,
      child: _roVal(store?.ownerNm, expand: compact),
    );
    final managerRow = _LabeledField(
      label: compact ? '계약 담당자' : '가맹계약 담당자',
      valignWithField: !compact,
      labelWidth: labelW,
      labelMaxLines: 2,
      stacked: compact,
      child: _roVal(store?.contManager, expand: compact),
    );
    final contPeriodValue = Row(
      children: [
        Expanded(child: _roVal(store?.contStartDt, expand: true)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('—', style: kActivityFormValueStyle),
        ),
        Expanded(child: _roVal(store?.contEndDt, expand: true)),
      ],
    );

    final firstContRow = _LabeledField(
      label: compact ? '최초 체결일' : '최초 가맹계약 체결일자',
      valignWithField: !compact,
      labelWidth: labelW,
      labelMaxLines: 2,
      stacked: compact,
      child: _roVal(store?.firstContDt, expand: compact),
    );
    final contPeriodRow = _LabeledField(
      label: compact ? '현재 계약기간' : '현재 가맹계약 기간',
      valignWithField: !compact,
      labelWidth: labelW,
      labelMaxLines: 2,
      stacked: compact,
      child: compact
          ? contPeriodValue
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _roVal(store?.contStartDt),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('—', style: kActivityFormValueStyle),
                ),
                _roVal(store?.contEndDt),
              ],
            ),
    );

    final depositRow = _LabeledField(
      label: '임대차보증금',
      valignWithField: !compact,
      labelWidth: labelTight,
      labelMaxLines: 2,
      stacked: compact,
      child: _roUnit(_StoreBasicInfoPanel._moneyText(store?.rentDeposit), '원'),
    );
    final premiumRow = _LabeledField(
      label: '권리금',
      valignWithField: !compact,
      labelWidth: labelTight,
      labelMaxLines: 2,
      stacked: compact,
      child: _roUnit(_StoreBasicInfoPanel._moneyText(store?.premiumFee), '원'),
    );
    final rentRow = _LabeledField(
      label: '임차료(정액)',
      valignWithField: !compact,
      labelWidth: labelTight,
      labelMaxLines: 2,
      stacked: compact,
      child: _roUnit(_StoreBasicInfoPanel._moneyText(store?.monthlyRent), '원'),
    );
    final floorRow = _LabeledField(
      label: '층수',
      valignWithField: !compact,
      labelWidth: labelTight,
      labelMaxLines: 2,
      stacked: compact,
      child: _roUnit(_StoreBasicInfoPanel._intText(store?.floor), '층'),
    );
    final contAreaRow = _LabeledField(
      label: '면적(계약㎡)',
      valignWithField: !compact,
      labelWidth: labelTight,
      labelMaxLines: 2,
      stacked: compact,
      child: _roUnit(_StoreBasicInfoPanel._decimalText(store?.contArea), 'm²'),
    );
    final contPyeongRow = _LabeledField(
      label: '면적(계약평)',
      valignWithField: !compact,
      labelWidth: labelTight,
      labelMaxLines: 2,
      stacked: compact,
      child: _roUnit(_StoreBasicInfoPanel._pyeongText(store?.contArea), '평'),
    );
    final realAreaRow = _LabeledField(
      label: '면적(실㎡)',
      valignWithField: !compact,
      labelWidth: labelTight,
      labelMaxLines: 2,
      stacked: compact,
      child: _roUnit(_StoreBasicInfoPanel._decimalText(store?.realArea), 'm²'),
    );
    final realPyeongRow = _LabeledField(
      label: '면적(실평)',
      valignWithField: !compact,
      labelWidth: labelTight,
      labelMaxLines: 2,
      stacked: compact,
      child: _roUnit(_StoreBasicInfoPanel._pyeongText(store?.realArea), '평'),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TwoColRow(keepRowOnCompact: true, left: ownerRow, right: managerRow),
          const SizedBox(height: 8),
          _TwoColRow(
            keepRowOnCompact: true,
            left: firstContRow,
            right: contPeriodRow,
          ),
          const SizedBox(height: 8),
          _TwoColRow(
            keepRowOnCompact: true,
            left: depositRow,
            right: premiumRow,
          ),
          const SizedBox(height: 8),
          _TwoColRow(keepRowOnCompact: true, left: rentRow, right: floorRow),
          const SizedBox(height: 8),
          _TwoColRow(
            keepRowOnCompact: true,
            left: contAreaRow,
            right: contPyeongRow,
          ),
          const SizedBox(height: 8),
          _TwoColRow(
            keepRowOnCompact: true,
            left: realAreaRow,
            right: realPyeongRow,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TwoColRow(left: ownerRow, right: managerRow),
        const SizedBox(height: 8),
        _TwoColRow(left: firstContRow, right: contPeriodRow),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: depositRow),
            const SizedBox(width: 16),
            Expanded(child: premiumRow),
            const SizedBox(width: 16),
            Expanded(child: rentRow),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: floorRow),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: _LabeledField(
                label: '면적(계약㎡)',
                valignWithField: true,
                labelWidth: labelTight,
                labelMaxLines: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: _roUnit(
                        _StoreBasicInfoPanel._decimalText(store?.contArea),
                        'm²',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _roUnit(
                        _StoreBasicInfoPanel._pyeongText(store?.contArea),
                        '평',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: _LabeledField(
                label: '면적(실㎡)',
                valignWithField: true,
                labelWidth: labelTight,
                labelMaxLines: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: _roUnit(
                        _StoreBasicInfoPanel._decimalText(store?.realArea),
                        'm²',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _roUnit(
                        _StoreBasicInfoPanel._pyeongText(store?.realArea),
                        '평',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TwoColRow extends StatelessWidget {
  const _TwoColRow({
    required this.left,
    required this.right,
    this.keepRowOnCompact = false,
  });

  final Widget left;
  final Widget right;
  final bool keepRowOnCompact;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    if (compact && !keepRowOnCompact) {
      final children = <Widget>[left];
      if (right is! _FormColSpacer) {
        children.addAll([const SizedBox(height: 12), right]);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    if (right is _FormColSpacer) {
      return left;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: compact ? 8 : 12),
        Expanded(child: right),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.requiredMark = false,

    /// 가맹점 기본정보 등: 라벨·값을 세로 **중앙** 정렬(한 줄 값이 라벨 아래로 밀리는 느낌 완화).
    this.valignWithField = false,
    this.labelWidth = 118,
    this.labelMaxLines = 2,
    this.stacked = false,
  });

  final String label;
  final Widget child;
  final bool requiredMark;
  final bool valignWithField;
  final double labelWidth;
  final int labelMaxLines;
  final bool stacked;

  Widget _labelText() {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: FormStylePalette.textPrimary,
          height: 1.3,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
        children: [
          if (requiredMark)
            const TextSpan(
              text: '* ',
              style: TextStyle(
                color: AppTheme.accentRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          TextSpan(text: label),
        ],
      ),
      maxLines: labelMaxLines,
      softWrap: true,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final useStacked = stacked || useCompactErpLayout(context);

    if (useStacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_labelText(), const SizedBox(height: 6), child],
      );
    }

    return Row(
      crossAxisAlignment: valignWithField
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Padding(
            padding: EdgeInsets.only(top: valignWithField ? 0 : 8),
            child: _labelText(),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(child: child),
      ],
    );
  }
}

class _SearchLikeField extends StatelessWidget {
  const _SearchLikeField({
    required this.hint,
    this.value,
    required this.onTap,
    this.enabled = true,
  });

  final String hint;
  final String? value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final display = value?.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: _fieldShell(
          Row(
            children: [
              Expanded(
                child: Text(
                  display == null || display.isEmpty ? hint : display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: display == null || display.isEmpty
                      ? kActivityFormValueStyle.copyWith(
                          color: FormStylePalette.textMuted,
                        )
                      : kActivityFormValueStyle,
                ),
              ),
              const SizedBox(width: 8),
              if (enabled)
                const Icon(
                  Icons.search,
                  size: 20,
                  color: FormStylePalette.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 결재 칸 도장 표시 — 채움은 실제 결재(또는 전체 완료 후 기안란)에만 사용한다.
enum _ApprovalSealKind { none, filled }

/// 결재정보 — 브랜드 레드 라벨 열 + 밝은 본문 (테마 [FormStylePalette] / [AppTheme]).
class _ApprovalTable extends StatelessWidget {
  const _ApprovalTable({
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
  });

  final List<String> approvalStampSlots;
  final List<String> rankStampSlots;
  final List<String> approvalUserIds;
  final Set<String> apprAckUserIds;
  final Map<String, String> apprAckDateByUserId;
  final String documentWrittenAt;
  final String writerSealDate;

  /// 서버에서 온 `apprStatus` — 없으면 신규 작성·미로드로 간주해 도장 채움을 쓰지 않는다.
  final String? loadedApprStatus;
  final String deptNm;
  final String drafterNm;

  static const double _labelW = 95;
  static const double _slotMinW = 72;
  static const double _tableMinWidth =
      _labelW + kActivityApprovalLineSlotCount * _slotMinW;
  static const double _rowSingleH = 40;
  static const double _rowDeptH = 30;
  static const double _rowRankGridH = 40;
  static const double _rowSealGridH = 56;
  static const double _rowDateGridH = 34;

  /// 모바일 가로 스크롤 래퍼 높이 — [IntrinsicHeight] 대신 고정(무한 세로 제약 시 멈춤 방지).
  static const double _compactTableScrollHeight =
      _rowSingleH +
      _rowDeptH +
      _rowSingleH +
      _rowRankGridH +
      _rowSealGridH +
      _rowDateGridH +
      6;
  static int get _slotCount => kActivityApprovalLineSlotCount;
  static const double _textSize = 13.0;
  static const double _sealDiameter = 52;

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

  /// 결재 칸 빨간 채움 — `apprAckUserIds`만으로는 부족할 수 있어(키 불일치 등),
  /// 서버가 내려준 `apprAckDateByUserId`에 **해당 사용자의 결재일**이 있을 때만 인정한다.
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
    var day = apprAckDateByUserId[ackId]?.trim() ?? '';
    if (day.isEmpty) day = apprAckDateByUserId[u]?.trim() ?? '';
    if (day.isEmpty) {
      for (final e in apprAckDateByUserId.entries) {
        if (e.key.trim() == u && e.value.toString().trim().isNotEmpty) {
          return true;
        }
      }
      return false;
    }
    return true;
  }

  _ApprovalSealKind _sealKind(int i) {
    final name = _paddedApprovalNames[i].trim();
    if (name.isEmpty) return _ApprovalSealKind.none;
    if (i == 0) {
      final st = _normApprStatus;
      // 기안자: 상신(PENDING) 시점부터 결재한 것과 동일하게 채움 도장(결재완료도 동일).
      if ((st == 'PENDING' || st == 'APPROVED') &&
          writerSealDate.trim().isNotEmpty) {
        return _ApprovalSealKind.filled;
      }
      return _ApprovalSealKind.none;
    }
    final uid = _paddedUserIds[i].trim();
    if (uid.isEmpty) return _ApprovalSealKind.none;
    if (_peerHasConfirmedApproval(uid)) return _ApprovalSealKind.filled;
    return _ApprovalSealKind.none;
  }

  /// 결재일자 행 — 1열부터는 실제 결재 확인된 경우에만 날짜를 진하게 표시한다.
  bool _dateCellEmphasis(int i) {
    if (i == 0) return _slotDateLabel(i).trim().isNotEmpty;
    return _sealKind(i) == _ApprovalSealKind.filled;
  }

  String _slotDateLabel(int i) {
    if (i == 0) return writerSealDate;
    final uid = _paddedUserIds[i].trim();
    if (uid.isEmpty) return '';
    return apprAckDateByUserId[uid]?.trim() ?? '';
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
            _rankGridRow(ranks, edge),
            _sealGridRow(names, edge),
            _dateGridRow(edge),
          ],
        ),
      ),
    );

    if (!useCompactErpLayout(context)) {
      return Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: table,
        ),
      );
    }

    return SizedBox(
      height: _compactTableScrollHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: _tableMinWidth, child: table),
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

  Widget _sealGridRow(List<String> names, Color edge) {
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

  Widget _dateGridRow(Color edge) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: edge, width: 1)),
      ),
      height: _rowDateGridH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labelCol('결재일자'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _slotCount; i++)
                  Expanded(
                    child: _dateCell(
                      _slotDateLabel(i),
                      showText: _dateCellEmphasis(i),
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
          color: Color.fromARGB(255, 218, 79, 86),
          border: Border(
            right: BorderSide(
              color: FormStylePalette.approvalTableBorder,
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              t,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: _textSize,
                fontWeight: FontWeight.w700,
                height: compact ? 1.15 : 2,
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

  Widget _sealCell(
    String nameRaw, {
    required _ApprovalSealKind kind,
    required Color edge,
    required bool isLast,
  }) {
    final name = nameRaw.trim();
    const sealRed = Color.fromARGB(255, 238, 92, 92);
    final nameTextStyle = TextStyle(
      color: kind == _ApprovalSealKind.filled
          ? Colors.white
          : FormStylePalette.textPrimary,
      fontSize: kind == _ApprovalSealKind.filled ? 11 : 12,
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
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: name.isEmpty
            ? const SizedBox.shrink()
            : kind == _ApprovalSealKind.none
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FormStylePalette.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              )
            : Container(
                width: _sealDiameter,
                height: _sealDiameter,
                decoration: BoxDecoration(
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
      ),
    );
  }

  Widget _dateCell(
    String dateRaw, {
    required bool showText,
    required Color edge,
    required bool isLast,
  }) {
    final date = dateRaw.trim();
    return ColoredBox(
      color: FormStylePalette.approvalTableDataBg,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: isLast ? BorderSide.none : BorderSide(color: edge, width: 1),
          ),
        ),
        child: showText && date.isNotEmpty
            ? Text(
                date,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FormStylePalette.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _ChecklistBlock extends StatefulWidget {
  const _ChecklistBlock({
    super.key,
    required this.store,
    this.readOnly = false,
  });

  final Store? store;

  /// 결재대기·결재완료 상세 — 체크리스트 수정 불가.
  final bool readOnly;

  @override
  State<_ChecklistBlock> createState() => _ChecklistBlockState();
}

class _ChecklistBlockState extends State<_ChecklistBlock> {
  List<ChecklistItem> _items = [];
  late final List<String> _result = [];
  bool _loading = true;

  /// 상세 로드 시 API 결과가 마스터 행보다 먼저 오면 여기 보관 후 `_loadChecklists` 완료 시 반영
  List<ChkResultRow>? _pendingChecklistResults;

  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  @override
  void didUpdateWidget(covariant _ChecklistBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.store?.brandCd != oldWidget.store?.brandCd) {
      _pendingChecklistResults = null;
      _loadChecklists();
    }
  }

  Future<void> _loadChecklists() async {
    if (widget.store == null || widget.store!.brandCd.isEmpty) {
      setState(() {
        _items = [];
        _result.clear();
        _pendingChecklistResults = null;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final items = await Act002Api().fetchChecklistMastersByBrand(
        widget.store!.brandCd,
      );
      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
        _syncResultFromPending();
      });
    } catch (e) {
      debugPrint('체크리스트 로드 에러: $e');
      if (!mounted) return;
      setState(() {
        _items = [];
        _result.clear();
        _loading = false;
      });
    }
  }

  /// 체크박스는 Y/N 만 비교하므로 서버·JSON 변형을 통일
  String _normalizeAnswerVal(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty || s == '미평가') return '미평가';
    final upper = s.toUpperCase();
    if (upper == 'Y' || s == '1' || s == '적합') return 'Y';
    if (upper == 'N' || s == '0' || s == '미적합') return 'N';
    return s;
  }

  void _syncResultFromPending() {
    _result.clear();
    if (_items.isEmpty) return;

    final pending = _pendingChecklistResults;
    if (pending == null || pending.isEmpty) {
      _result.addAll(List.filled(_items.length, '미평가'));
      return;
    }

    final resultMap = <int, String>{};
    for (final row in pending) {
      if (row.chkIdx == 0) continue;
      resultMap[row.chkIdx] = _normalizeAnswerVal(row.answerVal);
    }

    for (final item in _items) {
      _result.add(resultMap[item.chkIdx] ?? '미평가');
    }
  }

  /// 체크리스트 결과 설정 (임시보관 상세 로드 시 사용)
  void setChecklistResults(List<ChkResultRow> results) {
    _pendingChecklistResults = List<ChkResultRow>.from(results);
    if (!mounted || _items.isEmpty) return;
    setState(_syncResultFromPending);
  }

  /// 모든 항목을 적합(Y)으로 선택합니다.
  void _checkAllSuitable() {
    if (_items.isEmpty || _result.length != _items.length) return;
    setState(() {
      for (var i = 0; i < _result.length; i++) {
        _result[i] = 'Y';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle('체크리스트'),
            SizedBox(height: 20),
            CommonLoadingIndicator(),
            SizedBox(height: 20),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const _PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle('체크리스트'),
            SizedBox(height: 12),
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '가맹점을 선택하면 해당 브랜드의 체크리스트가 표시됩니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color.fromARGB(120, 156, 163, 175),
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('체크리스트'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.readOnly ? null : _checkAllSuitable,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '적합 모두 체크',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _ChecklistTable(
            items: _items,
            results: _result,
            readOnly: widget.readOnly,
            onTapY: (i) {
              setState(() {
                _result[i] = _result[i] == 'Y' ? '미평가' : 'Y';
              });
            },
            onTapN: (i) {
              setState(() {
                _result[i] = _result[i] == 'N' ? '미평가' : 'N';
              });
            },
          ),
        ],
      ),
    );
  }
}

class _ChecklistTable extends StatelessWidget {
  const _ChecklistTable({
    required this.items,
    required this.results,
    required this.readOnly,
    required this.onTapY,
    required this.onTapN,
  });

  final List<ChecklistItem> items;
  final List<String> results;
  final bool readOnly;
  final ValueChanged<int> onTapY;
  final ValueChanged<int> onTapN;

  static const double _minTableWidth = 560;
  static const Map<int, TableColumnWidth> _columnWidths = {
    0: FixedColumnWidth(44),
    1: FixedColumnWidth(88),
    2: FlexColumnWidth(1.6),
    3: FixedColumnWidth(148),
  };

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    final table = Table(
      columnWidths: _columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: kErpTableInnerGridBorder,
      children: [
        const TableRow(
          decoration: BoxDecoration(color: FormStylePalette.tableHeaderBg),
          children: [
            _ChHdr('번호'),
            _ChHdr('구분'),
            _ChHdr('체크항목'),
            _ChHdr('체크결과'),
          ],
        ),
        for (var i = 0; i < items.length; i++)
          TableRow(
            children: [
              _ChCell('${i + 1}'),
              _ChCell(items[i].chkTypeNm),
              _ChCell(items[i].chkContent, left: true, wrap: true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: _ChecklistResultCell(
                  yChecked: results[i] == 'Y',
                  nChecked: results[i] == 'N',
                  readOnly: readOnly,
                  onTapY: () => onTapY(i),
                  onTapN: () => onTapN(i),
                ),
              ),
            ],
          ),
      ],
    );

    final bordered = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: FormStylePalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: table,
    );

    if (!compact) return bordered;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(width: _minTableWidth, child: bordered),
    );
  }
}

class _ChecklistResultCell extends StatelessWidget {
  const _ChecklistResultCell({
    required this.yChecked,
    required this.nChecked,
    required this.readOnly,
    required this.onTapY,
    required this.onTapN,
  });

  final bool yChecked;
  final bool nChecked;
  final bool readOnly;
  final VoidCallback onTapY;
  final VoidCallback onTapN;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _checkOption(
          label: '적합',
          checked: yChecked,
          onTap: readOnly ? null : onTapY,
        ),
        const SizedBox(width: 10),
        _checkOption(
          label: '미적합',
          checked: nChecked,
          onTap: readOnly ? null : onTapN,
        ),
      ],
    );
  }

  Widget _checkOption({
    required String label,
    required bool checked,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: checked,
              onChanged: onTap == null ? null : (_) => onTap(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: FormStylePalette.textPrimary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChHdr extends StatelessWidget {
  const _ChHdr(this.t);

  final String t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: FormStylePalette.textPrimary,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

class _ChCell extends StatelessWidget {
  const _ChCell(this.t, {this.left = false, this.wrap = false});

  final String t;
  final bool left;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        t,
        textAlign: left ? TextAlign.start : TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: FormStylePalette.textPrimary,
          fontFamilyFallback: AppTheme.koreanFontFallback,
          height: 1.35,
        ),
        maxLines: wrap ? null : 3,
        overflow: wrap ? TextOverflow.visible : TextOverflow.ellipsis,
        softWrap: wrap,
      ),
    );
  }
}

InputDecoration _inputDeco(String hint) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    fillColor: FormStylePalette.inputBg,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
  );
}

Widget _outlineInput({
  required String hint,
  int maxLines = 1,
  TextEditingController? controller,
  bool readOnly = true,
}) {
  return TextField(
    controller: controller,
    readOnly: readOnly,
    maxLines: maxLines,
    style: kActivityFormValueStyle,
    decoration: _inputDeco(hint),
  );
}
