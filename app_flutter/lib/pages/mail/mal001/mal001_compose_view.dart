// 메일 작성 — 받는사람 자동완성·서명·예약발송·수신확인·중요도, 첨부, 답장/전달.
//
// 다우오피스를 기준으로 맞췄다. 특히 두 가지가 실사용에서 크게 갈린다.
//  - **부서를 고르면 부서원 전체가 수신자로 들어간다**(72명 조직에서 가장 잦은 동작).
//  - **주소를 색으로 구분한다**: 사내=파랑, 외부=주황, 형식오류=빨강.
//    보내기 직전 확인 팝업만으로는 주소를 한 줄씩 읽지 않는다. 색이 먼저 잡아 준다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/file/store_document_file_picker.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_provider.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_recipient_field.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_widgets.dart';
import 'package:app_flutter/pages/mail/shared/mail_routes.dart';

class Mal001ComposeView extends ConsumerStatefulWidget {
  const Mal001ComposeView({
    super.key,
    this.replyToMailIdx,
    this.mode = MailRoutes.composeModeReply,
    this.initialTo,
  });

  /// 답장·전달일 때 원본 mail_idx. 서버가 이 값으로 스레드·In-Reply-To 를 잇는다.
  final int? replyToMailIdx;

  /// `reply` / `replyAll` / `forward`.
  final String mode;

  /// 받는사람을 미리 채운 채로 시작한다(상세 화면에서 이름을 더블클릭해 들어온
  /// 경우). [replyToMailIdx] 와는 무관 — 스레드를 잇지 않는 완전히 새 메일이다.
  final String? initialTo;

  @override
  ConsumerState<Mal001ComposeView> createState() => _Mal001ComposeViewState();
}

