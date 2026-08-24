// 메일 설정(mal008) — 개인 환경설정 / 서명 / 사용자 메일함 / 자동분류 / 자동전달.
//
// 다섯 영역 모두 백엔드가 아직 준비 중일 수 있다. 그때 화면이 빨간 오류로 도배되면
// "서버가 죽었다"로 오해하므로, `MailFeatureUnavailable` 이면 "준비 중" 안내로
// 물러난다. 그 밖의 실패(403 권한·500 오류·타임아웃)는 예전처럼 사유를 그대로 보여 준다.
//
// 자동분류·자동전달 두 카드는 덩치가 커서 `mal001_settings_auto.dart` 로 뺐다.
// 카드 껍데기·스위치 줄은 `mal001_widgets.dart` 의 공용 위젯을 함께 쓴다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_provider.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_settings_auto.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_widgets.dart';

class Mal001SettingsView extends ConsumerStatefulWidget {
  const Mal001SettingsView({super.key});

  @override
  ConsumerState<Mal001SettingsView> createState() => _Mal001SettingsViewState();
}

class _Mal001SettingsViewState extends ConsumerState<Mal001SettingsView> {
  bool _busy = false;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 실패를 삼키지 않는다 — "준비 중"과 진짜 실패를 구분해 문장으로 보여 준다.
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

