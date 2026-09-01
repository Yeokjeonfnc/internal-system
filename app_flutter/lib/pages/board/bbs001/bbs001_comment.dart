// 게시글 상세 하단 댓글 — 목록·등록·본인(또는 삭제 권한) 삭제.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_api.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_model.dart';

class BoardCommentSection extends StatefulWidget {
  const BoardCommentSection({
    super.key,
    required this.postIdx,
    required this.userId,
    required this.api,
    required this.canDeleteAny,
  });

  final int postIdx;
  final String userId;
  final Bbs001ApiService api;
  final bool canDeleteAny;

  @override
  State<BoardCommentSection> createState() => _BoardCommentSectionState();
}

class _BoardCommentSectionState extends State<BoardCommentSection> {
  final _ctrl = TextEditingController();
  List<BoardComment> _rows = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await widget.api.getComments(
      postIdx: widget.postIdx,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    final created = await widget.api.createComment(
      postIdx: widget.postIdx,
      userId: widget.userId,
      bodyTxt: text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (created == null) {
      await showAlertDialog(context, '댓글을 등록하지 못했습니다.');
      return;
    }
    _ctrl.clear();
    setState(() => _rows = [..._rows, created]);
  }

  Future<void> _delete(BoardComment row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final deleted = await widget.api.deleteComment(
      postIdx: widget.postIdx,
      commentIdx: row.commentIdx,
      userId: widget.userId,
    );
    if (!mounted) return;
    if (!deleted) {
      await showAlertDialog(context, '댓글 삭제에 실패했습니다.');
      return;
    }
    setState(() {
      _rows = _rows.where((e) => e.commentIdx != row.commentIdx).toList();
    });
  }

  bool _isMine(BoardComment row) =>
      row.createdBy.trim().toLowerCase() == widget.userId.trim().toLowerCase();

  bool _canDelete(BoardComment row) => _isMine(row) || widget.canDeleteAny;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Divider(height: 1),
        const SizedBox(height: 20),
        Text(
          '댓글 ${_loading ? '' : _rows.length}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '첫 댓글을 남겨 보세요.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          )
        else
          for (final row in _rows) _CommentTile(
            row: row,
            canDelete: _canDelete(row),
            onDelete: () => _delete(row),
          ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                enabled: !_saving,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요',
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F7F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.accentRed),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(64, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text(_saving ? '등록 중' : '등록'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.row,
    required this.canDelete,
    required this.onDelete,
  });

  final BoardComment row;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final initial = row.authorNm.trim().isEmpty
        ? '?'
        : String.fromCharCode(row.authorNm.trim().runes.first);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.chipNeutralBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        row.authorNm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      row.createdAtLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  row.bodyTxt,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: AppTheme.textPrimary,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            height: 40,
            child: canDelete
                ? TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMuted,
                      minimumSize: const Size(64, 40),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('삭제', style: TextStyle(fontSize: 13)),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