class _Mal001ComposeViewState extends ConsumerState<Mal001ComposeView> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  List<String> _to = <String>[];
  List<String> _cc = <String>[];
  List<String> _bcc = <String>[];

  bool _showCcBcc = false;
  bool _busy = false;
  bool _highImportance = false;
  bool _requestReadReceipt = false;

  /// 예약발송 시각. null 이면 즉시 발송.
  DateTime? _scheduledAt;

  /// 이미 삽입한 서명 — 두 번 눌러 두 번 붙는 것을 막고, 바꿔 끼울 때 지운다.
  MailSignature? _appliedSignature;

  /// 답장 원문을 이미 채워 넣었는지 — 사용자가 고쳐 쓴 내용을 덮어쓰지 않기 위해
  /// 딱 한 번만 채운다.
  bool _replyApplied = false;

  /// 기본 서명·기본 수신확인 설정을 한 번만 적용하기 위한 표시.
  bool _prefsApplied = false;

  /// 임시저장으로 만들어진 mail_idx. null 이면 아직 서버에 아무것도 없다.
  int? _draftMailIdx;

  final _attachments = <MailAttachment>[];

  bool get _isForward => widget.mode == MailRoutes.composeModeForward;
  bool get _isReplyAll => widget.mode == MailRoutes.composeModeReplyAll;
  bool get _locked => _draftMailIdx != null;

  @override
  void initState() {
    super.initState();
    final to = widget.initialTo?.trim();
    if (to != null && to.isNotEmpty) {
      _to = [to];
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String failFallback,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      // 실패 사유를 그대로 보여 준다 — "저장했습니다" 같은 거짓 성공 문구를 내지 않는다.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mailIsFeatureUnavailable(e)
                ? e.toString()
                : formatApiUserMessage(e, fallback: failFallback),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ───────────────────────── 원본 반영 ─────────────────────────

  /// 답장·전체답장·전달의 초기값을 원본에서 채운다.
  void _applyReplySource(MailDetail source) {
    _replyApplied = true;
    final item = source.summary;
    final subject = item.subject.trim();

    if (_isForward) {
      // 전달은 수신자를 비워 둔다 — 원본 발신자에게 다시 보내는 사고를 막는다.
      _to = const [];
      final hasFwd = subject.toLowerCase().startsWith('fwd:');
      _subjectCtrl.text = hasFwd
          ? subject
          : 'Fwd: ${subject.isEmpty ? '(제목 없음)' : subject}';
    } else {
      _to = List<String>.of(source.replyRecipients);
      if (_isReplyAll) {
        // 전체답장: 원본의 받는사람·참조를 모두 참조로 끌어온다.
        // 단 **나 자신은 뺀다** — 안 그러면 답장할 때마다 내 메일함에 사본이 쌓인다.
        final me = provider.Provider.of<AuthProvider>(
          context,
          listen: false,
        ).userId.trim().toLowerCase();
        final extra = <String>[
          ...source.addressesOf('TO').map((a) => a.email),
          ...source.addressesOf('CC').map((a) => a.email),
        ].where((e) => e.trim().isNotEmpty);
        final ccList = <String>[];
        for (final e in extra) {
          final v = e.trim();
          final lower = v.toLowerCase();
          if (lower == me) continue;
          if (_to.any((x) => x.toLowerCase() == lower)) continue;
          if (ccList.any((x) => x.toLowerCase() == lower)) continue;
          ccList.add(v);
        }
        _cc = ccList;
        _showCcBcc = ccList.isNotEmpty;
      }
      final hasRe = subject.toLowerCase().startsWith('re:');
      _subjectCtrl.text = hasRe
          ? subject
          : 'Re: ${subject.isEmpty ? '(제목 없음)' : subject}';
    }

    final quoted = source.bodyText.trim();
    _bodyCtrl.text =
        '\n\n----- ${_isForward ? '전달된 메일' : '원본 메일'} -----\n'
        '보낸사람: ${item.fromLabel}\n'
        '일시: ${item.mailAtLabel}\n'
        '제목: ${item.subjectLabel}\n\n'
        '${quoted.isEmpty ? '(본문 없음)' : quoted}\n';
    setState(() {});
  }

  /// 개인 환경설정의 기본값(기본 서명·기본 수신확인)을 한 번 적용한다.
  void _applyPreferences(MailPreferences prefs, List<MailSignature> signs) {
    _prefsApplied = true;
    var changed = false;
    if (prefs.requestReadReceiptByDefault && !_requestReadReceipt) {
      _requestReadReceipt = true;
      changed = true;
    }
    // 새 메일이면 `defaultForNew`, 답장·전달이면 `defaultForReply` 서명을 쓴다.
    final wantReply = widget.replyToMailIdx != null;
    MailSignature? pick;
    for (final s in signs) {
      if (wantReply ? s.defaultForReply : s.defaultForNew) {
        pick = s;
        break;
      }
    }
    if (pick != null && _appliedSignature == null) {
      _insertSignature(pick, notify: false);
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  // ───────────────────────── 서명 ─────────────────────────

  void _insertSignature(MailSignature? sign, {bool notify = true}) {
    // 이전 서명은 지우고 새 서명을 붙인다. 안 그러면 서명을 바꿀 때마다
    // 본문 아래에 서명이 계속 쌓인다.
    var body = _bodyCtrl.text;
    final previous = _appliedSignature;
    if (previous != null) {
      final block = _signatureBlock(previous);
      final at = body.lastIndexOf(block);
      if (at >= 0) {
        body = body.replaceRange(at, at + block.length, '');
      }
    }
    if (sign != null) {
      body = '$body${_signatureBlock(sign)}';
    }
    _bodyCtrl.text = body;
    _appliedSignature = sign;
    if (notify) setState(() {});
  }

  String _signatureBlock(MailSignature s) => '\n\n--\n${s.insertText}\n';

  // ───────────────────────── 예약 ─────────────────────────

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final base = _scheduledAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      // 시각은 다이얼보다 직접 입력이 빠르다. 이 Flutter 버전은
      // `initialEntryMode` 이름을 쓴다(`initialTimeEntryMode` 아님).
      initialEntryMode: TimePickerEntryMode.input,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!picked.isAfter(DateTime.now())) {
      // 지난 시각으로 예약하면 서버가 즉시 보내거나 400 을 준다. 어느 쪽이든
      // 사용자가 의도한 것이 아니므로 여기서 막는다.
      _toast('예약 시각은 현재 시각보다 뒤여야 합니다.');
      return;
    }
    setState(() => _scheduledAt = picked);
  }

  String get _scheduleLabel {
    final at = _scheduledAt;
    if (at == null) return '즉시 발송';
    final l = at.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')} 예약';
  }

  // ───────────────────────── 발송 ─────────────────────────

  MailSendRequest? _buildRequest({required bool sendNow}) {
    if (_to.isEmpty) {
      _toast('받는사람을 입력해 주세요.');
      return null;
    }
    final invalid = [
      ..._to,
      ..._cc,
      ..._bcc,
    ].where((e) => !isValidMailAddress(e)).toList();
    if (invalid.isNotEmpty) {
      _toast('메일 주소 형식이 올바르지 않습니다: ${invalid.first}');
      return null;
    }
    if (_subjectCtrl.text.trim().isEmpty) {
      _toast('제목을 입력해 주세요.');
      return null;
    }
    return MailSendRequest(
      to: _to,
      cc: _cc,
      bcc: _bcc,
      subject: _subjectCtrl.text.trim(),
      bodyText: _bodyCtrl.text,
      replyToMailIdx: widget.replyToMailIdx,
      sendNow: sendNow,
      scheduledAt: sendNow ? _scheduledAt : null,
      requestReadReceipt: _requestReadReceipt,
      // 서버·DB 계약은 한 글자다(mail_mst.importance 가 char(1), 서버 검증이 [HNL]).
      // 예전에는 'HIGH' 를 보내서 중요 체크만 하면 400 입력값 검증 실패가 났다.
      importance: _highImportance ? 'H' : '',
      forward: _isForward,
    );
  }

  /// 보내기 전 확인. 외부 수신자가 있으면 **그 주소를 하나씩 보여 준다.**
  Future<bool> _confirmSend(MailPreferences prefs) async {
    final all = <String>[..._to, ..._cc, ..._bcc];
    final external = all
        .where((e) => classifyMailAddress(e) == MailAddressKind.external)
        .toList();

    final mustConfirm =
        prefs.confirmBeforeSend ||
        (prefs.warnExternalRecipients && external.isNotEmpty);
    if (!mustConfirm) return true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(external.isEmpty ? '메일 발송' : '외부 수신자가 있습니다'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 380),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '제목: ${_subjectCtrl.text.trim()}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '받는사람 ${_to.length}명'
                  '${_cc.isEmpty ? '' : ' · 참조 ${_cc.length}명'}'
                  '${_bcc.isEmpty ? '' : ' · 숨은참조 ${_bcc.length}명'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                if (_scheduledAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _scheduleLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB45309),
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ],
                if (external.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    // 외부 발송은 되돌릴 수 없다. 주소를 눈으로 확인하게 만든다.
                    '아래 주소는 사외로 나갑니다. 확인해 주세요.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in external) MailAddressChip(email: e),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
            child: Text(_scheduledAt == null ? '보내기' : '예약'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _saveDraft() async {
    final request = _buildRequest(sendNow: false);
    if (request == null) return;
    await _run(() async {
      final result = await ref.read(mailApiProvider).compose(request);
      ref.invalidate(mailCountsProvider);
      ref.invalidate(mailListProvider);
      if (!mounted) return;
      setState(() => _draftMailIdx = result.mailIdx);
      _toast('임시보관함에 저장했습니다. 이제 첨부파일을 붙일 수 있습니다.');
    }, failFallback: '임시저장에 실패했습니다.');
  }

  Future<void> _send(MailPreferences prefs) async {
    // 이미 임시저장된 건은 서버에 저장된 내용을 그대로 보낸다.
    // (백엔드에 임시저장 **수정** API 가 없어, 저장 후 화면을 잠가 두었다.)
    final draftIdx = _draftMailIdx;
    if (draftIdx != null) {
      if (!await _confirmSend(prefs)) return;
      if (!mounted) return;
      await _run(() async {
        final result = await ref.read(mailApiProvider).send(draftIdx);
        ref.invalidate(mailCountsProvider);
        ref.invalidate(mailListProvider);
        ref.invalidate(mailDetailProvider(draftIdx));
        if (!mounted) return;
        _toast(result.message.trim().isEmpty ? '발송을 요청했습니다.' : result.message);
        _goAfterSend();
      }, failFallback: '메일 발송에 실패했습니다.');
      return;
    }

    final request = _buildRequest(sendNow: true);
    if (request == null) return;
    if (!await _confirmSend(prefs)) return;
    if (!mounted) return;
    await _run(() async {
      final result = await ref.read(mailApiProvider).compose(request);
      ref.invalidate(mailCountsProvider);
      ref.invalidate(mailListProvider);
      if (!mounted) return;
      _toast(result.message.trim().isEmpty ? '발송을 요청했습니다.' : result.message);
      _goAfterSend();
    }, failFallback: '메일 발송에 실패했습니다.');
  }

  void _goAfterSend() {
    if (!mounted) return;
    // 예약이면 예약메일함으로, 즉시 발송이면 전체메일함으로 보낸다.
    // (발송은 워커가 처리하므로 곧바로 보낸메일함에 안 뜰 수 있어, 임시보관·
    //  발송대기까지 함께 보이는 전체메일함이 덜 헷갈린다.)
    context.go(
      _scheduledAt != null ? MailRoutes.scheduled : MailRoutes.all,
    );
  }

  // ───────────────────────── 첨부 ─────────────────────────

  Future<void> _addAttachment() async {
    final draftIdx = _draftMailIdx;
    if (draftIdx == null) {
      _toast('첨부를 붙이려면 먼저 「임시저장」을 눌러 주세요.');
      return;
    }
    final picked = await pickStoreDocumentFile();
    if (picked == null || !mounted) return;
    await _run(() async {
      final saved = await ref
          .read(mailApiProvider)
          .uploadAttachment(
            draftIdx,
            bytes: picked.bytes,
            fileName: picked.name,
          );
      if (!mounted) return;
      setState(() => _attachments.add(saved));
      _toast('첨부파일을 추가했습니다.');
    }, failFallback: '첨부파일 업로드에 실패했습니다.');
  }

  Future<void> _removeAttachment(MailAttachment att) async {
    await _run(() async {
      await ref.read(mailApiProvider).deleteAttachment(att.mailAttIdx);
      if (!mounted) return;
      setState(
        () => _attachments.removeWhere((a) => a.mailAttIdx == att.mailAttIdx),
      );
      _toast('첨부파일을 삭제했습니다.');
    }, failFallback: '첨부파일 삭제에 실패했습니다.');
  }

  /// 잠긴 화면에서 다시 처음부터 쓰기. 이미 만들어진 임시보관 메일은 남으므로
  /// 필요 없으면 임시보관함에서 지우면 된다(여기서 몰래 지우지 않는다).
  void _startOver() {
    setState(() {
      _draftMailIdx = null;
      _attachments.clear();
    });
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!context.menuCanCreate(kMenuMal001)) {
      return const ColoredBox(
        color: AppTheme.appSurface,
        child: Center(
          child: Text(
            '메일을 작성할 권한이 없습니다.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
      );
    }

    // 환경설정·서명은 없어도 작성은 되어야 한다. 실패하면 기본값으로 진행하고
    // 화면 위에 사유만 알린다(작성 자체를 막지 않는다).
    final prefsAsync = ref.watch(mailPreferencesProvider);
    final signsAsync = ref.watch(mailSignaturesProvider);
    final prefs = prefsAsync.valueOrNull ?? MailPreferences.defaults;
    final signs = signsAsync.valueOrNull ?? const <MailSignature>[];

    final replyIdx = widget.replyToMailIdx;
    AsyncValue<MailDetail?>? replyAsync;
    if (replyIdx != null) {
      // valueOrNull 은 AsyncValue 확장 멤버라 nullable 변수에 바로 붙일 수 없다.
      // 지역 변수로 한 번 받아 non-null 상태에서 읽는다(`!` 를 쓰지 않는 쪽이 안전하다).
      final async = ref.watch(mailDetailProvider(replyIdx));
      replyAsync = async;
      final source = async.valueOrNull;
      if (!_replyApplied && source != null) {
        // build 중에 컨트롤러를 건드리면 안 되므로 프레임 뒤로 미룬다.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_replyApplied) _applyReplySource(source);
        });
      }
    }

    // 기본 서명·기본 수신확인은 **원문을 채운 뒤에** 적용한다.
    // 순서가 뒤집히면 서명을 먼저 붙였다가 답장 본문이 통째로 덮어써서
    // 서명만 사라지고, 드롭다운에는 "서명 선택됨"으로 남아 거짓말을 하게 된다.
    final replySettled = replyIdx == null || _replyApplied;
    if (!_prefsApplied &&
        replySettled &&
        prefsAsync.hasValue &&
        signsAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_prefsApplied) _applyPreferences(prefs, signs);
      });
    }

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailScreenHeadline.plain(text: _title),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.listScreenHPadding,
                0,
                AppDimensions.listScreenHPadding,
                AppDimensions.listScreenBottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 답장 원문 조회가 실패하면 조용히 빈 화면을 주지 않는다 —
                  // 사용자는 "답장을 눌렀는데 아무것도 안 채워졌다" 만 보게 된다.
                  if (replyAsync != null && replyAsync.hasError)
                    MailErrorBanner(
                      error: replyAsync.error,
                      fallback: '원본 메일을 불러오지 못했습니다.',
                      onRetry: () =>
                          ref.invalidate(mailDetailProvider(replyIdx!)),
                    ),
                  if (replyAsync != null &&
                      replyAsync.isLoading &&
                      !replyAsync.hasValue)
                    const MailLoading(height: 80),
                  if (_locked) _lockedNotice(),
                  MailRecipientField(
                    label: '받는사람',
                    addresses: _to,
                    enabled: !_locked && !_busy,
                    onChanged: (v) => setState(() => _to = v),
                  ),
                  const MailAddressLegend(),
                  if (_showCcBcc) ...[
                    MailRecipientField(
                      label: '참조',
                      addresses: _cc,
                      enabled: !_locked && !_busy,
                      hint: '선택 입력',
                      onChanged: (v) => setState(() => _cc = v),
                    ),
                    MailRecipientField(
                      label: '숨은참조',
                      addresses: _bcc,
                      enabled: !_locked && !_busy,
                      hint: '선택 입력',
                      onChanged: (v) => setState(() => _bcc = v),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _showCcBcc = !_showCcBcc),
                      icon: Icon(
                        _showCcBcc ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                      ),
                      label: Text(_showCcBcc ? '참조 숨기기' : '참조·숨은참조'),
                    ),
                  ),
                  _field(
                    label: '제목',
                    controller: _subjectCtrl,
                    hint: '제목을 입력해 주세요',
                  ),
                  const SizedBox(height: 8),
                  _optionsCard(signs, signsAsync),
                  const SizedBox(height: 8),
                  _bodyField(),
                  const SizedBox(height: 12),
                  _attachmentSection(),
                  const SizedBox(height: 16),
                  _actionRow(prefs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _title {
    if (widget.replyToMailIdx == null) return '메일쓰기';
    if (_isForward) return '메일 전달';
    if (_isReplyAll) return '전체답장';
    return '답장';
  }

  Widget _lockedNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD3E2F7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF2563C7)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              // 여기서 "수정한 내용은 반영되지 않는다"고 분명히 알려 주는 이유:
              // 백엔드에 임시저장 수정 API 가 없어서 이 화면에서 글을 고쳐도
              // 서버에 저장된 내용은 그대로다. 알리지 않으면 사용자는 고친 줄 알고
              // 보내게 되고, 받는 사람은 옛 내용을 받는다.
              '임시보관함에 저장되었습니다. 저장된 내용 그대로 발송됩니다.\n'
              '내용을 바꾸려면 「새로 작성」을 눌러 처음부터 다시 써 주세요.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppTheme.textSecondary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _startOver,
            child: const Text('새로 작성'),
          ),
        ],
      ),
    );
  }

  /// 서명·예약·수신확인·중요도를 한 카드에 모은다.
  Widget _optionsCard(
    List<MailSignature> signs,
    AsyncValue<List<MailSignature>> signsAsync,
  ) {
    final enabled = !_locked && !_busy;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 서명 — 목록 조회가 실패해도 작성은 계속돼야 하므로 드롭다운만 감춘다.
              if (signsAsync.hasError)
                Text(
                  mailIsFeatureUnavailable(signsAsync.error)
                      ? '서명 기능은 준비 중입니다.'
                      : '서명 목록을 불러오지 못했습니다.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFB45309),
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                )
              else if (signs.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.draw_outlined,
                      size: 17,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    DropdownButton<int>(
                      value: _appliedSignature?.signIdx ?? 0,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: 0,
                          child: Text('서명 없음'),
                        ),
                        for (final s in signs)
                          DropdownMenuItem<int>(
                            value: s.signIdx,
                            child: Text(s.signNmLabel),
                          ),
                      ],
                      onChanged: enabled
                          ? (v) {
                              if (v == null || v == 0) {
                                _insertSignature(null);
                                return;
                              }
                              for (final s in signs) {
                                if (s.signIdx == v) {
                                  _insertSignature(s);
                                  return;
                                }
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              // 예약발송
              TextButton.icon(
                onPressed: enabled ? _pickSchedule : null,
                icon: Icon(
                  _scheduledAt == null
                      ? Icons.schedule_outlined
                      : Icons.event_available,
                  size: 17,
                ),
                label: Text(_scheduleLabel),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: _scheduledAt == null
                      ? AppTheme.textSecondary
                      : const Color(0xFFB45309),
                ),
              ),
              if (_scheduledAt != null)
                TextButton(
                  onPressed: enabled
                      ? () => setState(() => _scheduledAt = null)
                      : null,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('예약 취소'),
                ),
              _check(
                label: '수신확인 요청',
                value: _requestReadReceipt,
                enabled: enabled,
                onChanged: (v) => setState(() => _requestReadReceipt = v),
              ),
              _check(
                label: '중요',
                value: _highImportance,
                enabled: enabled,
                onChanged: (v) => setState(() => _highImportance = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _check({
    required String label,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: enabled ? (v) => onChanged(v ?? false) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !_locked && !_busy,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPlaceholder,
                ),
                isDense: true,
                filled: true,
                fillColor: AppTheme.cardBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.inputBorder),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _bodyCtrl,
        enabled: !_locked && !_busy,
        maxLines: 16,
        minLines: 12,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
        decoration: const InputDecoration(
          // 서식 편집기를 쓰지 않고 평문으로 보낸다. 서버가 평문만 받아도
          // Resend 가 그대로 발송하고, 수신 측 스팸 필터에도 유리하다.
          hintText: '본문을 입력해 주세요.',
          hintStyle: TextStyle(
            fontSize: 13,
            color: AppTheme.textPlaceholder,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _attachmentSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MailSectionTitle(
            title: '첨부파일 (${_attachments.length})',
            trailing: TextButton.icon(
              onPressed: _busy ? null : _addAttachment,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('파일 추가'),
            ),
          ),
          if (!_locked)
            const Text(
              '첨부는 임시저장 후에 붙일 수 있습니다(서버에 메일이 먼저 만들어져야 합니다).',
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            )
          else if (_attachments.isEmpty)
            const Text(
              '첨부된 파일이 없습니다.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            )
          else
            for (final att in _attachments)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_file,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        att.fileNameLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      att.sizeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                    IconButton(
                      tooltip: '첨부 삭제',
                      visualDensity: VisualDensity.compact,
                      onPressed: _busy ? null : () => _removeAttachment(att),
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _actionRow(MailPreferences prefs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _busy ? null : () => context.go(MailRoutes.inbox),
          child: const Text('취소'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _busy || _locked ? null : _saveDraft,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('임시저장'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _busy ? null : () => _send(prefs),
          icon: Icon(
            _scheduledAt == null ? Icons.send : Icons.schedule_send,
            size: 18,
          ),
          label: Text(_scheduledAt == null ? '보내기' : '예약발송'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accentRed,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
