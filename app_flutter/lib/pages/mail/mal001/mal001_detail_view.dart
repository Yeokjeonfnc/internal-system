// 메일 상세 — 왼쪽 본문 / 오른쪽 참여자·첨부·발송이력·스레드.
//
// 본문 HTML 은 **외부인이 보낸 신뢰할 수 없는 문서**다. 두 겹으로 막는다.
//  1) `sanitizeMailHtml` 로 스크립트·이벤트 속성·javascript: URL 을 제거하고,
//  2) 그 결과를 다시 `sandbox="allow-scripts"` iframe 안에서만 그린다.
// 여기에 더해 외부 이미지는 기본 차단이다(추적픽셀로 열람 시각이 새는 것을 막는다).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import 'package:url_launcher/url_launcher.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/web/iframe_pointer_gate.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_content_html_preview.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_html_sanitize.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_provider.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_widgets.dart';
import 'package:app_flutter/pages/mail/shared/mail_routes.dart';

class Mal001DetailView extends ConsumerStatefulWidget {
  const Mal001DetailView({super.key, required this.mailIdx, this.folder});

  final int mailIdx;

  /// 어느 메일함에서 들어왔는지 — 이전/다음 이동에 쓴다. null 이면 받은메일함 기준.
  final String? folder;

  @override
  ConsumerState<Mal001DetailView> createState() => _Mal001DetailViewState();
}

class _Mal001DetailViewState extends ConsumerState<Mal001DetailView> {
  /// 본문 표시 모드. **기본은 텍스트다.**
  ///
  /// 메일 본문은 이 앱에서 가장 신뢰할 수 없는 HTML 이다(외부인이 보낸다).
  /// HTML 로 볼 때는 sanitize + iframe 샌드박스로 이중 격리하지만, 그래도 기본값은
  /// 서버가 만들어 준 평문(`body_text`)으로 둔다 — 대부분의 업무 메일은 평문으로
  /// 충분하고, 원본 그대로 봐야 할 때만 사용자가 직접 켜게 한다.
  bool _showHtml = false;

  /// 외부 이미지 표시 여부. **기본은 차단**이다(추적픽셀 방어).
  /// 사용자가 "이미지 표시"를 누른 메일에 한해, 그 화면이 살아 있는 동안만 풀린다.
  bool _showExternalImages = false;

  /// 상세를 처음 열면 서버가 `read_yn='Y'` 로 바꾸므로, 목록·건수도 한 번 다시 읽는다.
  bool _readSynced = false;

  bool _busy = false;

