import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/file/picked_store_document_file.dart';
import 'package:app_flutter/core/file/store_document_file_picker.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_api.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_model.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_quill.dart';

/// 게시글 등록·수정 다이얼로그. 저장 성공 시 `true`.
Future<bool?> showBoardPostEditorDialog(
  BuildContext context, {
  required List<BoardFolder> folders,
  required int? initialFolderIdx,
  BoardPost? post,
  required bool canSetNotice,
  required bool canEdit,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _BoardPostEditorDialog(
      folders: folders,
      initialFolderIdx: initialFolderIdx,
      post: post,
      canSetNotice: canSetNotice,
      canEdit: canEdit,
    ),
  );
}

class _BoardPostEditorDialog extends StatefulWidget {
  const _BoardPostEditorDialog({
    required this.folders,
    required this.initialFolderIdx,
    required this.post,
    required this.canSetNotice,
    required this.canEdit,
  });

  final List<BoardFolder> folders;
  final int? initialFolderIdx;
  final BoardPost? post;
  final bool canSetNotice;
  final bool canEdit;

  @override
  State<_BoardPostEditorDialog> createState() => _BoardPostEditorDialogState();
}

class _BoardPostEditorDialogState extends State<_BoardPostEditorDialog> {
  final _api = Bbs001ApiService();
  final _titleCtrl = TextEditingController();
  late final QuillController _quill;
  final _editorFocus = FocusNode();
  final _editorScroll = ScrollController();

  late int? _folderIdx;
  bool _privateYn = false;
  bool _noticeYn = false;
  bool _saving = false;
  bool _loadingDocs = false;

  /// 사진이 아닌 일반 첨부.
  final List<BoardDocument> _existingDocs = [];
  final List<PickedStoreDocumentFile> _pendingFiles = [];

  bool get _isEdit => widget.post != null;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _titleCtrl.text = p?.title ?? '';
    _folderIdx = p?.folderIdx ?? widget.initialFolderIdx;
    _privateYn = p?.isPrivate ?? false;
    _noticeYn = p?.isNotice ?? false;

    _quill = QuillController(
      document: p == null ? Document() : boardBodyToDocument(p.bodyTxt),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: !widget.canEdit,
    );

