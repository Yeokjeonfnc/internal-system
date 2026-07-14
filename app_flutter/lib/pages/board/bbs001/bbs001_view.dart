import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/perf/session_list_cache.dart';
import 'package:app_flutter/core/widgets/common/common_status_badge.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_api.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_attachment_image.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_model.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_post_editor_dialog.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_quill.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_rich_body.dart';

/// 게시판 — 폴더(좌) + 목록(우).
class BoardView extends ConsumerStatefulWidget {
  const BoardView({super.key});

  @override
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView> {
  final _api = Bbs001ApiService();
  final _searchCtrl = TextEditingController();

  List<BoardFolder> _folders = const [];
  List<BoardPost> _posts = const [];
  int? _selectedFolderIdx;
  String _keyword = '';
  int _page = 0;
  bool _loading = true;
  String? _error;

  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(_reload);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _userId => context.read<AuthProvider>().userId;

  bool get _canCreate =>
      context.read<AuthProvider>().canCreateMenu(kMenuBbs001);

  bool get _canUpdate =>
      context.read<AuthProvider>().canUpdateMenu(kMenuBbs001);

  bool get _canDelete =>
      context.read<AuthProvider>().canDeleteMenu(kMenuBbs001);

  bool get _isFranchiseOwner => context.read<AuthProvider>().isFranchiseOwner;

  Future<void> _reload() async {
    final userId = _userId;
    // userId 가 비어 있으면(로그인 프로필 로딩 지연 등) 무한 로딩에 빠지지 않도록
    // 로딩을 끄고 안내를 표시한다. (이전에는 그대로 return 해 스피너가 멈춰 있었다.)
    if (userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '로그인 정보를 불러오는 중입니다. 다시 시도해 주세요.';
      });
      return;
    }
    // 같은 폴더·키워드로 조회한 세션 캐시가 있으면 즉시 그리고 배경 갱신한다.
    final cacheKey = 'bbs001:${_selectedFolderIdx ?? 'all'}:$_keyword';
    final cachedFolders = SessionListCache.get<BoardFolder>('bbs001:folders');
    final cachedPosts = SessionListCache.get<BoardPost>(cacheKey);
    final hasCache = cachedFolders != null && cachedPosts != null;
    setState(() {
      if (hasCache) {
        _folders = cachedFolders;
        _posts = cachedPosts;
        _loading = false;
      } else {
        _loading = true;
      }
      _error = null;
    });
    try {
      // 폴더·게시글은 독립 API 이므로 병렬 호출(직렬 대비 왕복 1회 절감).
      final foldersFuture = _api.getFolders(userId);
      final postsFuture = _api.getPosts(
        userId: userId,
        folderIdx: _selectedFolderIdx,
        keyword: _keyword,
      );
      final folders = await foldersFuture;
      var folderIdx = _selectedFolderIdx;
      var posts = await postsFuture;
      if (folderIdx != null && !folders.any((f) => f.folderIdx == folderIdx)) {
        // 선택했던 폴더가 사라진 드문 경우에만 전체 글로 재조회.
        folderIdx = null;
        posts = await _api.getPosts(
          userId: userId,
          folderIdx: null,
          keyword: _keyword,
        );
      }
      if (!mounted) return;
      SessionListCache.put<BoardFolder>('bbs001:folders', folders);
      SessionListCache.put<BoardPost>(
        'bbs001:${folderIdx ?? 'all'}:$_keyword',
        posts,
      );
      setState(() {
        _folders = folders;
        _selectedFolderIdx = folderIdx;
        _posts = posts;
        if (!hasCache) _page = 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // 릴리즈 앱에서도 원인을 볼 수 있도록 실제 오류를 함께 표시.
        _error = '게시판을 불러오지 못했습니다.\n$e';
      });
    }
  }

  List<BoardPost> get _pagedPosts {
    final start = _page * _pageSize;
    if (start >= _posts.length) return const [];
    final end = (start + _pageSize).clamp(0, _posts.length);
    return _posts.sublist(start, end);
  }

  int get _totalPages {
    if (_posts.isEmpty) return 1;
    return (_posts.length + _pageSize - 1) ~/ _pageSize;
  }

  Future<void> _openEditor({BoardPost? post}) async {
    if (!_canCreate && post == null) return;
    final saved = await showBoardPostEditorDialog(
      context,
      folders: _folders,
      initialFolderIdx:
          post?.folderIdx ??
          _selectedFolderIdx ??
          _folders.firstOrNull?.folderIdx,
      post: post,
      canSetNotice: !_isFranchiseOwner,
      canEdit: post == null
          ? _canCreate
          : (_canUpdate &&
                (_isFranchiseOwner ? post.createdBy == _userId : true)),
    );
    if (saved == true) await _reload();
  }

  Future<void> _openDetail(BoardPost post) async {
    final userId = _userId;
    final detail = await _api.getPost(postIdx: post.postIdx, userId: userId);
    if (!mounted) return;
    if (detail == null) {
      await showAlertDialog(context, '게시글을 불러오지 못했습니다.');
      return;
    }
    final canEdit =
        _canUpdate && (_isFranchiseOwner ? detail.createdBy == userId : true);
    final canDel =
        _canDelete && (_isFranchiseOwner ? detail.createdBy == userId : true);

    await showDialog<void>(
      context: context,
      builder: (ctx) => _BoardPostDetailDialog(
        post: detail,
        userId: userId,
        api: _api,
        canEdit: canEdit,
        canDelete: canDel,
        onEdit: () async {
          Navigator.of(ctx).pop();
          await _openEditor(post: detail);
        },
        onDelete: () async {
          final ok = await _api.deletePost(
            postIdx: detail.postIdx,
            userId: userId,
          );
          if (!ctx.mounted) return;
          Navigator.of(ctx).pop();
          if (ok) {
            await _reload();
          } else if (mounted) {
            await showAlertDialog(context, '삭제에 실패했습니다.');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FormStylePalette.panelBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height - 120,
                  child: useCompactErpLayout(context)
                      ? _buildCompactBody()
                      : _buildWideBody(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 게시글 목록(로딩/에러 포함) — 넓은·컴팩트 레이아웃 공통.
  Widget _postContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: TextButton(onPressed: _reload, child: Text(_error!)),
      );
    }
    return _PostListPanel(
      searchCtrl: _searchCtrl,
      posts: _pagedPosts,
      totalCount: _posts.length,
      page: _page,
      totalPages: _totalPages,
      userId: _userId,
      api: _api,
      onSearch: (v) {
        _keyword = v;
        _reload();
      },
      onPage: (p) => setState(() => _page = p),
      onRefresh: _reload,
      onWrite: _canCreate ? () => _openEditor() : null,
      onOpen: _openDetail,
    );
  }

  void _onSelectFolder(int? idx) {
    setState(() => _selectedFolderIdx = idx);
    _reload();
  }

  /// 갤럭시탭·데스크톱(넓은 폭): 좌측 고정 폴더 패널 + 우측 목록.
  Widget _buildWideBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FolderPanel(
          folders: _folders,
          selectedFolderIdx: _selectedFolderIdx,
          onSelect: _onSelectFolder,
          canManageFolders: _canUpdate && !_isFranchiseOwner,
          onAddFolder: _addFolder,
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: _postContent()),
      ],
    );
  }

  /// 핸드폰(좁은 폭): 상단 가로 폴더 칩 바 + 전체 폭 목록.
  /// 고정 220px 폴더 패널을 쓰면 목록이 짓눌려 사실상 못 쓰게 되므로 분리한다.
  Widget _buildCompactBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FolderChipsBar(
          folders: _folders,
          selectedFolderIdx: _selectedFolderIdx,
          onSelect: _onSelectFolder,
          canManageFolders: _canUpdate && !_isFranchiseOwner,
          onAddFolder: _addFolder,
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(child: _postContent()),
      ],
    );
  }

  Future<void> _addFolder() async {
    final result =
        await showDialog<({String name, bool ownerView, bool staffView})>(
          context: context,
          builder: (ctx) => const _FolderCreateDialog(),
        );
    if (result == null || result.name.isEmpty) return;
    final created = await _api.createFolder(
      userId: _userId,
      folderNm: result.name,
      ownerView: result.ownerView,
      staffView: result.staffView,
    );
    if (created != null) await _reload();
  }
}