  @override
  Widget build(BuildContext context) {
    if (!context.menuCanView(kMenuMal008)) {
      return const ColoredBox(
        color: AppTheme.appSurface,
        child: Center(
          child: Text(
            '메일 설정을 볼 권한이 없습니다.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
      );
    }
    final canUpdate = context.menuCanUpdate(kMenuMal008);

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailScreenHeadline.plain(text: '메일설정'),
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
                  _PreferencesCard(canUpdate: canUpdate, run: _run),
                  const SizedBox(height: 12),
                  _SignatureCard(
                    canUpdate: canUpdate,
                    run: _run,
                    toast: _toast,
                    busy: _busy,
                  ),
                  const SizedBox(height: 12),
                  _UserFolderCard(
                    canUpdate: canUpdate,
                    run: _run,
                    toast: _toast,
                    busy: _busy,
                  ),
                  const SizedBox(height: 12),
                  // 자동분류가 자동전달보다 위다 — 분류는 내 메일함 안에서 끝나지만
                  // 전달은 메일이 사외로 나간다. 위험한 설정을 아래에 둔다.
                  MailAutoRuleCard(
                    canUpdate: canUpdate,
                    run: _run,
                    toast: _toast,
                    busy: _busy,
                  ),
                  const SizedBox(height: 12),
                  MailForwardCard(
                    canUpdate: canUpdate,
                    run: _run,
                    toast: _toast,
                    busy: _busy,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 카드 껍데기(`MailSettingsCard`)·스위치 줄(`MailSettingSwitchRow`)·실행 래퍼 형태
// (`MailSettingsRunAction`)는 `mal001_widgets.dart` 에 있다. 설정 카드가 파일 두 곳으로
// 갈라져 있어 껍데기를 공용으로 두지 않으면 여백·테두리가 서로 어긋난다.

// ───────────────────────── 개인 환경설정 ─────────────────────────

class _PreferencesCard extends ConsumerWidget {
  const _PreferencesCard({required this.canUpdate, required this.run});

  final bool canUpdate;
  final MailSettingsRunAction run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mailPreferencesProvider);

    Future<void> save(MailPreferences next) async {
      await run(() async {
        await ref.read(mailApiProvider).savePreferences(next);
        ref.invalidate(mailPreferencesProvider);
      }, failFallback: '환경설정 저장에 실패했습니다.');
    }

    return MailSettingsCard(
      title: '개인 환경설정',
      description: '이 설정은 나에게만 적용됩니다.',
      child: async.when(
        loading: () => const MailLoading(height: 80),
        error: (e, _) => MailFailureBanner(
          error: e,
          feature: '메일 환경설정',
          fallback: '환경설정을 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(mailPreferencesProvider),
        ),
        data: (prefs) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MailSettingSwitchRow(
              label: '보내기 전에 확인 창 띄우기',
              description: '받는사람과 제목을 한 번 더 확인합니다.',
              value: prefs.confirmBeforeSend,
              enabled: canUpdate,
              onChanged: (v) => save(prefs.copyWith(confirmBeforeSend: v)),
            ),
            MailSettingSwitchRow(
              label: '외부 수신자가 있으면 경고',
              description: '사외 주소가 섞여 있으면 발송 전에 그 주소를 보여 줍니다.',
              value: prefs.warnExternalRecipients,
              enabled: canUpdate,
              onChanged: (v) =>
                  save(prefs.copyWith(warnExternalRecipients: v)),
            ),
            MailSettingSwitchRow(
              label: '기본으로 수신확인 요청',
              description: '새 메일을 쓸 때 수신확인 요청이 미리 켜집니다.',
              value: prefs.requestReadReceiptByDefault,
              enabled: canUpdate,
              onChanged: (v) =>
                  save(prefs.copyWith(requestReadReceiptByDefault: v)),
            ),
            MailSettingSwitchRow(
              label: '외부 이미지 차단',
              description:
                  '메일을 열 때 원격 이미지를 막습니다. '
                  '보낸 사람이 "언제 읽었는지" 추적하는 것을 막아 줍니다.',
              value: prefs.blockExternalImages,
              enabled: canUpdate,
              onChanged: (v) => save(prefs.copyWith(blockExternalImages: v)),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 서명 ─────────────────────────

class _SignatureCard extends ConsumerWidget {
  const _SignatureCard({
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
    final async = ref.watch(mailSignaturesProvider);

    Future<void> edit(MailSignature? existing) async {
      final result = await showDialog<MailSignature>(
        context: context,
        builder: (ctx) => _SignatureDialog(initial: existing),
      );
      if (result == null) return;
      await run(() async {
        await ref.read(mailApiProvider).saveSignature(result);
        ref.invalidate(mailSignaturesProvider);
        toast('서명을 저장했습니다.');
      }, failFallback: '서명 저장에 실패했습니다.');
    }

    Future<void> remove(MailSignature s) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('서명 삭제'),
          content: Text('「${s.signNmLabel}」 서명을 삭제하시겠습니까?'),
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
        await ref.read(mailApiProvider).deleteSignature(s.signIdx);
        ref.invalidate(mailSignaturesProvider);
        toast('서명을 삭제했습니다.');
      }, failFallback: '서명 삭제에 실패했습니다.');
    }

    return MailSettingsCard(
      title: '서명 관리',
      description: '새 메일과 답장에 각각 기본 서명을 정할 수 있습니다.',
      trailing: canUpdate && !async.hasError
          ? TextButton.icon(
              onPressed: busy ? null : () => edit(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('서명 추가'),
            )
          : null,
      child: async.when(
        loading: () => const MailLoading(height: 80),
        error: (e, _) => MailFailureBanner(
          error: e,
          feature: '메일 서명',
          fallback: '서명 목록을 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(mailSignaturesProvider),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '등록된 서명이 없습니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in rows)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                  decoration: BoxDecoration(
                    color: AppTheme.appSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.hairline),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    s.signNmLabel,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                      fontFamilyFallback:
                                          AppTheme.koreanFontFallback,
                                    ),
                                  ),
                                ),
                                if (s.defaultForNew) const _Tag('새메일 기본'),
                                if (s.defaultForReply) const _Tag('답장 기본'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.insertText,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppTheme.textSecondary,
                                fontFamilyFallback:
                                    AppTheme.koreanFontFallback,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canUpdate) ...[
                        IconButton(
                          tooltip: '수정',
                          visualDensity: VisualDensity.compact,
                          onPressed: busy ? null : () => edit(s),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                        ),
                        IconButton(
                          tooltip: '삭제',
                          visualDensity: VisualDensity.compact,
                          onPressed: busy ? null : () => remove(s),
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
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD3E2F7)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2563C7),
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

class _SignatureDialog extends StatefulWidget {
  const _SignatureDialog({this.initial});

  final MailSignature? initial;

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bodyCtrl;
  late bool _forNew;
  late bool _forReply;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _nameCtrl = TextEditingController(text: s?.signNm ?? '');
    _bodyCtrl = TextEditingController(text: s?.insertText ?? '');
    _forNew = s?.defaultForNew ?? false;
    _forReply = s?.defaultForReply ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('서명 이름을 입력해 주세요.')));
      return;
    }
    Navigator.pop(
      context,
      MailSignature(
        signIdx: widget.initial?.signIdx ?? 0,
        signNm: _nameCtrl.text.trim(),
        bodyText: _bodyCtrl.text,
        bodyHtml: '',
        defaultForNew: _forNew,
        defaultForReply: _forReply,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '서명 추가' : '서명 수정'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '서명 이름',
                  hintText: '예) 기본 서명',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyCtrl,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: '서명 내용',
                  hintText: '이름 / 직위 / 연락처 등',
                  isDense: true,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _forNew,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('새 메일 기본 서명'),
                onChanged: (v) => setState(() => _forNew = v ?? false),
              ),
              CheckboxListTile(
                value: _forReply,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('답장·전달 기본 서명'),
                onChanged: (v) => setState(() => _forReply = v ?? false),
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

// ───────────────────────── 사용자 정의 메일함 ─────────────────────────

class _UserFolderCard extends ConsumerWidget {
  const _UserFolderCard({
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
    final async = ref.watch(mailUserFoldersProvider);

    Future<void> edit(MailUserFolder? existing) async {
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => _FolderNameDialog(initial: existing?.folderNm ?? ''),
      );
      if (name == null) return;
      await run(() async {
        await ref
            .read(mailApiProvider)
            .saveUserFolder(
              MailUserFolder(
                folderIdx: existing?.folderIdx ?? 0,
                folderNm: name,
                sortOrder: existing?.sortOrder ?? 0,
                mailCnt: 0,
              ),
            );
        ref.invalidate(mailUserFoldersProvider);
        toast('메일함을 저장했습니다.');
      }, failFallback: '메일함 저장에 실패했습니다.');
    }

    Future<void> remove(MailUserFolder f) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('메일함 삭제'),
          content: Text(
            f.mailCnt > 0
                // 안에 메일이 있으면 그 사실을 먼저 알린다 — 서버가 어떻게
                // 처리하든(받은메일함으로 되돌리든) 사용자가 모르고 지우면 안 된다.
                ? '「${f.folderNmLabel}」 안에 ${f.mailCnt}건이 있습니다.\n'
                      '메일함을 삭제하시겠습니까?'
                : '「${f.folderNmLabel}」 메일함을 삭제하시겠습니까?',
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
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await run(() async {
        await ref.read(mailApiProvider).deleteUserFolder(f.folderIdx);
        ref.invalidate(mailUserFoldersProvider);
        toast('메일함을 삭제했습니다.');
      }, failFallback: '메일함 삭제에 실패했습니다.');
    }

    return MailSettingsCard(
      title: '사용자 메일함 관리',
      description: '목록에서 「이동」을 눌러 메일을 이 메일함으로 옮길 수 있습니다.',
      trailing: canUpdate && !async.hasError
          ? TextButton.icon(
              onPressed: busy ? null : () => edit(null),
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('메일함 추가'),
            )
          : null,
      child: async.when(
        loading: () => const MailLoading(height: 80),
        error: (e, _) => MailFailureBanner(
          error: e,
          feature: '사용자 메일함',
          fallback: '메일함 목록을 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(mailUserFoldersProvider),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '만들어 둔 메일함이 없습니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final f in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 17,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f.folderNmLabel,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppTheme.textPrimary,
                            fontFamilyFallback: AppTheme.koreanFontFallback,
                          ),
                        ),
                      ),
                      Text(
                        '${f.mailCnt}건',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textMuted,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                      if (canUpdate) ...[
                        IconButton(
                          tooltip: '이름 변경',
                          visualDensity: VisualDensity.compact,
                          onPressed: busy ? null : () => edit(f),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                        ),
                        IconButton(
                          tooltip: '삭제',
                          visualDensity: VisualDensity.compact,
                          onPressed: busy ? null : () => remove(f),
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
    );
  }
}

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({this.initial = ''});

  final String initial;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메일함 이름을 입력해 주세요.')));
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial.isEmpty ? '메일함 추가' : '메일함 이름 변경'),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: '메일함 이름',
            hintText: '예) 거래처, 프로젝트A',
            isDense: true,
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