    if (_isEdit) _loadDocs();
  }

  Future<void> _loadDocs() async {
    setState(() => _loadingDocs = true);
    final userId = context.read<AuthProvider>().userId;
    final docs = await _api.getDocuments(
      postIdx: widget.post!.postIdx,
      userId: userId,
    );
    if (!mounted) return;
    setState(() {
      _existingDocs
        ..clear()
        ..addAll(docs);
      _loadingDocs = false;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _quill.dispose();
    _editorFocus.dispose();
    _editorScroll.dispose();
    super.dispose();
  }

  /// 커서 위치에 사진을 끼워 넣는다(이미지가 아니면 일반 첨부로).
  Future<void> _insertImageAtCursor() async {
    final picked = await pickStoreDocumentFiles();
    if (picked.isEmpty || !mounted) return;
    for (final f in picked) {
      if (boardDocumentIsImage(f.name, '')) {
        final dataUri = await encodeImageToDataUri(f.bytes);
        final sel = _quill.selection;
        final docLen = _quill.document.length;
        var index = sel.baseOffset;
        if (index < 0 || index > docLen) index = docLen > 0 ? docLen - 1 : 0;
        final length =
            (sel.extentOffset - sel.baseOffset).clamp(0, docLen).toInt();
        // 사진을 자기 줄에 두기 위해 줄바꿈 사이에 임베드를 끼운다.
        _quill
          ..replaceText(
            index,
            length,
            '\n',
            TextSelection.collapsed(offset: index + 1),
          )
          ..replaceText(
            index + 1,
            0,
            BlockEmbed.custom(
              BoardImageEmbed.create(dataUri: dataUri, width: 0.5),
            ),
            TextSelection.collapsed(offset: index + 2),
          )
          ..replaceText(
            index + 2,
            0,
            '\n',
            TextSelection.collapsed(offset: index + 3),
          );
      } else {
        setState(() => _pendingFiles.add(f));
      }
    }
  }

  Future<void> _save() async {
    if (_saving || !widget.canEdit) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      await showAlertDialog(context, '제목을 입력해 주세요.');
      return;
    }
    if (_folderIdx == null) {
      await showAlertDialog(context, '폴더를 선택해 주세요.');
      return;
    }
    final userId = context.read<AuthProvider>().userId;
    setState(() => _saving = true);
    try {
      final body = _buildSaveBody(
        title: title,
        bodyTxt: boardDocumentToBody(_quill.document),
      );

      int? postIdx = widget.post?.postIdx;
      if (postIdx == null) {
        final created = await _api.createPost(userId: userId, body: body);
        if (created == null) {
          if (mounted) await showAlertDialog(context, '저장에 실패했습니다.');
          return;
        }
        postIdx = created.postIdx;
      } else {
        final updated = await _api.updatePost(
          postIdx: postIdx,
          userId: userId,
          body: body,
        );
        if (updated == null) {
          if (mounted) await showAlertDialog(context, '저장에 실패했습니다.');
          return;
        }
      }

      var uploadFailed = 0;
      for (final f in _pendingFiles) {
        final uploaded = await _api.uploadDocument(
          postIdx: postIdx,
          userId: userId,
          fileName: f.name,
          bytes: f.bytes,
        );
        if (uploaded == null) uploadFailed++;
      }

      if (!mounted) return;
      if (uploadFailed > 0) {
        await showAlertDialog(
          context,
          '게시글은 저장됐지만 첨부 $uploadFailed건 업로드에 실패했습니다.',
        );
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic> _buildSaveBody({
    required String title,
    required String bodyTxt,
  }) {
    return BoardPost(
      postIdx: widget.post?.postIdx ?? 0,
      folderIdx: _folderIdx!,
      folderNm: '',
      title: title,
      bodyTxt: bodyTxt,
      privateYn: _privateYn ? 'Y' : 'N',
      noticeYn: _noticeYn ? 'Y' : 'N',
      viewCnt: 0,
      authorNm: '',
      createdBy: '',
      createdAtRaw: '',
      hasAttachment: false,
    ).toSaveBody(
      folderIdx: _folderIdx!,
      privateYn: _privateYn,
      noticeYn: widget.canSetNotice && _noticeYn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogW = (size.width - 48).clamp(720.0, 1200.0);
    final dialogH = (size.height - 48).clamp(560.0, 900.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: dialogW,
        height: dialogH,
        child: ErpDialogFrame(
          title: _isEdit ? '게시글 수정' : '게시글 등록',
          maxWidth: dialogW,
          maxHeight: dialogH,
          onClose: _saving ? null : () => Navigator.pop(context),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _folderIdx,
                decoration: InputDecoration(
                  labelText: '폴더',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  for (final f in widget.folders)
                    DropdownMenuItem(
                      value: f.folderIdx,
                      child: Text(f.folderNm),
                    ),
                ],
                onChanged: widget.canEdit
                    ? (v) => setState(() => _folderIdx = v)
                    : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                readOnly: !widget.canEdit,
                decoration: InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.canEdit)
                QuillSimpleToolbar(
                  controller: _quill,
                  config: QuillSimpleToolbarConfig(
                    multiRowsDisplay: false,
                    showFontFamily: false,
                    showFontSize: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showSearchButton: false,
                    showCodeBlock: false,
                    showInlineCode: false,
                    showQuote: false,
                    showIndent: false,
                    showLink: false,
                    customButtons: [
                      QuillToolbarCustomButtonOptions(
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        tooltip: '사진 삽입',
                        onPressed: _insertImageAtCursor,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: QuillEditor.basic(
                    controller: _quill,
                    focusNode: _editorFocus,
                    scrollController: _editorScroll,
                    config: QuillEditorConfig(
                      placeholder: '내용을 입력하세요. 사진은 상단 사진 버튼으로 삽입합니다.',
                      padding: EdgeInsets.zero,
                      embedBuilders: [BoardImageEmbedBuilder()],
                    ),
                  ),
                ),
              ),
              _buildFileAttachments(context),
              const SizedBox(height: 4),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('비공개'),
                value: _privateYn,
                onChanged: widget.canEdit
                    ? (v) => setState(() => _privateYn = v ?? false)
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              if (widget.canSetNotice)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('공지'),
                  value: _noticeYn,
                  onChanged: widget.canEdit
                      ? (v) => setState(() => _noticeYn = v ?? false)
                      : null,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.canEdit)
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _insertImageAtCursor,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text('파일 첨부'),
                    ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                      side: const BorderSide(color: AppTheme.accentRed),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  if (widget.canEdit)
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('저장'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileAttachments(BuildContext context) {
    final userId = context.read<AuthProvider>().userId;
    if (_loadingDocs) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (_existingDocs.isEmpty && _pendingFiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 110),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text('첨부파일', style: TextStyle(fontWeight: FontWeight.w600)),
            for (final d in _existingDocs)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  d.isImage ? Icons.image_outlined : Icons.attach_file,
                ),
                title: Text(d.fileName),
                trailing: widget.canEdit
                    ? IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.accentRed,
                        ),
                        onPressed: () async {
                          await _api.deleteDocument(
                            postIdx: widget.post!.postIdx,
                            bbsDocIdx: d.bbsDocIdx,
                            userId: userId,
                          );
                          setState(() => _existingDocs.remove(d));
                        },
                      )
                    : null,
              ),
            for (final f in _pendingFiles)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file),
                title: Text(f.name),
                trailing: widget.canEdit
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _pendingFiles.remove(f)),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
