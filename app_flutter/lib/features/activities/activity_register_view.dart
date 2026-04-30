// 활동 관리 등록 — 제공 화면 구조·[FormStylePalette] 톤.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart'
    show CalendarPickButton, showAccentDatePicker;
import 'package:app_flutter/core/auth/auth_provider.dart';

import 'package:app_flutter/features/activities/activity_approval_line_dialog.dart';
import 'package:app_flutter/features/activities/activity_api_service.dart';
import 'package:app_flutter/features/activities/activity_instructions_dialog.dart';
import 'package:app_flutter/features/activities/activity_visit_history_dialog.dart';
import 'package:app_flutter/features/activities/checklist_api_service.dart';
import 'package:app_flutter/features/stores/store_api_service.dart';
import 'package:app_flutter/features/stores/store_model.dart';

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
  fontSize: 13,
  height: 1.3,
  color: FormStylePalette.textPrimary,
  fontFamilyFallback: AppTheme.koreanFontFallback,
);

Widget _activityFormFieldShell(Widget child) {
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
Widget _storeReadonlyValue(String? text) {
  final empty = text == null || text.trim().isEmpty;
  final s = empty
      ? kActivityFormValueStyle.copyWith(color: FormStylePalette.textMuted)
      : kActivityFormValueStyle;
  final display = empty ? '' : text.trim();
  return Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: _kStoreReadonlyMinWidth,
        maxWidth: _kStoreReadonlyMaxWidth,
      ),
      child: IntrinsicWidth(
        child: _activityFormFieldShell(
          _StoreFieldLineContent(
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              strutStyle: StrutStyle(
                fontSize: s.fontSize,
                height: s.height,
                fontFamily: s.fontFamily,
                fontFamilyFallback: s.fontFamilyFallback,
                leadingDistribution: TextLeadingDistribution.even,
              ),
              style: s,
            ),
          ),
        ),
      ),
    ),
  );
}

/// 값 + 우측 단위(원, m², 평, 층) — [kActivityFormValueStyle] 맞춤.
///
/// [Expanded] / 좁은 [Row] 내부에 둘 때 [IntrinsicWidth]를 쓰지 않아 가로 오버플로를 막는다.
Widget _storeReadonlyWithUnit(String value, String unit) {
  const uStyle = TextStyle(
    fontSize: 13,
    color: FormStylePalette.textMuted,
    fontFamilyFallback: AppTheme.koreanFontFallback,
  );
  return _activityFormFieldShell(
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

/// 텍스트필드·읽기전용·[_activityFormFieldShell] 과 동일한 높이감·달력 피킹.
class _ActivityFormDateField extends StatelessWidget {
  const _ActivityFormDateField({required this.labelText, required this.onPick});

  final String labelText;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(8),
              child: _activityFormFieldShell(
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(labelText, style: kActivityFormValueStyle),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        CalendarPickButton(onPressed: onPick),
      ],
    );
  }
}

