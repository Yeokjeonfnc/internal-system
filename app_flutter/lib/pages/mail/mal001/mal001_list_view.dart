// 메일함 목록 — 체크박스 일괄선택·일괄동작·중요표시·정렬·페이지 나누기.
//
// 메일함마다 이 화면 하나를 쓴다(받은/보낸/임시보관/예약/스팸/휴지통/전체).
// 폴더에 따라 보여 줄 버튼이 다르다 — 휴지통에서는 "삭제"가 **완전삭제**라
// 문구와 확인 절차가 달라야 하고, 스팸함에서는 "스팸해제"가 필요하다.
//
// 정렬·검색·페이지는 전부 클라이언트에서 한다. 목록은 서버 상한(500건)까지
// 한 번에 받아 두므로 헤더를 눌러 바로 뒤집히는 편이 서버 왕복보다 낫다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_filter.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_home_view.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_provider.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_widgets.dart';
import 'package:app_flutter/pages/mail/shared/mail_routes.dart';

/// 메일함 한 개 화면.
class Mal001FolderView extends ConsumerStatefulWidget {
  const Mal001FolderView({
    super.key,
    required this.folder,
    this.title,
    this.emptyMessage,
  });

  final String folder;
  final String? title;
  final String? emptyMessage;

  @override
  ConsumerState<Mal001FolderView> createState() => _Mal001FolderViewState();
}

class _Mal001FolderViewState extends ConsumerState<Mal001FolderView> {
  final _keywordCtrl = TextEditingController();

  bool _mine = false;
  MailSearchScope _scope = MailSearchScope.all;
  MailSortSpec _sort = MailSortSpec.latestFirst;
  int _page = 1;
  int _pageSize = 50;
  bool _busy = false;

  /// 선택된 mail_idx. **화면에 안 보이는 메일까지 남기지 않는다** —
  /// 검색으로 걸러진 뒤에도 선택이 살아 있으면 "3건 선택"인데 목록엔 1건만
  /// 보이는 상태가 되어, 일괄삭제가 보이지 않는 메일까지 지워 버린다.
  final Set<int> _selected = <int>{};