class _FolderCreateDialog extends StatefulWidget {
  const _FolderCreateDialog();

  @override
  State<_FolderCreateDialog> createState() => _FolderCreateDialogState();
}

class _FolderCreateDialogState extends State<_FolderCreateDialog> {
  final _ctrl = TextEditingController();
  bool _ownerView = true;
  bool _staffView = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('폴더 추가'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: '폴더명',
                hintText: '폴더명 입력',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '조회 권한',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('가맹점주'),
              value: _ownerView,
              onChanged: (v) => setState(() => _ownerView = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('사원'),
              value: _staffView,
              onChanged: (v) => setState(() => _staffView = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            if (!_ownerView && !_staffView) return;
            Navigator.pop(context, (
              name: _ctrl.text.trim(),
              ownerView: _ownerView,
              staffView: _staffView,
            ));
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}

class _FolderPanel extends StatelessWidget {
  const _FolderPanel({
    required this.folders,
    required this.selectedFolderIdx,
    required this.onSelect,
    required this.canManageFolders,
    required this.onAddFolder,
  });

  final List<BoardFolder> folders;
  final int? selectedFolderIdx;
  final ValueChanged<int?> onSelect;
  final bool canManageFolders;
  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: ColoredBox(
        color: const Color(0xFFFAFAFA),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                '게시판',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
            _FolderTile(
              label: '전체',
              count: folders.fold<int>(0, (s, f) => s + f.postCount),
              selected: selectedFolderIdx == null,
              onTap: () => onSelect(null),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: folders.length,
                itemBuilder: (_, i) {
                  final f = folders[i];
                  return _FolderTile(
                    label: f.folderNm,
                    subtitle: canManageFolders
                        ? _folderVisibilityLabel(f)
                        : null,
                    count: f.postCount,
                    selected: selectedFolderIdx == f.folderIdx,
                    onTap: () => onSelect(f.folderIdx),
                  );
                },
              ),
            ),
            if (canManageFolders)
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: onAddFolder,
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  label: const Text('폴더 추가'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 핸드폰(컴팩트)용 가로 스크롤 폴더 선택 바. ('전체' + 폴더별 칩 + 폴더 추가)
class _FolderChipsBar extends StatelessWidget {
  const _FolderChipsBar({
    required this.folders,
    required this.selectedFolderIdx,
    required this.onSelect,
    required this.canManageFolders,
    required this.onAddFolder,
  });

  final List<BoardFolder> folders;
  final int? selectedFolderIdx;
  final ValueChanged<int?> onSelect;
  final bool canManageFolders;
  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context) {
    final totalCount = folders.fold<int>(0, (s, f) => s + f.postCount);
    return ColoredBox(
      color: const Color(0xFFFAFAFA),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _FolderChip(
              label: '전체',
              count: totalCount,
              selected: selectedFolderIdx == null,
              onTap: () => onSelect(null),
            ),
            for (final f in folders) ...[
              const SizedBox(width: 8),
              _FolderChip(
                label: f.folderNm,
                count: f.postCount,
                selected: selectedFolderIdx == f.folderIdx,
                onTap: () => onSelect(f.folderIdx),
              ),
            ],
            if (canManageFolders) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onAddFolder,
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: const Text('폴더 추가'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color.fromARGB(255, 158, 0, 0) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color.fromARGB(255, 158, 0, 0)
                  : FormStylePalette.panelBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_outlined,
                size: 16,
                color: selected ? Colors.white : FormStylePalette.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : AppTheme.textPrimary,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? Colors.white70
                      : FormStylePalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _folderVisibilityLabel(BoardFolder folder) {
  if (folder.allowsOwner && folder.allowsStaff) return '가맹점주·사원';
  if (folder.allowsOwner) return '가맹점주';
  if (folder.allowsStaff) return '사원';
  return null;
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.label,
    this.subtitle,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color.fromARGB(255, 158, 0, 0)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 18,
                color: selected ? Colors.white : FormStylePalette.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? Colors.white : AppTheme.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? Colors.white70
                              : FormStylePalette.textSecondary,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? Colors.white70
                      : FormStylePalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostListPanel extends StatelessWidget {
  const _PostListPanel({
    required this.searchCtrl,
    required this.posts,
    required this.totalCount,
    required this.page,
    required this.totalPages,
    required this.userId,
    required this.api,
    required this.onSearch,
    required this.onPage,
    required this.onRefresh,
    required this.onWrite,
    required this.onOpen,
  });

  final TextEditingController searchCtrl;
  final List<BoardPost> posts;
  final int totalCount;
  final int page;
  final int totalPages;
  final String userId;
  final Bbs001ApiService api;
  final ValueChanged<String> onSearch;
  final ValueChanged<int> onPage;
  final VoidCallback onRefresh;
  final VoidCallback? onWrite;
  final ValueChanged<BoardPost> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '게시글',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '새로고침',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SearchFilterTextField(
            controller: searchCtrl,
            hint: '제목·내용·작성자 검색',
            borderRadius: 8,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey.shade500,
              size: 22,
            ),
            onChanged: onSearch,
          ),
          const SizedBox(height: 12),
          Text(
            '총 $totalCount건',
            style: const TextStyle(
              fontSize: 13,
              color: FormStylePalette.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: posts.isEmpty
                    ? const Center(child: Text('게시글이 없습니다.'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // 좁은 화면에서 제목이 잘리지 않도록 최소 너비를 보장하고,
                          // 그보다 좁으면 가로 스크롤로 전체 행을 볼 수 있게 한다.
                          const minWidth = 640.0;
                          final rowWidth = constraints.maxWidth > minWidth
                              ? constraints.maxWidth
                              : minWidth;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: rowWidth,
                              child: ListView.builder(
                                itemCount: posts.length,
                                itemBuilder: (_, i) {
                                  final p = posts[i];
                                  final no =
                                      page * _BoardViewState._pageSize + i + 1;
                                  return _PostRow(
                                    post: p,
                                    no: no,
                                    even: i.isEven,
                                    userId: userId,
                                    api: api,
                                    onTap: () => onOpen(p),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Pagination(page: page, totalPages: totalPages, onPage: onPage),
              const Spacer(),
              if (onWrite != null)
                FilledButton.icon(
                  onPressed: onWrite,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('글쓰기'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostRow extends StatelessWidget {
  const _PostRow({
    required this.post,
    required this.no,
    required this.even,
    required this.userId,
    required this.api,
    required this.onTap,
  });

  final BoardPost post;
  final int no;
  final bool even;
  final String userId;
  final Bbs001ApiService api;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: even ? AppTheme.tableRowOdd : AppTheme.tableRowEven,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '$no',
                  textAlign: TextAlign.center,
                  style: kSearchFilterValueTextStyle,
                ),
              ),
              // SizedBox(
              //   width: 56,
              //   height: 56,
              //   child: post.hasImageThumb
              //       ? BoardListThumb(
              //           postIdx: post.postIdx,
              //           thumbDocIdx: post.thumbDocIdx!,
              //           api: api,
              //           userId: userId,
              //         )
              //       : DecoratedBox(
              //           decoration: BoxDecoration(
              //             color: const Color(0xFFF3F4F6),
              //             borderRadius: BorderRadius.circular(8),
              //             border: Border.all(color: const Color(0xFFE5E7EB)),
              //           ),
              //           child: Icon(
              //             post.hasAttachment
              //                 ? Icons.attach_file
              //                 : Icons.article_outlined,
              //             color: FormStylePalette.textSecondary,
              //           ),
              //         ),
              // ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (post.isNotice)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentRed.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '공지',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.accentRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (post.isPrivate)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: FormStylePalette.textSecondary,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            post.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.bodyTxt.isEmpty ? post.folderNm : post.bodyTxt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: FormStylePalette.textSecondary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  post.authorNm.isEmpty ? '-' : post.authorNm,
                  textAlign: TextAlign.center,
                  style: kSearchFilterValueTextStyle,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  post.createdAtLabel,
                  textAlign: TextAlign.center,
                  style: kSearchFilterValueTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: page > 0 ? () => onPage(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        for (var i = 0; i < totalPages && i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: TextButton(
              onPressed: () => onPage(i),
              style: TextButton.styleFrom(
                foregroundColor: i == page
                    ? AppTheme.accentRed
                    : AppTheme.textPrimary,
                backgroundColor: i == page
                    ? AppTheme.accentRed.withValues(alpha: 0.08)
                    : null,
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
              child: Text('${i + 1}'),
            ),
          ),
        IconButton(
          onPressed: page < totalPages - 1 ? () => onPage(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _BoardPostDetailDialog extends StatefulWidget {
  const _BoardPostDetailDialog({
    required this.post,
    required this.userId,
    required this.api,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final BoardPost post;
  final String userId;
  final Bbs001ApiService api;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_BoardPostDetailDialog> createState() => _BoardPostDetailDialogState();
}

class _BoardPostDetailDialogState extends State<_BoardPostDetailDialog> {
  List<BoardDocument> _docs = const [];
  bool _loadingDocs = true;

  /// 본문이 리치(Quill Delta)면 읽기 전용 렌더링용 컨트롤러.
  QuillController? _viewQuill;

  @override
  void initState() {
    super.initState();
    if (boardBodyIsQuillDelta(widget.post.bodyTxt)) {
      _viewQuill = QuillController(
        document: boardBodyToDocument(widget.post.bodyTxt),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    }
    _loadDocs();
  }

  @override
  void dispose() {
    _viewQuill?.dispose();
    super.dispose();
  }

  Future<void> _loadDocs() async {
    final docs = await widget.api.getDocuments(
      postIdx: widget.post.postIdx,
      userId: widget.userId,
    );
    if (mounted) {
      setState(() {
        _docs = docs;
        _loadingDocs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final imageDocs = _docs.where((d) => d.isImage).toList(growable: false);
    final fileDocs = _docs.where((d) => !d.isImage).toList(growable: false);
    final body = BoardRichBody.parse(p.bodyTxt);

    void openGallery(int docIdx) {
      final idx = imageDocs.indexWhere((d) => d.bbsDocIdx == docIdx);
      showBoardImageGallery(
        context: context,
        api: widget.api,
        userId: widget.userId,
        postIdx: p.postIdx,
        images: [
          for (final d in imageDocs)
            (bbsDocIdx: d.bbsDocIdx, fileName: d.fileName),
        ],
        initialIndex: idx < 0 ? 0 : idx,
      );
    }

    final size = MediaQuery.sizeOf(context);
    final compactReading = size.width < 720;

    // 본문 위젯(리치/구형 텍스트 분기) — 데이터 로직은 기존 그대로.
    Widget bodyContent;
    if (_viewQuill != null) {
      bodyContent = QuillEditor.basic(
        controller: _viewQuill!,
        config: QuillEditorConfig(
          scrollable: false,
          showCursor: false,
          padding: EdgeInsets.zero,
          embedBuilders: [BoardImageEmbedBuilder()],
        ),
      );
    } else if (_loadingDocs) {
      bodyContent = const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(),
      );
    } else if (body.isRich) {
      bodyContent = BoardRichBodyView(
        body: body,
        postIdx: p.postIdx,
        api: widget.api,
        userId: widget.userId,
        onTapImage: openGallery,
      );
    } else {
      bodyContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageDocs.isNotEmpty) ...[
            for (var i = 0; i < imageDocs.length; i++)
              BoardInlineImage(
                postIdx: p.postIdx,
                bbsDocIdx: imageDocs[i].bbsDocIdx,
                fileName: imageDocs[i].fileName,
                api: widget.api,
                userId: widget.userId,
                onTap: () => openGallery(imageDocs[i].bbsDocIdx),
              ),
            const SizedBox(height: 16),
          ],
          Text(
            p.bodyTxt.isEmpty ? '(내용 없음)' : p.bodyTxt,
            style: TextStyle(
              fontSize: compactReading ? 13.5 : 14.5,
              height: compactReading ? 1.8 : 1.85,
              color: AppTheme.textPrimary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ],
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compactReading ? 0 : 28,
        vertical: compactReading ? 0 : 28,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compactReading ? 0 : 14),
        side: compactReading
            ? BorderSide.none
            : const BorderSide(color: AppTheme.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compactReading ? double.infinity : 1040,
          maxHeight: compactReading ? double.infinity : size.height - 72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _readingTopBar(context, p),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compactReading ? 18 : 40,
                  compactReading ? 20 : 32,
                  compactReading ? 18 : 40,
                  compactReading ? 28 : 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    // 본문 컬럼 폭 ~760px — 리딩 가독성 핵심(CHANGES_턴7 §3).
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _badgeRow(p),
                        const SizedBox(height: 14),
                        Text(
                          p.title,
                          style: TextStyle(
                            fontSize: compactReading ? 20 : 27,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            height: 1.3,
                            color: AppTheme.textPrimary,
                            fontFamilyFallback: AppTheme.koreanFontFallback,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _metaRow(p),
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 22),
                        bodyContent,
                        if (!_loadingDocs && fileDocs.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            '첨부파일 ${fileDocs.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final d in fileDocs) ...[
                            _attachmentCard(d),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상단 바 — breadcrumb(게시판 / 폴더) + 수정·삭제·닫기.
  Widget _readingTopBar(BuildContext context, BoardPost p) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
      child: Row(
        children: [
          const Text(
            '게시판',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          if (p.folderNm.trim().isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '/',
                style: TextStyle(fontSize: 12, color: AppTheme.textPlaceholder),
              ),
            ),
            Flexible(
              child: Text(
                p.folderNm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (widget.canEdit)
            TextButton(
              onPressed: widget.onEdit,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('수정'),
            ),
          if (widget.canDelete)
            TextButton(
              onPressed: widget.onDelete,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('삭제'),
            ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppTheme.textMuted,
            tooltip: '닫기',
          ),
        ],
      ),
    );
  }

  /// 배지 행 — 공지(레드) · 비공개(자물쇠) · 폴더 · 매장.
  Widget _badgeRow(BoardPost p) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (p.isNotice) const StatusBadge('공지', color: AppTheme.accentRed),
        if (p.isPrivate)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.chipNeutralBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 11, color: AppTheme.textMuted),
                SizedBox(width: 4),
                Text(
                  '비공개',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ],
            ),
          ),
        if (p.folderNm.trim().isNotEmpty)
          StatusBadge(
            p.folderNm,
            showDot: false,
            color: AppTheme.textSecondary,
          ),
        if (p.storeNm.trim().isNotEmpty)
          StatusBadge(
            p.storeNm,
            showDot: false,
            color: AppTheme.statusRenewal,
          ),
      ],
    );
  }

  /// 메타 행 — 작성자 아바타 + 이름 + 작성일 + 조회수.
  Widget _metaRow(BoardPost p) {
    final initial = p.authorNm.trim().isEmpty ? '?' : p.authorNm.trim()[0];
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: AppTheme.textPrimary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: p.authorNm,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: '  ·  ${p.createdAtLabel}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        const Icon(
          Icons.visibility_outlined,
          size: 14,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          '${p.viewCnt}',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontFeatures: [FontFeature.tabularFigures()],
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ],
    );
  }

  /// 첨부 파일카드 — 타입 아이콘(이미지=보라/문서=파랑) + 파일명 + 형식·용량.
  Widget _attachmentCard(BoardDocument d) {
    final tint = d.isImage ? AppTheme.statusTransfer : AppTheme.statusRenewal;
    final ext = d.fileName.contains('.')
        ? d.fileName.split('.').last.toUpperCase()
        : '파일';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              d.isImage ? Icons.image_outlined : Icons.description_outlined,
              size: 17,
              color: tint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$ext · ${_fileSizeLabel(d.fileSize)}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textMuted,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fileSizeLabel(int bytes) {
    if (bytes <= 0) return '-';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