  Future<void> _refreshLists() async {
    ref.invalidate(mailCountsProvider);
    ref.invalidate(mailListProvider);
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
      // 실패를 조용히 넘기지 않는다 — 사유를 그대로 보여 준다.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatApiUserMessage(e, fallback: failFallback)),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(mailDetailProvider(widget.mailIdx));

    // 값이 도착한 뒤 딱 한 번 목록·건수를 갱신한다(안 읽음 뱃지를 맞추기 위해).
    if (!_readSynced && detailAsync.hasValue && detailAsync.value != null) {
      _readSynced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshLists();
      });
    }

    return ColoredBox(
      color: AppTheme.appSurface,
      child: detailAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 16),
            MailErrorBanner(
              error: e,
              fallback: '메일을 불러오지 못했습니다.',
              onRetry: () => ref.invalidate(mailDetailProvider(widget.mailIdx)),
            ),
            Center(
              child: TextButton(
                onPressed: () => _goBack(),
                child: const Text('메일함으로'),
              ),
            ),
          ],
        ),
        data: (detail) {
          if (detail == null) return _notFound();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolbar(detail),
              if (_busy) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: _buildBody(detail),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(MailRoutes.inbox);
  }

  Widget _notFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '메일을 찾을 수 없습니다. 이미 삭제되었을 수 있습니다.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(MailRoutes.inbox),
            child: const Text('받은메일함으로'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(MailDetail detail) {
    final item = detail.summary;
    final canUpdate = context.menuCanUpdate(kMenuMal001);
    final canCreate = context.menuCanCreate(kMenuMal001);
    final canDelete = context.menuCanDelete(kMenuMal001);
    final isDraft = item.outbound && item.sendStatus.toUpperCase() == 'DRAFT';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(bottom: BorderSide(color: AppTheme.hairline)),
      ),
      // 제목 줄과 버튼 줄을 나눈다. 한 줄에 몰면 좁은 화면(앱·분할 창)에서
      // Row 가 넘쳐 노란 줄무늬(RenderFlex overflow)가 뜬다.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '뒤로',
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back, size: 20),
              ),
              if (canUpdate)
                IconButton(
                  tooltip: item.starred ? '중요표시 해제' : '중요표시',
                  onPressed: _busy
                      ? null
                      : () => _updateFlags(
                          item.mailIdx,
                          starred: !item.starred,
                        ),
                  icon: Icon(
                    item.starred ? Icons.star : Icons.star_border,
                    size: 20,
                    color: item.starred
                        ? const Color(0xFFE9A100)
                        : AppTheme.textMuted,
                  ),
                ),
              Expanded(
                child: Text(
                  item.subjectLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.chromeBlack,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
              _PrevNextButtons(
                currentMailIdx: item.mailIdx,
                folder: widget.folder ??
                    (item.inbound ? MailFolders.inbox : MailFolders.sent),
              ),
              MailStatusBadge(item: item, center: false),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: [
              if (canCreate) ...[
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () =>
                            context.push(MailRoutes.composeReply(item.mailIdx)),
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text('답장'),
                ),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => context.push(
                          MailRoutes.composeReplyAll(item.mailIdx),
                        ),
                  icon: const Icon(Icons.reply_all, size: 18),
                  label: const Text('전체답장'),
                ),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => context.push(
                          MailRoutes.composeForward(item.mailIdx),
                        ),
                  icon: const Icon(Icons.forward, size: 18),
                  label: const Text('전달'),
                ),
              ],
              if (canCreate && isDraft)
                TextButton.icon(
                  onPressed: _busy ? null : () => _send(item.mailIdx),
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('보내기'),
                ),
              if (canUpdate && item.inbound)
                TextButton.icon(
                  onPressed: _busy ? null : () => _refreshBody(item.mailIdx),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('본문 다시 가져오기'),
                ),
              if (canUpdate)
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _updateFlags(item.mailIdx, read: !item.read),
                  icon: Icon(
                    item.read
                        ? Icons.mark_email_unread_outlined
                        : Icons.drafts_outlined,
                    size: 18,
                  ),
                  label: Text(item.read ? '안읽음으로' : '읽음으로'),
                ),
              if (canUpdate)
                TextButton.icon(
                  onPressed: _busy ? null : () => _move(item.mailIdx),
                  icon: const Icon(Icons.drive_file_move_outline, size: 18),
                  label: const Text('이동'),
                ),
              if (canUpdate)
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _updateFlags(item.mailIdx, spam: !item.spam),
                  icon: const Icon(
                    Icons.report_gmailerrorred_outlined,
                    size: 18,
                  ),
                  label: Text(item.spam ? '스팸 해제' : '스팸 처리'),
                ),
              if (canDelete)
                TextButton.icon(
                  onPressed: _busy ? null : () => _delete(detail),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('삭제'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentRed,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 사용자 정의 메일함으로 이동. 목록의 일괄 이동과 같은 API 를 쓴다.
  Future<void> _move(int mailIdx) async {
    List<MailUserFolder> folders;
    try {
      folders = await ref.read(mailUserFoldersProvider.future);
    } catch (e) {
      if (!mounted) return;
      _toast(
        mailIsFeatureUnavailable(e)
            ? e.toString()
            : formatApiUserMessage(e, fallback: '메일함 목록을 불러오지 못했습니다.'),
      );
      return;
    }
    if (!mounted) return;
    if (folders.isEmpty) {
      _toast('만들어 둔 메일함이 없습니다. 「메일설정」에서 먼저 추가해 주세요.');
      return;
    }
    // 본문 iframe 이 떠 있으면 다이얼로그가 포인터를 못 받는다 — 게이트를 태운다.
    final picked = await IframePointerGate.whileBlocked(
      () => showDialog<MailUserFolder>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('메일함으로 이동'),
          children: [
            for (final f in folders)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, f),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(f.folderNmLabel),
                ),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('취소'),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _run(() async {
      await ref
          .read(mailApiProvider)
          .bulkAction(
            mailIdxList: [mailIdx],
            action: MailBulkActions.move,
            targetFolderIdx: picked.folderIdx,
          );
      ref.invalidate(mailDetailProvider(mailIdx));
      await _refreshLists();
      _toast('「${picked.folderNmLabel}」 (으)로 옮겼습니다.');
    }, failFallback: '메일 이동에 실패했습니다.');
  }

  Widget _buildBody(MailDetail detail) {
    final compact = useCompactErpLayout(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = compact || constraints.maxWidth < 1100;
        final bodyCard = _BodyCard(
          detail: detail,
          showHtml: _showHtml,
          onToggleHtml: (v) => setState(() => _showHtml = v),
          showExternalImages: _showExternalImages,
          onShowExternalImages: () =>
              setState(() => _showExternalImages = true),
        );
        final sideCard = _SidePanel(
          detail: detail,
          onOpenAttachment: _openAttachment,
          onDownloadAll: () => _downloadAllAttachments(detail),
          onDeleteAttachment: context.menuCanDelete(kMenuMal001)
              ? _deleteAttachment
              : null,
        );
        if (narrow) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 460, child: bodyCard),
                const SizedBox(height: 12),
                sideCard,
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: bodyCard),
            const SizedBox(width: 12),
            SizedBox(
              width: 380,
              child: SingleChildScrollView(child: sideCard),
            ),
          ],
        );
      },
    );
  }

  Future<void> _send(int mailIdx) async {
    await _run(() async {
      final result = await ref.read(mailApiProvider).send(mailIdx);
      ref.invalidate(mailDetailProvider(mailIdx));
      await _refreshLists();
      _toast(
        result.message.trim().isEmpty ? '발송을 요청했습니다.' : result.message,
      );
    }, failFallback: '메일 발송 요청에 실패했습니다.');
  }

  Future<void> _refreshBody(int mailIdx) async {
    await _run(() async {
      await ref.read(mailApiProvider).refreshBody(mailIdx);
      ref.invalidate(mailDetailProvider(mailIdx));
      _toast('본문을 다시 가져왔습니다.');
    }, failFallback: '본문을 다시 가져오지 못했습니다.');
  }

  Future<void> _updateFlags(
    int mailIdx, {
    bool? read,
    bool? spam,
    bool? starred,
  }) async {
    await _run(() async {
      await ref
          .read(mailApiProvider)
          .updateFlags(mailIdx, read: read, spam: spam, starred: starred);
      ref.invalidate(mailDetailProvider(mailIdx));
      await _refreshLists();
      _toast('메일 상태를 변경했습니다.');
    }, failFallback: '메일 상태 변경에 실패했습니다.');
  }

  Future<void> _delete(MailDetail detail) async {
    // 본문 iframe 이 떠 있으면 다이얼로그가 포인터를 못 받는다 —
    // 전자결재와 같은 게이트를 태운다.
    final ok = await IframePointerGate.whileBlocked(
      () => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('메일 삭제'),
          content: Text('「${detail.summary.subjectLabel}」 메일을 삭제하시겠습니까?'),
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
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() async {
      await ref.read(mailApiProvider).deleteMessage(detail.summary.mailIdx);
      await _refreshLists();
      _toast('메일을 삭제했습니다.');
      if (mounted) _goBack();
    }, failFallback: '메일 삭제에 실패했습니다.');
  }

  Future<void> _openAttachment(MailAttachment att) async {
    if (!att.downloadable) {
      _toast('아직 내려받을 수 없는 첨부입니다. (${att.pendingReason})');
      return;
    }
    final url = ref.read(mailApiProvider).attachmentDownloadUrl(att.mailAttIdx);
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _toast('첨부 주소를 만들지 못했습니다.');
      return;
    }
    if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
      _toast('첨부파일을 열지 못했습니다. 팝업 차단을 확인해 주세요.');
    }
  }

  /// 첨부 전체 저장.
  ///
  /// 서버에 "zip 으로 묶어 주는" API 가 없어서 한 건씩 새 탭으로 연다.
  /// 브라우저 팝업 차단에 걸리기 쉬우므로 **실패한 건수를 세어 알려 준다** —
  /// 조용히 두 개만 열리고 끝나면 사용자는 나머지가 사라진 줄 안다.
  Future<void> _downloadAllAttachments(MailDetail detail) async {
    final targets = detail.attachments.where((a) => a.downloadable).toList();
    if (targets.isEmpty) {
      _toast('내려받을 수 있는 첨부가 없습니다.');
      return;
    }
    final api = ref.read(mailApiProvider);
    var failed = 0;
    for (final att in targets) {
      final uri = Uri.tryParse(api.attachmentDownloadUrl(att.mailAttIdx));
      if (uri == null) {
        failed++;
        continue;
      }
      if (!await launchUrl(uri, webOnlyWindowName: '_blank')) failed++;
    }
    if (!mounted) return;
    if (failed > 0) {
      _toast(
        '첨부 ${targets.length}건 중 $failed건을 열지 못했습니다. 팝업 차단을 확인해 주세요.',
      );
      return;
    }
    _toast('첨부 ${targets.length}건을 새 탭으로 열었습니다.');
  }

  Future<void> _deleteAttachment(MailAttachment att) async {
    final ok = await IframePointerGate.whileBlocked(
      () => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('첨부 삭제'),
          content: Text('「${att.fileNameLabel}」 첨부를 삭제하시겠습니까?'),
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
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() async {
      await ref.read(mailApiProvider).deleteAttachment(att.mailAttIdx);
      ref.invalidate(mailDetailProvider(widget.mailIdx));
      _toast('첨부를 삭제했습니다.');
    }, failFallback: '첨부 삭제에 실패했습니다.');
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({
    required this.detail,
    required this.showHtml,
    required this.onToggleHtml,
    required this.showExternalImages,
    required this.onShowExternalImages,
  });

  final MailDetail detail;
  final bool showHtml;
  final ValueChanged<bool> onToggleHtml;
  final bool showExternalImages;
  final VoidCallback onShowExternalImages;

  @override
  Widget build(BuildContext context) {
    final item = detail.summary;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.mailAtLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textMuted,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
              if (detail.hasHtml)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'HTML 원본',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                    Switch(
                      value: showHtml,
                      onChanged: onToggleHtml,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
            ],
          ),
          if (detail.errorLine.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(
                detail.errorLine,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppTheme.accentRed,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          if (detail.truncated)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '본문이 너무 커서 일부만 저장되었습니다.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFFB45309),
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          const Divider(height: 12, color: AppTheme.hairline),
          if (showHtml && detail.hasHtml) _imageNotice(detail),
          Expanded(child: _buildBody(detail)),
        ],
      ),
    );
  }

  /// 차단한 외부 이미지가 있을 때만 뜨는 줄.
  Widget _imageNotice(MailDetail detail) {
    if (showExternalImages) return const SizedBox.shrink();
    final result = sanitizeMailHtml(detail.bodyHtml, blockExternalImages: true);
    if (!result.blockedExternalImages) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF0E0C0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: 17,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              // 왜 막았는지 이유까지 적는다. "이미지가 안 보인다"는 오해를 없애고,
              // 사용자가 신뢰하는 발신자일 때만 스스로 풀도록 유도한다.
              '외부 이미지 ${result.blockedImageCount}개를 차단했습니다. '
              '이미지를 표시하면 보낸 사람이 열람 사실을 알 수 있습니다.',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Color(0xFF8A5A0B),
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          TextButton(
            onPressed: onShowExternalImages,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: const Color(0xFFB45309),
            ),
            child: const Text('이미지 표시'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(MailDetail detail) {
    if (showHtml && detail.hasHtml) {
      // 외부에서 온 HTML 이다. 두 겹으로 막는다.
      //  1) sanitize — 스크립트·이벤트 속성·javascript: URL 제거, 외부 이미지 차단.
      //  2) 샌드박스 iframe — 전자결재 미리보기(`eapContentHtmlPreview`)가 이미
      //     sandbox="allow-scripts" 로 격리된 iframe 을 쓰고 있어 그대로 재사용한다
      //     (구현을 복제하면 나중에 한쪽만 고쳐지는 사고가 난다).
      //
      // 한 겹만으로 끝내지 않는 이유: sanitize 는 정규식 기반이라 완벽하지 않고,
      // iframe 격리는 나중에 누가 구현을 바꾸면 조용히 무너진다.
      final sanitized = sanitizeMailHtml(
        detail.bodyHtml,
        blockExternalImages: !showExternalImages,
      );
      return eapContentHtmlPreview(
        sanitized.html,
        seamless: true,
        readOnly: true,
      );
    }
    final text = detail.bodyText.trim();
    if (text.isEmpty) {
      final item = detail.summary;
      final reason = item.bodyFailed
          ? '본문 수집에 실패했습니다. 「본문 다시 가져오기」를 눌러 주세요.'
          : (item.bodyPending
                ? '본문을 아직 가져오는 중입니다. 잠시 후 다시 확인해 주세요.'
                : '본문이 없습니다.');
      return Center(
        child: Text(
          reason,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      child: SelectableText(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppTheme.textPrimary,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

/// [MailInfoRow] 와 같은 라벨-값 한 줄이지만, 값이 사람 목록일 때 각 이름을
/// **더블클릭**하면 그 사람 앞으로 새 메일쓰기(`Mal001ComposeView`)로 넘어간다.
///
/// 한 번 클릭이 아니라 더블클릭인 이유: 이 줄은 주소를 드래그해서 복사하려고
/// 자주 누르는 자리다. 한 번 클릭에 반응하면 드래그를 시작할 때마다 화면이
/// 넘어가 버린다. 대신 이 값은 더 이상 SelectableText 가 아니다 — 클릭 영역과
/// 드래그 선택 영역이 같은 위젯에서 동시에 성립하지 않기 때문에, "더블클릭하면
/// 메일쓰기"가 이겼다(툴팁으로 안내한다).
class _AddressInfoRow extends StatelessWidget {
  const _AddressInfoRow({
    required this.label,
    required this.people,
    this.fallbackText = '',
  });

  final String label;
  final List<MailAddress> people;

  /// [people] 이 비었을 때(과거 메일이라 mail_addr_dtl 이 없는 경우 등) 대신 보여줄 문구.
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return MailInfoRow(label: label, value: fallbackText);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              runSpacing: 2,
              children: [
                for (var i = 0; i < people.length; i++) ...[
                  _addressSpan(context, people[i]),
                  if (i < people.length - 1)
                    const Text(
                      ', ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressSpan(BuildContext context, MailAddress person) {
    final email = person.email.trim();
    const style = TextStyle(
      fontSize: 13,
      color: AppTheme.textPrimary,
      fontFamilyFallback: AppTheme.koreanFontFallback,
    );
    if (email.isEmpty) {
      // 이메일이 없으면 눌러도 갈 곳이 없다 — 그냥 텍스트로 둔다.
      return Text(person.label, style: style);
    }
    return Tooltip(
      message: '더블클릭 — $email 앞으로 새 메일쓰기',
      child: GestureDetector(
        onDoubleTap: () => context.push(MailRoutes.composeTo(email)),
        child: Text(
          person.label,
          style: style.copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.detail,
    required this.onOpenAttachment,
    required this.onDownloadAll,
    this.onDeleteAttachment,
  });

  final MailDetail detail;
  final Future<void> Function(MailAttachment att) onOpenAttachment;
  final VoidCallback onDownloadAll;
  final Future<void> Function(MailAttachment att)? onDeleteAttachment;

  int get downloadableCount =>
      detail.attachments.where((a) => a.downloadable).length;

  @override
  Widget build(BuildContext context) {
    final item = detail.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          title: '메일 정보',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AddressInfoRow(
                label: '보낸사람',
                people: detail.addressesOf('FROM'),
                fallbackText: item.fromLabel,
              ),
              _AddressInfoRow(
                label: '받는사람',
                people: detail.addressesOf('TO'),
                fallbackText: item.toSummary,
              ),
              if (detail.ccLine.isNotEmpty)
                _AddressInfoRow(label: '참조', people: detail.addressesOf('CC')),
              if (detail.bccLine.isNotEmpty)
                _AddressInfoRow(
                  label: '숨은참조',
                  people: detail.addressesOf('BCC'),
                ),
              if (detail.replyToLine.isNotEmpty)
                MailInfoRow(label: '회신주소', value: detail.replyToLine),
              MailInfoRow(label: '일시', value: item.mailAtLabel),
              if (item.scheduledAt != null)
                MailInfoRow(label: '예약', value: item.scheduledAtLabel),
              MailInfoRow(label: '상태', value: item.statusLabel),
              // 수신확인은 **발송 메일에만** 의미가 있다. 수신 메일에 "확인되지 않음"이
              // 뜨면 내가 안 읽었다는 뜻으로 오해된다.
              //
              // 문구를 "읽음/읽지 않음"으로 쓰지 않는 이유와 그 한계는
              // [kMailReadReceiptHelp] 에 적어 두고, 바로 아래에 그대로 보여 준다.
              if (item.outbound) ...[
                MailInfoRow(label: '수신확인', value: item.readReceiptLabel),
                const MailReadReceiptNote(),
              ],
              if (item.userId.trim().isNotEmpty)
                MailInfoRow(label: '담당자', value: item.userId),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          title: '첨부파일 (${detail.attachments.length})',
          trailing: downloadableCount > 1
              ? TextButton.icon(
                  onPressed: onDownloadAll,
                  icon: const Icon(Icons.download_outlined, size: 17),
                  label: const Text('전체 저장'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                )
              : null,
          child: detail.attachments.isEmpty
              ? const _MutedLine('첨부파일이 없습니다')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final att in detail.attachments)
                      _AttachmentRow(
                        att: att,
                        onOpen: () => onOpenAttachment(att),
                        onDelete: onDeleteAttachment == null
                            ? null
                            : () => onDeleteAttachment!(att),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _card(
          title: '발송 이력 (${detail.events.length})',
          child: detail.events.isEmpty
              ? const _MutedLine('기록된 이벤트가 없습니다')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final ev in detail.events)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 68,
                              child: Text(
                                ev.typeLabel,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                  fontFamilyFallback:
                                      AppTheme.koreanFontFallback,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                ev.recipient.trim().isEmpty
                                    ? ev.occurredAtLabel
                                    : '${ev.occurredAtLabel} · ${ev.recipient}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textMuted,
                                  fontFamilyFallback:
                                      AppTheme.koreanFontFallback,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _ThreadCard(threadIdx: item.threadIdx, currentMailIdx: item.mailIdx),
      ],
    );
  }

  Widget _card({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
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
          MailSectionTitle(title: title, trailing: trailing),
          child,
        ],
      ),
    );
  }
}

/// 같은 메일함 안에서 이전/다음 메일로 이동.
///
/// 목록 provider 를 그대로 읽어 현재 메일의 위치를 찾는다. 목록이 아직 없거나
/// (상세를 URL 로 바로 열었을 때) 현재 메일이 그 목록에 없으면 버튼을 비활성화한다 —
/// 엉뚱한 메일로 튀는 것보다 눌리지 않는 편이 낫다.
class _PrevNextButtons extends ConsumerWidget {
  const _PrevNextButtons({
    required this.currentMailIdx,
    required this.folder,
  });

  final int currentMailIdx;
  final String folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = provider.Provider.of<AuthProvider>(context).userId;
    final items =
        ref.watch(mailListProvider(mailListKey(uid, folder))).valueOrNull ??
        const <MailListItem>[];

    final index = items.indexWhere((m) => m.mailIdx == currentMailIdx);
    final hasPrev = index > 0;
    final hasNext = index >= 0 && index < items.length - 1;

    void go(int at) {
      // `pushReplacement` 를 쓴다. `push` 면 이전/다음을 열 번 누른 뒤
      // 뒤로가기를 열 번 눌러야 목록으로 돌아가게 된다.
      // 메일함도 함께 넘겨야 다음 화면에서도 이전/다음이 계속 동작한다.
      context.pushReplacement(
        MailRoutes.detail(items[at].mailIdx, folder: folder),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: hasPrev ? '이전 메일' : '이전 메일 없음',
          visualDensity: VisualDensity.compact,
          onPressed: hasPrev ? () => go(index - 1) : null,
          icon: const Icon(Icons.keyboard_arrow_up, size: 20),
        ),
        IconButton(
          tooltip: hasNext ? '다음 메일' : '다음 메일 없음',
          visualDensity: VisualDensity.compact,
          onPressed: hasNext ? () => go(index + 1) : null,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        ),
      ],
    );
  }
}

class _MutedLine extends StatelessWidget {
  const _MutedLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textMuted,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.att, required this.onOpen, this.onDelete});

  final MailAttachment att;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            att.downloadable
                ? Icons.attach_file
                : Icons.hourglass_empty_outlined,
            size: 16,
            color: att.downloadable ? AppTheme.textSecondary : AppTheme.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Text(
                att.fileNameLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: att.downloadable
                      ? const Color(0xFF2563C7)
                      : AppTheme.textMuted,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            att.downloadable ? att.sizeLabel : att.pendingReason,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: '첨부 삭제',
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

/// 같은 스레드의 다른 메일들 — 주고받은 흐름을 한눈에 본다.
class _ThreadCard extends ConsumerWidget {
  const _ThreadCard({required this.threadIdx, required this.currentMailIdx});

  final int threadIdx;
  final int currentMailIdx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (threadIdx <= 0) return const SizedBox.shrink();
    final threadAsync = ref.watch(mailThreadProvider(threadIdx));

    Widget body;
    if (threadAsync.isLoading && !threadAsync.hasValue) {
      body = const MailLoading(height: 60);
    } else if (threadAsync.hasError) {
      body = MailErrorBanner(
        error: threadAsync.error,
        fallback: '스레드를 불러오지 못했습니다.',
        onRetry: () => ref.invalidate(mailThreadProvider(threadIdx)),
      );
    } else {
      final thread = threadAsync.valueOrNull;
      final mails = thread?.mails ?? const <MailListItem>[];
      if (mails.length <= 1) {
        body = const _MutedLine('이 메일 하나뿐인 대화입니다');
      } else {
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final m in mails)
              InkWell(
                onTap: m.mailIdx == currentMailIdx
                    ? null
                    : () => context.push(MailRoutes.detail(m.mailIdx)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: m.mailIdx == currentMailIdx
                        ? AppTheme.tableRowSelectedTint
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        m.inbound ? '수신' : '발신',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.counterpartLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: m.unread
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: AppTheme.textPrimary,
                            fontFamilyFallback: AppTheme.koreanFontFallback,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        m.mailAtDateLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const MailSectionTitle(title: '대화'), body],
      ),
    );
  }
}
