// 메일 설정 — 자동분류 / 자동전달.
//
// 설정 화면(`mal001_settings_view.dart`)이 환경설정·서명·메일함 3개만 있을 때는
// 한 파일로 충분했는데, 여기 두 영역은 각각 규칙 목록 + 편집 팝업 + 확인 절차가
// 붙어 덩치가 크다. 그래서 카드 두 개만 이 파일로 뺐다. 카드 껍데기·스위치 줄 등
// 생김새는 `mal001_widgets.dart` 의 공용 위젯을 그대로 쓴다.
//
// 두 기능 모두 백엔드가 아직 배포 전일 수 있다. 그때 화면이 빨간 오류로 도배되면
// "서버가 죽었다"로 오해하므로 `MailFeatureUnavailable`(404/501/405)이면 "준비 중"
// 안내로 물러난다. 그 밖의 실패(403 권한·500 오류·타임아웃)는 사유를 그대로 보여 준다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_provider.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_widgets.dart';

// ═════════════════════════ 자동분류 ═════════════════════════

/// 조건에 맞는 메일을 받은 즉시 옮기거나 읽음처리하는 규칙 관리.
class MailAutoRuleCard extends ConsumerWidget {
  const MailAutoRuleCard({
    super.key,
    required this.canUpdate,
    required this.run,
    required this.toast,
    required this.busy,
  });