/// 활동을 신규 등록하는 화면(상신·임시보관·결재라인).
///
/// [ActivityManagementView] 탭 2또는 `/activities/manage/register` 경로에 동일 위젯을 쓴다.
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
  int? _draftActIdx;
  Timer? _autoSaveTimer;

  final _specialNotesController = TextEditingController();
  final _activityNotesController = TextEditingController();
  final _suggestionsController = TextEditingController();
  final _svNotesController = TextEditingController();
  
  // 체크리스트 블록에 접근하기 위한 GlobalKey
  final _checklistKey = GlobalKey<_ChecklistBlockState>();

  /// 결재 절차선 — [결재라인 설정]에서 반영. `결재` 행(칸 수 [kActivityApprovalLineSlotCount]).
  List<String> _approvalLineStampSlots = const ['김민효', '', '', '', '', '', ''];

  /// [직급(직책)]. [_approvalLineStampSlots]과 같은 인덱스.
  List<String> _rankLineStampSlots = const ['사원', '', '', '', '', '', ''];

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _activityDate = _today;
    _draftActIdx = widget.actIdx;
    _initializeApprovalLine();
    if (widget.actIdx != null) {
      _loadActivity(widget.actIdx!);
    }
    _autoSaveTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _autoSaveDraft(),
    );
  }

  void _initializeApprovalLine() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user != null) {
      final userName = user['userNm']?.toString() ?? '';
      final positionNm = user['positionNm']?.toString() ?? '';
      
      _approvalLineStampSlots = [userName, '', '', '', '', '', ''];
      _rankLineStampSlots = [positionNm, '', '', '', '', '', ''];
    }
  }

  Future<void> _loadActivity(int actIdx) async {
    final activity = await ActivityApiService().getActivity(actIdx);
    if (!mounted || activity == null) return;

    Store? store;
    final rawStoreIdx = activity['storeIdx'];
    if (rawStoreIdx is int) {
      store = await StoreApiService().getStoreByIndex(rawStoreIdx);
    }
    if (!mounted) return;

    final rawNotes = activity['actNotes']?.toString() ?? '';
    final noteParts = rawNotes.split('\n\n');
    setState(() {
      _selectedStore = store;
      _activityKind = activity['actType']?.toString() ?? _activityKind;
      _activityDate = _parseDate(activity['actDt']) ?? _activityDate;
      _specialNotesController.text = noteParts.isNotEmpty
          ? noteParts.first
          : '';
      _activityNotesController.text = noteParts.length > 1
          ? noteParts.skip(1).join('\n\n')
          : '';
      _suggestionsController.text = activity['suggestions']?.toString() ?? '';
      _svNotesController.text = activity['svNotes']?.toString() ?? '';
    });

    // 체크리스트 결과 로드
    _loadChecklistResults(actIdx);
  }

  Future<void> _loadChecklistResults(int actIdx) async {
    try {
      final results = await ActivityApiService().getChecklistResults(actIdx);
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
    super.dispose();
  }

  Future<void> _pickActivityDate() async {
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

  Future<void> _openApprovalLineDialog() async {
    final r = await showActivityApprovalLineDialog(
      context,
      initialNames: _approvalLineStampSlots,
      initialTitles: _rankLineStampSlots,
    );
    if (!mounted || r == null) return;
    setState(() {
      _approvalLineStampSlots = r.names;
      _rankLineStampSlots = r.titles;
    });
  }

  Future<void> _openStoreLookup() async {
    final selected = await showDialog<Store>(
      context: context,
      builder: (dialogContext) => const _StoreLookupDialog(),
    );
    if (!mounted || selected == null) return;
    final detail =
        await StoreApiService().getStoreByIndex(selected.storeIdx) ?? selected;
    if (!mounted) return;
    setState(() => _selectedStore = detail);
  }

  Map<String, dynamic>? _buildPayload(String apprStatus) {
    final store = _selectedStore;
    if (store == null) return null;
    
    // 체크리스트 결과 수집
    final checklistResults = _getChecklistResults();
    
    return {
      'storeIdx': store.storeIdx,
      'actType': _activityKind,
      'actDt': _formatYmd(_activityDate),
      'actNotes': [
        _specialNotesController.text.trim(),
        _activityNotesController.text.trim(),
      ].where((text) => text.isNotEmpty).join('\n\n'),
      'svId': store.svId.trim().isEmpty ? null : store.svId.trim(),
      'apprStatus': apprStatus,
      'suggestions': _suggestionsController.text.trim(),
      'svNotes': _svNotesController.text.trim(),
      if (checklistResults != null && checklistResults.isNotEmpty)
        'checklistResults': checklistResults,
    };
  }

  /// 체크리스트 결과를 JSON 형식으로 반환
  List<Map<String, dynamic>>? _getChecklistResults() {
    final checklistState = _checklistKey.currentState;
    if (checklistState == null) return null;
    
    final items = checklistState._items;
    final results = checklistState._result;
    
    if (items.isEmpty || results.isEmpty) return null;
    
    final List<Map<String, dynamic>> checklistResults = [];
    for (var i = 0; i < items.length; i++) {
      final answerVal = results[i];
      // "미평가"는 제외하고 실제 평가된 항목만 저장
      if (answerVal != '미평가') {
        checklistResults.add({
          'chkIdx': items[i].chkIdx,
          'answerVal': answerVal,
          'answerScore': answerVal == 'Y' ? items[i].baseScore : 0,
        });
      }
    }
    
    return checklistResults.isEmpty ? null : checklistResults;
  }

  /// 체크리스트에 미평가 항목이 있는지 확인
  bool _hasUnevaluatedChecklist() {
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

  Future<void> _autoSaveDraft() async {
    if (_submitted || _autoSaving || _saving || _selectedStore == null) return;
    _autoSaving = true;
    final saved = await _persistActivity('DRAFT');
    _autoSaving = false;
    if (saved != null) {
      final rawActIdx = saved['actIdx'];
      if (rawActIdx is int) {
        _draftActIdx = rawActIdx;
      }
    }
  }

  Future<void> _saveActivity(String apprStatus) async {
    if (_selectedStore == null) {
      _snack('가맹점을 먼저 선택해 주세요.');
      return;
    }
    
    // 상신 시 체크리스트 검증
    if (apprStatus == 'PENDING' && _hasUnevaluatedChecklist()) {
      _snack('아직 체크되지 않은 체크리스트 항목이 있습니다.');
      return;
    }
    
    if (_saving) return;
    setState(() => _saving = true);
    final saved = await _persistActivity(apprStatus);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      _snack('저장에 실패했습니다.');
      return;
    }
    final rawActIdx = saved['actIdx'];
    if (rawActIdx is int) {
      _draftActIdx = rawActIdx;
    }
    if (apprStatus == 'PENDING') {
      _submitted = true;
      _autoSaveTimer?.cancel();
    }
    _snack(apprStatus == 'PENDING' ? '상신되었습니다.' : '임시보관되었습니다.');
  }

  Future<Map<String, dynamic>?> _persistActivity(String apprStatus) {
    final payload = _buildPayload(apprStatus);
    if (payload == null) return Future.value(null);
    final api = ActivityApiService();
    final actIdx = _draftActIdx;
    if (actIdx == null) {
      return api.createActivity(payload);
    }
    return api.updateActivity(actIdx, payload);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 550),
                          child: _ApprovalTable(
                            approvalStampSlots: _approvalLineStampSlots
                                .take(kActivityApprovalLineSlotCount)
                                .toList(),
                            rankStampSlots: _rankLineStampSlots
                                .take(kActivityApprovalLineSlotCount)
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '• 모바일 앱에서 가맹점출입관리 실행 후 태깅을 진행해주세요.\n'
                  '내용 입력 후 상신하기 버튼을 클릭하여 태그 이력을 선택해 주세요.\n'
                  '• 태그 이력은 다음날 12시전에 활동관리를 상신해야 실적으로 인정됩니다.',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                _PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      /// 셸/탭에 제목이 있으면 본문에서 제목 중복 생략. 안내는 검색·입력 제목 **옆**에 배치.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _SectionTitle('검색·입력'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '(* 가맹점을 먼저 선택해 주세요.)',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.notoSansKr(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentRed,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _openApprovalLineDialog,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.accentRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('결재라인'),
                          ),
                        ],
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
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _activityKind = v);
                            },
                          ),
                        ),
                        right: _LabeledField(
                          label: '활동일자',
                          requiredMark: true,
                          child: _ActivityFormDateField(
                            labelText: _formatYmd(_activityDate),
                            onPick: _pickActivityDate,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      _TwoColRow(
                        left: _LabeledField(
                          label: '등록일자',
                          child: _activityFormFieldShell(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatYmd(_today),
                                style: kActivityFormValueStyle,
                              ),
                            ),
                          ),
                        ),
                        right: const _FormColSpacer(),
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
                      readOnly: false,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ChecklistBlock(key: _checklistKey, store: _selectedStore),
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
                          maxLines: 5,
                          controller: _activityNotesController,
                          readOnly: false,
                        ),
                      ),
                      SizedBox(height: 16),
                      _LabeledField(
                        label: '건의사항',
                        child: _outlineInput(
                          hint: '',
                          maxLines: 5,
                          controller: _suggestionsController,
                          readOnly: false,
                        ),
                      ),
                      SizedBox(height: 16),
                      _LabeledField(
                        label: '담당 수퍼바이저 의견',
                        child: _outlineInput(
                          hint: '',
                          maxLines: 5,
                          controller: _svNotesController,
                          readOnly: false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton(
                      onPressed: () => _snack('첨부 기능은 추후 연결됩니다.'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.statusNew,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('첨부'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '* 전체 200MB까지 첨부 가능',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          color: AppTheme.statusNew,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: FormStylePalette.labelWidth,
                      child: Text(
                        '전자 서명',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FormStylePalette.textPrimary,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FormStylePalette.panelBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '(서명)',
                        style: TextStyle(
                          color: FormStylePalette.textMuted,
                          fontSize: 14,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '* 전자서명을 저장하면 입력된 내용 수정 불가하며 자동 상신됩니다.\n'
                        '저장 전에 활동관리 작성을 완료하세요.',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          color: AppTheme.accentRed,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _saving
                          ? null
                          : () => _saveActivity('PENDING'),
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
                      onPressed: _saving ? null : () => _saveActivity('DRAFT'),
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
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreLookupDialog extends StatefulWidget {
  const _StoreLookupDialog();

  @override
  State<_StoreLookupDialog> createState() => _StoreLookupDialogState();
}

class _StoreLookupDialogState extends State<_StoreLookupDialog> {
  final _keywordController = TextEditingController();
  late Future<List<Store>> _storesFuture;
  Store? _selected;

  @override
  void initState() {
    super.initState();
    _storesFuture = StoreApiService().getAllStores();
    _keywordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  List<Store> _filter(List<Store> rows) {
    final q = _keywordController.text.trim();
    if (q.isEmpty) return rows;
    return rows
        .where(
          (s) =>
              s.storeNm.contains(q) ||
              s.storeCd.contains(q) ||
              s.brandNm.contains(q) ||
              s.ownerNm.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: ErpDialogFrame(
        title: '가맹점 검색',
        maxWidth: 980,
        maxHeight: 680,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _keywordController,
              style: kActivityFormValueStyle,
              decoration: _inputDeco('가맹점명, 코드, 브랜드, 사업자명 검색'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Store>>(
                future: _storesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rows = _filter(snapshot.data ?? const <Store>[]);
                  if (rows.isEmpty) {
                    return const Center(child: Text('검색 결과가 없습니다.'));
                  }
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: FormStylePalette.panelBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const ColoredBox(
                          color: AppTheme.accentRed,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _StoreLookupHeaderCell('가맹점명'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _StoreLookupHeaderCell('브랜드'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _StoreLookupHeaderCell('가맹점코드'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _StoreLookupHeaderCell('사업자명'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: rows.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final store = rows[index];
                              final selected =
                                  _selected?.storeIdx == store.storeIdx;
                              return Material(
                                color: selected
                                    ? AppTheme.accentRed.withValues(alpha: 0.08)
                                    : Colors.white,
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selected = store),
                                  onDoubleTap: () =>
                                      Navigator.of(context).pop(store),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            store.storeNm,
                                            style: kActivityFormValueStyle
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            store.brandNm,
                                            style: kActivityFormValueStyle,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            store.storeCd,
                                            style: kActivityFormValueStyle,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            store.ownerNm,
                                            style: kActivityFormValueStyle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('선택'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreLookupHeaderCell extends StatelessWidget {
  const _StoreLookupHeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: AppTheme.koreanFontFallback,
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
                onPressed: () {
                  showActivityVisitHistoryDialog(context);
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
                onPressed: () {
                  showActivityInstructionsDialog(context);
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
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              color: FormStylePalette.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          _TwoColRow(
            left: _LabeledField(
              label: '가맹점 사업자 성명',
              valignWithField: true,
              labelWidth: _kStoreLabelWidth,
              labelMaxLines: 2,
              child: _storeReadonlyValue(store?.ownerNm),
            ),
            right: _LabeledField(
              label: '가맹계약 담당자',
              valignWithField: true,
              labelWidth: _kStoreLabelWidth,
              labelMaxLines: 2,
              child: _storeReadonlyValue(store?.contManager),
            ),
          ),
          const SizedBox(height: 8),
          _TwoColRow(
            left: _LabeledField(
              label: '최초 가맹계약 체결일자',
              valignWithField: true,
              labelWidth: _kStoreLabelWidth,
              labelMaxLines: 2,
              child: _storeReadonlyValue(store?.firstContDt),
            ),
            right: _LabeledField(
              label: '현재 가맹계약 기간',
              valignWithField: true,
              labelWidth: _kStoreLabelWidth,
              labelMaxLines: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _storeReadonlyValue(store?.contStartDt),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('—', style: kActivityFormValueStyle),
                  ),
                  _storeReadonlyValue(store?.contEndDt),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: '임대차보증금',
                  valignWithField: true,
                  labelWidth: _kStoreLabelWidthTight,
                  labelMaxLines: 2,
                  child: _storeReadonlyWithUnit(
                    _moneyText(store?.rentDeposit),
                    '원',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _LabeledField(
                  label: '권리금',
                  valignWithField: true,
                  labelWidth: _kStoreLabelWidthTight,
                  labelMaxLines: 2,
                  child: _storeReadonlyWithUnit(
                    _moneyText(store?.premiumFee),
                    '원',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _LabeledField(
                  label: '임차료(정액)',
                  valignWithField: true,
                  labelWidth: _kStoreLabelWidthTight,
                  labelMaxLines: 2,
                  child: _storeReadonlyWithUnit(
                    _moneyText(store?.monthlyRent),
                    '원',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _LabeledField(
                  label: '층수',
                  valignWithField: true,
                  labelWidth: _kStoreLabelWidthTight,
                  labelMaxLines: 2,
                  child: _storeReadonlyWithUnit(_intText(store?.floor), '층'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: _LabeledField(
                  label: '면적(계약㎡)',
                  valignWithField: true,
                  labelWidth: _kStoreLabelWidthTight,
                  labelMaxLines: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: _storeReadonlyWithUnit(
                          _decimalText(store?.contArea),
                          'm²',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _storeReadonlyWithUnit(
                          _pyeongText(store?.contArea),
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
                  labelWidth: _kStoreLabelWidthTight,
                  labelMaxLines: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: _storeReadonlyWithUnit(
                          _decimalText(store?.realArea),
                          'm²',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _storeReadonlyWithUnit(
                          _pyeongText(store?.realArea),
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

class _TwoColRow extends StatelessWidget {
  const _TwoColRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
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
  });

  final String label;
  final Widget child;
  final bool requiredMark;
  final bool valignWithField;
  final double labelWidth;
  final int labelMaxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: valignWithField
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Padding(
            padding: EdgeInsets.only(top: valignWithField ? 0 : 8),
            child: Text.rich(
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
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(child: child),
      ],
    );
  }
}

class _SearchLikeField extends StatelessWidget {
  const _SearchLikeField({required this.hint, this.value, required this.onTap});

  final String hint;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = value?.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: _activityFormFieldShell(
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

/// 결재정보 — 브랜드 레드 라벨 열 + 밝은 본문 (테마 [FormStylePalette] / [AppTheme]).
class _ApprovalTable extends StatelessWidget {
  const _ApprovalTable({
    required this.approvalStampSlots,
    required this.rankStampSlots,
  });

  final List<String> approvalStampSlots;
  final List<String> rankStampSlots;

  static const double _labelW = 95;
  static const double _rowSingleH = 40;

  /// 기안부서 한 줄(문서·스크린샷에서 세로로 더 촘촘하게 보이도록).
  static const double _rowDeptH = 30;
  static const double _rowStampH = 40;
  static int get _slotCount => kActivityApprovalLineSlotCount;
  static const double _textSize = 13.0;

  List<String> get _paddedApproval {
    final a = <String>[];
    for (var i = 0; i < _slotCount; i++) {
      a.add(i < approvalStampSlots.length ? approvalStampSlots[i] : '');
    }
    return a;
  }

  List<String> get _paddedRank {
    final a = <String>[];
    for (var i = 0; i < _slotCount; i++) {
      a.add(i < rankStampSlots.length ? rankStampSlots[i] : '');
    }
    return a;
  }

  @override
  Widget build(BuildContext context) {
    const edge = FormStylePalette.approvalTableBorder;
    return ClipRRect(
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
            _singleRow('작성일자', '2026-04-22', showTop: true, edge: edge),
            _singleRow(
              '기안부서',
              'IT팀',
              showTop: false,
              edge: edge,
              height: _rowDeptH,
              valueCompact: true,
            ),
            _singleRow('기안자', '김민효', showTop: false, edge: edge),
            _gridRow('직급(직책)', _paddedRank, edge: edge),
            _gridRow('결재', _paddedApproval, edge: edge),
          ],
        ),
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

  static Widget _gridRow(
    String label,
    List<String> slots, {
    required Color edge,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: edge, width: 1)),
      ),
      height: _rowStampH,
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
                    child: _stampSlot(
                      i < slots.length ? slots[i] : '',
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

  static Widget _stampSlot(String t, Color edge, {required bool isLast}) {
    return ColoredBox(
      color: FormStylePalette.approvalTableDataBg,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        decoration: BoxDecoration(
          border: Border(
            right: isLast ? BorderSide.none : BorderSide(color: edge, width: 1),
          ),
        ),
        child: t.isEmpty
            ? const SizedBox.shrink()
            : Text(
                t,
                textAlign: TextAlign.center,
                maxLines: 2,
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
}

class _ChecklistBlock extends StatefulWidget {
  const _ChecklistBlock({super.key, required this.store});

  final Store? store;

  @override
  State<_ChecklistBlock> createState() => _ChecklistBlockState();
}

class _ChecklistBlockState extends State<_ChecklistBlock> {
  List<ChecklistItem> _items = [];
  late final List<String> _result = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  @override
  void didUpdateWidget(covariant _ChecklistBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.store?.brandCd != oldWidget.store?.brandCd) {
      _loadChecklists();
    }
  }

  Future<void> _loadChecklists() async {
    if (widget.store == null || widget.store!.brandCd.isEmpty) {
      setState(() {
        _items = [];
        _result.clear();
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final items = await ChecklistApiService().getChecklistsByBrand(
        widget.store!.brandCd,
      );
      if (!mounted) return;

      setState(() {
        _items = items;
        _result.clear();
        _result.addAll(List.filled(items.length, '미평가'));
        _loading = false;
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

  /// 체크리스트 결과 설정 (임시보관 상세 로드 시 사용)
  void setChecklistResults(List<Map<String, dynamic>> results) {
    if (_items.isEmpty) return;

    // chkIdx를 키로 하는 결과 맵 생성
    final resultMap = <int, String>{};
    for (final result in results) {
      final chkIdx = result['chkIdx'] as int?;
      final answerVal = result['answerVal']?.toString() ?? '미평가';
      if (chkIdx != null) {
        resultMap[chkIdx] = answerVal;
      }
    }

    // _items의 순서대로 결과 매핑
    setState(() {
      _result.clear();
      for (final item in _items) {
        _result.add(resultMap[item.chkIdx] ?? '미평가');
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
            Center(child: CircularProgressIndicator()),
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
                    color: FormStylePalette.textMuted,
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
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: FormStylePalette.panelBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(44),
                1: FixedColumnWidth(80),
                2: FlexColumnWidth(1.0),
                3: FixedColumnWidth(140),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: kErpTableInnerGridBorder,
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    color: FormStylePalette.tableHeaderBg,
                  ),
                  children: [
                    _ChHdr('번호'),
                    _ChHdr('구분'),
                    _ChHdr('체크항목'),
                    _ChHdr('체크결과'),
                  ],
                ),
                for (var i = 0; i < _items.length; i++)
                  TableRow(
                    children: [
                      _ChCell('${i + 1}'),
                      _ChCell(_items[i].chkTypeNm, left: true),
                      _ChCell(_items[i].chkContent, left: true),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _result[i] = _result[i] == 'Y' ? '미평가' : 'Y';
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Checkbox(
                                      value: _result[i] == 'Y',
                                      onChanged: (v) {
                                        setState(() {
                                          _result[i] = _result[i] == 'Y' ? '미평가' : 'Y';
                                        });
                                      },
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '적합',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: FormStylePalette.textPrimary,
                                      fontFamilyFallback: AppTheme.koreanFontFallback,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _result[i] = _result[i] == 'N' ? '미평가' : 'N';
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Checkbox(
                                      value: _result[i] == 'N',
                                      onChanged: (v) {
                                        setState(() {
                                          _result[i] = _result[i] == 'N' ? '미평가' : 'N';
                                        });
                                      },
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '미적합',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: FormStylePalette.textPrimary,
                                      fontFamilyFallback: AppTheme.koreanFontFallback,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
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
  const _ChCell(this.t, {this.left = false});

  final String t;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        t,
        textAlign: left ? TextAlign.start : TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: FormStylePalette.textPrimary,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
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