  /// 서버 응답으로 갱신된 행. 별표를 눌렀을 때 목록 전체를 다시 받지 않고
  /// 그 줄만 갈아 끼우기 위한 것이다(응답 값을 쓰므로 서버와 어긋나지 않는다).
  final Map<int, MailListItem> _patched = <int, MailListItem>{};

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant Mal001FolderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.folder != widget.folder) {
      // 메일함을 옮기면 선택·페이지를 초기화한다. 안 그러면 받은메일함에서 고른
      // 3건이 보낸메일함에서도 "선택됨"으로 남아 엉뚱한 메일이 지워진다.
      //
      // `didUpdateWidget` 뒤에는 어차피 build 가 이어지므로 setState 를 부르지 않는다.
      _selected.clear();
      _patched.clear();
      _page = 1;
    }
  }

  MailListKey get _listKey {
    final uid = provider.Provider.of<AuthProvider>(context, listen: false).userId;
    return mailListKey(uid, widget.folder, mine: _mine);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refresh() async {
    final key = _listKey;
    ref.invalidate(mailListProvider(key));
    ref.invalidate(mailCountsProvider);
    setState(() => _patched.clear());
    try {
      await ref.read(mailListProvider(key).future);
    } catch (_) {
      // 실패 사유는 아래 배너가 화면에 그대로 보여 준다. 여기서 다시 던지면
      // RefreshIndicator 안에서 처리되지 않은 예외가 된다.
    }
  }

  /// 공통 실행 래퍼 — 실패 사유를 **그대로** 보여 준다(조용히 삼키지 않는다).
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

  List<MailListItem> _visibleItems(List<MailListItem> raw) {
    final patched = _patched.isEmpty
        ? raw
        : [for (final m in raw) _patched[m.mailIdx] ?? m];
    final filtered = mailItemsMatchingKeyword(
      patched,
      _keywordCtrl.text,
      scope: _scope,
    );
    return sortMailItems(filtered, _sort);
  }

  /// 지금 유효한 페이지 번호.
  ///
  /// 검색으로 목록이 줄어들면 `_page` 가 마지막 페이지를 넘어설 수 있다.
  /// 그대로 두면 **목록이 텅 빈 채로 "3 / 1 페이지"** 가 뜬다 — 결과가 없는 줄 안다.
  int _clampedPage(int totalCount) {
    final last = totalCount <= 0 ? 1 : ((totalCount - 1) ~/ _pageSize) + 1;
    return _page.clamp(1, last);
  }

  List<MailListItem> _pageItems(List<MailListItem> sorted) {
    final page = _clampedPage(sorted.length);
    final start = (page - 1) * _pageSize;
    if (start >= sorted.length) return const <MailListItem>[];
    final end = (start + _pageSize).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }

  // ───────────────────────── 동작 ─────────────────────────

  Future<void> _toggleStar(MailListItem item, bool starred) async {
    await _run(() async {
      final updated = await ref
          .read(mailApiProvider)
          .updateFlags(item.mailIdx, starred: starred);
      if (!mounted) return;
      // 서버가 돌려준 값으로 갱신한다. 요청 값을 그대로 믿고 켜 두면, 서버가
      // 아직 중요표시를 모를 때 새로고침에서 별이 사라져 더 헷갈린다.
      setState(() => _patched[item.mailIdx] = updated);
      ref.invalidate(mailCountsProvider);
    }, failFallback: '중요표시를 변경하지 못했습니다.');
  }

  Future<void> _bulk(String action, {int? targetFolderIdx}) async {
    final ids = _selected.toList(growable: false);
    if (ids.isEmpty) return;

    if (MailBulkActions.isDestructive(action)) {
      final confirmed = await _confirmDestructive(action, ids.length);
      if (confirmed != true || !mounted) return;
    }

    await _run(() async {
      final result = await ref
          .read(mailApiProvider)
          .bulkAction(
            mailIdxList: ids,
            action: action,
            targetFolderIdx: targetFolderIdx,
          );
      if (!mounted) return;
      setState(() {
        _selected.clear();
        _patched.clear();
      });
      ref.invalidate(mailListProvider(_listKey));
      ref.invalidate(mailCountsProvider);

      // 요청 건수와 처리 건수가 다르면 성공이라고 말하지 않는다 —
      // "10건 삭제했습니다" 인데 실제로 2건만 지워진 상황을 숨기지 않는다.
      if (result.affected < result.requested && result.requested > 0) {
        _toast(
          '${MailBulkActions.labelOf(action)}: 요청 ${result.requested}건 중 '
          '${result.affected}건만 처리되었습니다.'
          '${result.message.isEmpty ? '' : ' ${result.message}'}',
        );
        return;
      }
      _toast(
        result.message.trim().isEmpty
            ? '${ids.length}건을 ${MailBulkActions.labelOf(action)}했습니다.'
            : result.message,
      );
    }, failFallback: '${MailBulkActions.labelOf(action)}에 실패했습니다.');
  }

  Future<bool?> _confirmDestructive(String action, int count) {
    final purge = action == MailBulkActions.purge;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(purge ? '완전삭제' : '메일 삭제'),
        content: Text(
          purge
              // 완전삭제는 되돌릴 수 없다. 그 사실을 반드시 문장으로 알린다.
              ? '선택한 $count건을 완전히 삭제합니다.\n삭제한 메일은 복구할 수 없습니다.'
              : '선택한 $count건을 휴지통으로 옮깁니다.',
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
            child: Text(purge ? '완전삭제' : '삭제'),
          ),
        ],
      ),
    );
  }

  /// 사용자 정의 메일함으로 이동.
  Future<void> _showMoveDialog() async {
    final foldersAsync = await _loadUserFolders();
    if (!mounted) return;
    if (foldersAsync == null) return; // 실패 사유는 이미 안내했다.
    if (foldersAsync.isEmpty) {
      _toast('만들어 둔 메일함이 없습니다. 「메일설정」에서 먼저 추가해 주세요.');
      return;
    }

    final picked = await showDialog<MailUserFolder>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('메일함으로 이동'),
        children: [
          for (final f in foldersAsync)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, f),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(f.folderNmLabel)),
                  ],
                ),
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
    );
    if (picked == null || !mounted) return;
    await _bulk(MailBulkActions.move, targetFolderIdx: picked.folderIdx);
  }

  /// 메일함 목록을 읽어 온다. 실패하면 사유를 알리고 null.
  Future<List<MailUserFolder>?> _loadUserFolders() async {
    try {
      return await ref.read(mailUserFoldersProvider.future);
    } catch (e) {
      if (!mounted) return null;
      _toast(
        mailIsFeatureUnavailable(e)
            ? e.toString()
            : formatApiUserMessage(e, fallback: '메일함 목록을 불러오지 못했습니다.'),
      );
      return null;
    }
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final key = _listKey;
    final listAsync = ref.watch(mailListProvider(key));
    final title = widget.title ?? MailFolders.labelOf(widget.folder);
    final canUpdate = context.menuCanUpdate(kMenuMal001);
    final canDelete = context.menuCanDelete(kMenuMal001);

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(title),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          // 받은메일함에서만 메일함 현황을 함께 보여 준다. 다른 메일함에서는
          // 사이드바 뱃지로 충분하고, 화면 위쪽을 차지할 이유가 없다.
          if (widget.folder == MailFolders.inbox) const MailCountsStrip(),
          MailSearchBar(
            controller: _keywordCtrl,
            onChanged: (_) => setState(() => _page = 1),
            mine: _mine,
            onMineChanged: (v) => setState(() {
              _mine = v;
              _page = 1;
              _selected.clear();
            }),
            scope: _scope,
            onScopeChanged: (v) => setState(() {
              _scope = v;
              _page = 1;
            }),
          ),
          MailBulkActionBar(
            selectedCount: _selected.length,
            folder: widget.folder,
            busy: _busy,
            canUpdate: canUpdate,
            canDelete: canDelete,
            onAction: _bulk,
            onMove: canUpdate ? _showMoveDialog : null,
            onClear: () => setState(_selected.clear),
          ),
          Expanded(
            child: listAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 8),
                    MailFailureBanner(
                      error: e,
                      feature: '$title 조회',
                      fallback: '$title 조회에 실패했습니다.',
                      onRetry: _refresh,
                    ),
                  ],
                ),
              ),
              data: (raw) => _body(raw, canUpdate: canUpdate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String title) {
    return Row(
      children: [
        Expanded(child: DetailScreenHeadline.plain(text: title)),
        IconButton(
          tooltip: '새로고침',
          onPressed: _busy ? null : _refresh,
          icon: const Icon(Icons.refresh, size: 20),
        ),
        if (context.menuCanCreate(kMenuMal001))
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: FilledButton.icon(
              onPressed: () => context.push(MailRoutes.compose),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('메일쓰기'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _body(List<MailListItem> raw, {required bool canUpdate}) {
    final sorted = _visibleItems(raw);
    if (sorted.isEmpty) {
      // "검색 결과 없음" 과 "메일함이 비었음" 을 구분한다 — 같은 문구로 묶으면
      // 필터를 켜 둔 줄 모르고 메일이 사라졌다고 오해한다.
      final searching = _keywordCtrl.text.trim().isNotEmpty && raw.isNotEmpty;
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 8),
            MailEmptyBanner(
              message: searching
                  ? '검색 결과가 없습니다'
                  : (widget.emptyMessage ??
                        MailFolders.emptyMessageOf(widget.folder)),
            ),
          ],
        ),
      );
    }

    final pageItems = _pageItems(sorted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MailPagerBar(
          totalCount: sorted.length,
          page: _clampedPage(sorted.length),
          pageSize: _pageSize,
          onPageChanged: (p) => setState(() => _page = p),
          onPageSizeChanged: (n) => setState(() {
            _pageSize = n;
            _page = 1;
          }),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.listScreenHPadding,
              0,
              AppDimensions.listScreenHPadding,
              AppDimensions.listScreenBottomPadding,
            ),
            child: MailMessageTable(
              items: pageItems,
              // 수신확인은 보낸메일함에서만 의미가 있다. 받은메일함에 "미확인"이
              // 뜨면 **내가** 안 읽었다는 뜻으로 읽혀 정반대로 오해된다.
              showReadReceipt: widget.folder == MailFolders.sent,
              sort: _sort,
              onSort: (field) => setState(() {
                _sort = _sort.toggled(field);
                _page = 1;
              }),
              selectedIds: _selected,
              onToggleSelect: canUpdate
                  ? (item, selected) => setState(() {
                      if (selected) {
                        _selected.add(item.mailIdx);
                      } else {
                        _selected.remove(item.mailIdx);
                      }
                    })
                  : null,
              // 전체선택은 **지금 페이지에 보이는 것만** 고른다. 안 보이는 페이지까지
              // 함께 선택하면 사용자가 확인하지 못한 메일이 일괄삭제된다.
              onToggleSelectAll: canUpdate
                  ? (selectAll) => setState(() {
                      if (selectAll) {
                        _selected.addAll(pageItems.map((m) => m.mailIdx));
                      } else {
                        _selected.removeAll(pageItems.map((m) => m.mailIdx));
                      }
                    })
                  : null,
              onToggleStar: canUpdate ? _toggleStar : null,
              // 지금 메일함을 함께 넘긴다 — 상세에서 이전/다음이 이 목록을 따라간다.
              onOpen: (item) =>
                  MailRoutes.openMail(context, item, folder: widget.folder),
            ),
          ),
        ),
      ],
    );
  }
}