  final bool canUpdate;
  final MailSettingsRunAction run;
  final void Function(String message) toast;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mailRulesProvider);
    // 이동 대상 목록. 실패·미도착이면 빈 목록으로 두고, 팝업 안에서 그 사실을
    // 문장으로 알린다(같은 화면 아래쪽 「사용자 메일함 관리」 카드가 오류를 따로 보여 준다).
    final folders =
        ref.watch(mailUserFoldersProvider).valueOrNull ??
        const <MailUserFolder>[];

    Future<void> edit(MailRule? existing) async {
      final result = await showDialog<MailRule>(
        context: context,
        builder: (ctx) => _RuleDialog(initial: existing, folders: folders),
      );
      if (result == null) return;
      await run(() async {
        await ref.read(mailApiProvider).saveRule(result);
        ref.invalidate(mailRulesProvider);
        toast('자동분류 규칙을 저장했습니다.');
      }, failFallback: '자동분류 규칙 저장에 실패했습니다.');
    }

    Future<void> remove(MailRule rule) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('자동분류 규칙 삭제'),
          content: Text('「${rule.ruleNmLabel}」 규칙을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await run(() async {
        await ref.read(mailApiProvider).deleteRule(rule.ruleIdx);
        ref.invalidate(mailRulesProvider);
        toast('자동분류 규칙을 삭제했습니다.');
      }, failFallback: '자동분류 규칙 삭제에 실패했습니다.');
    }

    /// 위/아래 한 칸 이동. 순서가 곧 우선순위라 **전체 순서를 한 번에** 보낸다.
    Future<void> move(List<MailRule> rows, int index, int delta) async {
      final target = index + delta;
      if (target < 0 || target >= rows.length) return;
      final next = List<MailRule>.of(rows);
      final moved = next.removeAt(index);
      next.insert(target, moved);
      await run(() async {
        await ref
            .read(mailApiProvider)
            .reorderRules([for (final r in next) r.ruleIdx]);
        ref.invalidate(mailRulesProvider);
      }, failFallback: '규칙 순서 변경에 실패했습니다.');
    }

    Future<void> toggleEnabled(MailRule rule, bool enabled) async {
      await run(() async {
        await ref
            .read(mailApiProvider)
            .saveRule(rule.copyWith(enabled: enabled));
        ref.invalidate(mailRulesProvider);
      }, failFallback: '규칙 사용 여부를 바꾸지 못했습니다.');
    }

    return MailSettingsCard(
      title: '자동분류',
      // 소급 적용이 안 된다는 사실을 **가장 먼저** 말한다. 규칙을 만들고 나서
      // "예전 메일은 왜 안 옮겨졌냐"는 문의가 반드시 나오는 지점이다.
      description:
          '조건에 맞는 메일을 받는 즉시 지정한 메일함으로 옮기거나 읽음으로 표시합니다.\n'
          '설정 이후 받는 메일부터 적용됩니다. 이미 받은 메일에는 소급 적용되지 않습니다.\n'
          '위에 있는 규칙이 먼저 적용되고, 한 메일에는 먼저 걸린 규칙 하나만 적용됩니다.',
      trailing: canUpdate && !async.hasError
          ? TextButton.icon(
              onPressed: busy ? null : () => edit(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('규칙 추가'),
            )
          : null,
      child: async.when(
        loading: () => const MailLoading(height: 80),
        error: (e, _) => MailFailureBanner(
          error: e,
          feature: '메일 자동분류',
          fallback: '자동분류 규칙을 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(mailRulesProvider),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const MailSettingsEmptyLine('등록된 자동분류 규칙이 없습니다.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++)
                _RuleRow(
                  rule: rows[i],
                  order: i + 1,
                  canUpdate: canUpdate,
                  busy: busy,
                  // 맨 위/맨 아래에서는 버튼을 아예 못 누르게 한다.
                  // 눌러도 아무 일이 없으면 고장난 줄 안다.
                  onUp: i == 0 ? null : () => move(rows, i, -1),
                  onDown: i == rows.length - 1 ? null : () => move(rows, i, 1),
                  onEdit: () => edit(rows[i]),
                  onDelete: () => remove(rows[i]),
                  onToggleEnabled: (v) => toggleEnabled(rows[i], v),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.rule,
    required this.order,
    required this.canUpdate,
    required this.busy,
    required this.onUp,
    required this.onDown,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  final MailRule rule;
  final int order;
  final bool canUpdate;
  final bool busy;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppTheme.appSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 우선순위 번호 — "위에 있는 것이 먼저"라는 규칙을 눈으로 보여 준다.
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Text(
              '$order',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          if (canUpdate)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniIconButton(
                  icon: Icons.keyboard_arrow_up,
                  tooltip: '위로',
                  onPressed: busy ? null : onUp,
                ),
                _MiniIconButton(
                  icon: Icons.keyboard_arrow_down,
                  tooltip: '아래로',
                  onPressed: busy ? null : onDown,
                ),
              ],
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        rule.ruleNmLabel,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: rule.enabled
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
                    if (!rule.enabled)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text(
                          '사용 안 함',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                            fontFamilyFallback: AppTheme.koreanFontFallback,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${rule.conditionLabel} → ${rule.actionLabel}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppTheme.textSecondary,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ],
            ),
          ),
          if (canUpdate) ...[
            Switch(
              value: rule.enabled,
              onChanged: busy ? null : onToggleEnabled,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            IconButton(
              tooltip: '수정',
              visualDensity: VisualDensity.compact,
              onPressed: busy ? null : onEdit,
              icon: const Icon(Icons.edit_outlined, size: 17),
            ),
            IconButton(
              tooltip: '삭제',
              visualDensity: VisualDensity.compact,
              onPressed: busy ? null : onDelete,
              icon: const Icon(
                Icons.delete_outline,
                size: 17,
                color: AppTheme.accentRed,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 20),
      icon: Icon(icon, size: 18),
      color: AppTheme.textSecondary,
      disabledColor: AppTheme.textPlaceholder,
    );
  }
}

/// 규칙 추가·수정 팝업.
///
/// 조건은 **AND 로만** 묶인다(다우오피스와 같다). OR 을 넣으면 규칙 하나가 언제
/// 걸리는지 사용자가 예측할 수 없어지고, 그때부터는 "왜 안 옮겨졌냐"를 아무도
/// 설명하지 못한다. OR 이 필요하면 규칙을 두 개 만들면 된다.
class _RuleDialog extends StatefulWidget {
  const _RuleDialog({this.initial, required this.folders});

  final MailRule? initial;
  final List<MailUserFolder> folders;

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _fromCtrl;
  late final TextEditingController _toCtrl;
  late final TextEditingController _subjectCtrl;
  late String _action;
  late int? _folderIdx;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _nameCtrl = TextEditingController(text: r?.ruleNm ?? '');
    _fromCtrl = TextEditingController(text: r?.fromContains ?? '');
    _toCtrl = TextEditingController(text: r?.toContains ?? '');
    _subjectCtrl = TextEditingController(text: r?.subjectContains ?? '');
    _action = r?.actionType ?? MailRuleActions.move;
    _enabled = r?.enabled ?? true;
    // 지금 목록에 없는 메일함이 지정돼 있으면(삭제된 메일함) 드롭다운이 터진다.
    // 목록에 있는 값일 때만 초기값으로 쓴다.
    final idx = r?.targetFolderIdx;
    _folderIdx = widget.folders.any((f) => f.folderIdx == idx) ? idx : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  void _warn(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 고른 메일함 이름 — 목록 화면이 규칙 한 줄을 사람 말로 보여 줄 때 쓴다.
  /// 서버가 이름을 다시 내려주더라도 저장 직후 화면이 "이동"만 보이는 것을 막는다.
  String _selectedFolderNm() {
    for (final f in widget.folders) {
      if (f.folderIdx == _folderIdx) return f.folderNm;
    }
    return '';
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _warn('규칙 이름을 입력해 주세요.');
      return;
    }
    final rule = MailRule(
      ruleIdx: widget.initial?.ruleIdx ?? 0,
      ruleNm: name,
      enabled: _enabled,
      sortOrder: widget.initial?.sortOrder ?? 0,
      fromContains: _fromCtrl.text,
      toContains: _toCtrl.text,
      subjectContains: _subjectCtrl.text,
      actionType: _action,
      targetFolderIdx: _action == MailRuleActions.move ? _folderIdx : null,
      targetFolderNm: _action == MailRuleActions.move
          ? _selectedFolderNm()
          : '',
    );
    // 조건이 하나도 없으면 **모든 메일**에 걸린다. 저장 전에 막는다 —
    // 받은메일함이 통째로 비는 사고가 여기서 난다.
    if (!rule.hasCondition) {
      _warn('조건을 하나 이상 입력해 주세요. 조건이 없으면 모든 메일에 적용됩니다.');
      return;
    }
    if (rule.isMove && rule.targetFolderIdx == null) {
      _warn('옮길 메일함을 선택해 주세요.');
      return;
    }
    Navigator.pop(context, rule);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '자동분류 규칙 추가' : '자동분류 규칙 수정'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '규칙 이름',
                  hintText: '예) 거래처 메일 모으기',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              const _DialogSectionLabel('조건'),
              const Text(
                // AND 뿐이라는 사실을 여기서 못 박는다. 조건 칸이 세 개라
                // 말하지 않으면 "셋 중 하나만 맞아도" 로 읽는다.
                '입력한 조건을 모두 만족하는 메일에만 적용됩니다(AND). '
                '비워 둔 칸은 조건으로 보지 않습니다.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppTheme.textMuted,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _fromCtrl,
                decoration: const InputDecoration(
                  labelText: '보낸사람에 포함',
                  hintText: '예) @partner.co.kr',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _toCtrl,
                decoration: const InputDecoration(
                  labelText: '수신자에 포함',
                  hintText: '예) sales@',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: '제목에 포함',
                  hintText: '예) [세금계산서]',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const _DialogSectionLabel('처리'),
              const SizedBox(height: 4),
              // 처리는 규칙당 하나만 고른다. `RadioListTile` 의 groupValue/onChanged
              // 는 Flutter 3.32 에서 폐기돼 `RadioGroup` 으로 감싸는 방식이 됐다.
              RadioGroup<String>(
                groupValue: _action,
                onChanged: (v) =>
                    setState(() => _action = v ?? MailRuleActions.move),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final action in MailRuleActions.all)
                      RadioListTile<String>(
                        value: action,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(MailRuleActions.labelOf(action)),
                      ),
                  ],
                ),
              ),
              if (_action == MailRuleActions.move) ...[
                const SizedBox(height: 4),
                if (widget.folders.isEmpty)
                  const Text(
                    '만들어 둔 메일함이 없습니다. 아래 「사용자 메일함 관리」에서 먼저 추가해 주세요.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: AppTheme.accentRed,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: _folderIdx,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: '옮길 메일함',
                      isDense: true,
                    ),
                    items: [
                      for (final f in widget.folders)
                        DropdownMenuItem<int>(
                          value: f.folderIdx,
                          child: Text(f.folderNmLabel),
                        ),
                    ],
                    onChanged: (v) => setState(() => _folderIdx = v),
                  ),
              ],
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _enabled,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('이 규칙 사용'),
                onChanged: (v) => setState(() => _enabled = v ?? true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }
}

class _DialogSectionLabel extends StatelessWidget {
  const _DialogSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.chromeBlack,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

// ═════════════════════════ 자동전달 ═════════════════════════

/// 받은 메일을 다른 주소로 자동 전달.
///
/// **이 화면에서 가장 위험한 설정이다.** 주소 한 글자를 틀리면 회사로 오는 메일이
/// 통째로 외부로 나가고, 나간 메일은 되돌릴 수 없다. 그래서
///  1) 저장 전에 무엇이 어디로 나가는지 적은 확인 팝업을 반드시 거치고,
///  2) 주소 형식을 최소한이라도 검사하며,
///  3) 켜져 있을 때는 화면 위쪽에 경고 상자를 계속 띄운다.
class MailForwardCard extends ConsumerStatefulWidget {
  const MailForwardCard({
    super.key,
    required this.canUpdate,
    required this.run,
    required this.toast,
    required this.busy,
  });

  final bool canUpdate;
  final MailSettingsRunAction run;
  final void Function(String message) toast;
  final bool busy;

  @override
  ConsumerState<MailForwardCard> createState() => _MailForwardCardState();
}

class _MailForwardCardState extends ConsumerState<MailForwardCard> {
  final _addrCtrl = TextEditingController();

  /// 서버 값을 화면 상태로 한 번 옮겼는지. 안 그러면 매 build 마다 사용자가
  /// 고치던 값이 서버 값으로 되돌아간다.
  bool _adopted = false;
  bool? _enabled;
  bool? _keepOriginal;

  @override
  void dispose() {
    _addrCtrl.dispose();
    super.dispose();
  }

  /// 서버 값 → 화면 상태. build 중에 부르면 안 되므로 항상 콜백에서 부른다
  /// (`TextEditingController.text` 대입이 build 중이면 setState 충돌이 난다).
  void _adopt(MailForwardSetting s) {
    if (!mounted) return;
    if (_addrCtrl.text != s.forwardTo) _addrCtrl.text = s.forwardTo;
    setState(() {
      _adopted = true;
      _enabled = s.enabled;
      _keepOriginal = s.keepOriginal;
    });
  }

  Future<bool> _confirmSave({
    required bool enabled,
    required String addr,
    required bool keepOriginal,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(enabled ? '자동전달을 켭니다' : '자동전달을 끕니다'),
        content: Text(
          enabled
              // 무엇이 어디로 나가는지 문장으로 다시 읽게 한다.
              // "저장하시겠습니까?" 만 물으면 아무도 안 읽는다.
              ? '지금부터 받는 모든 메일이 아래 주소로 전달됩니다.\n\n'
                    '전달 주소 : $addr\n'
                    '원본 메일 : ${keepOriginal ? '내 메일함에 남김' : '전달 후 삭제'}\n\n'
                    '한 번 전달된 메일은 되돌릴 수 없습니다. 주소가 맞는지 확인해 주세요.'
              : '자동전달을 끕니다. 앞으로 받는 메일은 전달되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: enabled ? AppTheme.accentRed : null,
              foregroundColor: enabled ? Colors.white : null,
            ),
            child: Text(enabled ? '전달 켜기' : '끄기'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _save(MailForwardSetting current) async {
    final addr = _addrCtrl.text.trim();
    final enabled = _enabled ?? current.enabled;
    final keepOriginal = _keepOriginal ?? current.keepOriginal;

    if (enabled && !isLikelyEmail(addr)) {
      widget.toast('전달 주소를 정확히 입력해 주세요. (예: name@example.com)');
      return;
    }
    if (!await _confirmSave(
      enabled: enabled,
      addr: addr,
      keepOriginal: keepOriginal,
    )) {
      return;
    }
    await widget.run(() async {
      await ref
          .read(mailApiProvider)
          .saveForward(
            MailForwardSetting(
              enabled: enabled,
              forwardTo: addr,
              keepOriginal: keepOriginal,
            ),
          );
      ref.invalidate(mailForwardProvider);
      widget.toast(enabled ? '자동전달을 켰습니다.' : '자동전달을 껐습니다.');
    }, failFallback: '자동전달 설정 저장에 실패했습니다.');
  }

  @override
  Widget build(BuildContext context) {
    // 값이 바뀌면(저장 후 갱신 등) 화면 상태를 다시 맞춘다.
    ref.listen<AsyncValue<MailForwardSetting>>(mailForwardProvider, (_, next) {
      final v = next.valueOrNull;
      if (v != null) _adopt(v);
    });

    final async = ref.watch(mailForwardProvider);

    // `ref.listen` 은 **이미 도착해 있던 첫 값**은 잡지 못한다. 그 경우만 여기서
    // 한 번 채운다(build 중 setState 를 피하려고 프레임 뒤로 미룬다).
    final first = async.valueOrNull;
    if (!_adopted && first != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_adopted) _adopt(first);
      });
    }

    return MailSettingsCard(
      title: '자동전달',
      description:
          '받은 메일을 다른 주소로 자동 전달합니다. 설정 이후 받는 메일부터 적용됩니다.',
      child: async.when(
        loading: () => const MailLoading(height: 80),
        error: (e, _) => MailFailureBanner(
          error: e,
          feature: '메일 자동전달',
          fallback: '자동전달 설정을 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(mailForwardProvider),
        ),
        data: (setting) {
          final enabled = _enabled ?? setting.enabled;
          final keepOriginal = _keepOriginal ?? setting.keepOriginal;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (enabled)
                const MailWarningBox(
                  message:
                      '자동전달이 켜지면 받는 메일이 사외로 나갈 수 있습니다. '
                      '전달 주소가 맞는지 반드시 확인해 주세요.',
                ),
              MailSettingSwitchRow(
                label: '전체 자동전달',
                description: '받는 모든 메일을 아래 주소로 전달합니다.',
                value: enabled,
                enabled: widget.canUpdate && !widget.busy,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _addrCtrl,
                enabled: widget.canUpdate,
                decoration: const InputDecoration(
                  labelText: '전달 주소',
                  hintText: 'name@example.com',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              const _DialogSectionLabel('원본 메일'),
              RadioGroup<bool>(
                groupValue: keepOriginal,
                onChanged: (v) => setState(() => _keepOriginal = v ?? true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RadioListTile<bool>(
                      value: true,
                      enabled: widget.canUpdate,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('내 메일함에 남김'),
                    ),
                    RadioListTile<bool>(
                      value: false,
                      enabled: widget.canUpdate,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('전달 후 삭제'),
                      subtitle: const Text(
                        // 삭제 쪽이 무슨 뜻인지 반드시 적는다. 골라 놓고 나중에
                        // "메일이 사라졌다"고 하는 상황을 막는다.
                        '전달한 메일은 내 메일함에 남지 않습니다.',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.canUpdate)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: FilledButton(
                      onPressed: widget.busy ? null : () => _save(setting),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('자동전달 저장'),
                    ),
                  ),
                ),
              const Divider(height: 28, color: AppTheme.hairline),
              _ForwardRuleSection(
                canUpdate: widget.canUpdate,
                run: widget.run,
                toast: widget.toast,
                busy: widget.busy,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 자동전달 예외 규칙 — 발신자 주소·도메인별로 다른 주소로 보낸다.
class _ForwardRuleSection extends ConsumerWidget {
  const _ForwardRuleSection({
    required this.canUpdate,
    required this.run,
    required this.toast,
    required this.busy,
  });

  final bool canUpdate;
  final MailSettingsRunAction run;
  final void Function(String message) toast;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mailForwardRulesProvider);

    Future<void> edit(MailForwardRule? existing) async {
      final result = await showDialog<MailForwardRule>(
        context: context,
        builder: (ctx) => _ForwardRuleDialog(initial: existing),
      );
      if (result == null) return;
      await run(() async {
        await ref.read(mailApiProvider).saveForwardRule(result);
        ref.invalidate(mailForwardRulesProvider);
        toast('예외 규칙을 저장했습니다.');
      }, failFallback: '예외 규칙 저장에 실패했습니다.');
    }

    Future<void> remove(MailForwardRule rule) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('예외 규칙 삭제'),
          content: Text('${rule.matchLabel} 규칙을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await run(() async {
        await ref.read(mailApiProvider).deleteForwardRule(rule.ruleIdx);
        ref.invalidate(mailForwardRulesProvider);
        toast('예외 규칙을 삭제했습니다.');
      }, failFallback: '예외 규칙 삭제에 실패했습니다.');
    }

    final rows = async.valueOrNull ?? const <MailForwardRule>[];
    final full = rows.length >= kMailForwardRuleMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '예외 규칙',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.chromeBlack,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
            if (canUpdate && !async.hasError)
              TextButton.icon(
                // 상한에 걸리면 **누르기 전에** 막는다. 저장 순간에 거절당하면
                // 입력한 내용이 통째로 날아간다.
                onPressed: busy || full ? null : () => edit(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('예외 추가'),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '특정 발신자에게서 온 메일만 다른 주소로 보냅니다. '
            '예외 규칙이 전체 자동전달보다 먼저 적용됩니다. '
            '(최대 $kMailForwardRuleMax개'
            '${full ? ' · 상한에 도달했습니다' : ''})',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppTheme.textMuted,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        async.when(
          loading: () => const MailLoading(height: 60),
          error: (e, _) => MailFailureBanner(
            error: e,
            feature: '메일 자동전달',
            fallback: '예외 규칙을 불러오지 못했습니다.',
            onRetry: () => ref.invalidate(mailForwardRulesProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const MailSettingsEmptyLine('등록된 예외 규칙이 없습니다.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final rule in list)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          rule.enabled
                              ? Icons.alt_route
                              : Icons.pause_circle_outline,
                          size: 17,
                          color: rule.enabled
                              ? AppTheme.textSecondary
                              : AppTheme.textPlaceholder,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${rule.matchLabel} → ${rule.forwardTo}'
                            '${rule.enabled ? '' : ' (사용 안 함)'}',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: rule.enabled
                                  ? AppTheme.textPrimary
                                  : AppTheme.textMuted,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ),
                        if (canUpdate) ...[
                          IconButton(
                            tooltip: '수정',
                            visualDensity: VisualDensity.compact,
                            onPressed: busy ? null : () => edit(rule),
                            icon: const Icon(Icons.edit_outlined, size: 17),
                          ),
                          IconButton(
                            tooltip: '삭제',
                            visualDensity: VisualDensity.compact,
                            onPressed: busy ? null : () => remove(rule),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 17,
                              color: AppTheme.accentRed,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ForwardRuleDialog extends StatefulWidget {
  const _ForwardRuleDialog({this.initial});

  final MailForwardRule? initial;

  @override
  State<_ForwardRuleDialog> createState() => _ForwardRuleDialogState();
}

class _ForwardRuleDialogState extends State<_ForwardRuleDialog> {
  late final TextEditingController _valueCtrl;
  late final TextEditingController _addrCtrl;
  late String _matchType;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _valueCtrl = TextEditingController(text: r?.matchValue ?? '');
    _addrCtrl = TextEditingController(text: r?.forwardTo ?? '');
    _matchType = r?.matchType ?? MailForwardMatchTypes.address;
    _enabled = r?.enabled ?? true;
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  void _warn(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final value = _valueCtrl.text.trim();
    final addr = _addrCtrl.text.trim();
    if (value.isEmpty) {
      _warn('조건 값을 입력해 주세요.');
      return;
    }
    if (!isLikelyEmail(addr)) {
      _warn('전달 주소를 정확히 입력해 주세요. (예: name@example.com)');
      return;
    }
    // 예외 규칙도 메일을 밖으로 내보낸다 — 전체 설정과 같은 확인 절차를 거친다.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('예외 전달 규칙을 저장합니다'),
        content: Text(
          '${MailForwardMatchTypes.labelOf(_matchType)}이(가) '
          '「$value」인 메일을\n$addr (으)로 전달합니다.\n\n'
          '한 번 전달된 메일은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    Navigator.pop(
      context,
      MailForwardRule(
        ruleIdx: widget.initial?.ruleIdx ?? 0,
        matchType: _matchType,
        matchValue: value,
        forwardTo: addr,
        enabled: _enabled,
        sortOrder: widget.initial?.sortOrder ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '예외 전달 규칙 추가' : '예외 전달 규칙 수정'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _matchType,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: '조건 기준',
                  isDense: true,
                ),
                items: [
                  for (final t in MailForwardMatchTypes.all)
                    DropdownMenuItem<String>(
                      value: t,
                      child: Text(MailForwardMatchTypes.labelOf(t)),
                    ),
                ],
                onChanged: (v) => setState(
                  () => _matchType = v ?? MailForwardMatchTypes.address,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _valueCtrl,
                decoration: InputDecoration(
                  labelText: MailForwardMatchTypes.labelOf(_matchType),
                  hintText: MailForwardMatchTypes.hintOf(_matchType),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addrCtrl,
                decoration: const InputDecoration(
                  labelText: '전달 주소',
                  hintText: 'name@example.com',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 6),
              CheckboxListTile(
                value: _enabled,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('이 규칙 사용'),
                onChanged: (v) => setState(() => _enabled = v ?? true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }
}
