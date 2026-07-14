// 메신저 채팅방 패널 — 사진의 오른쪽 화면(말풍선 + 입력창)에 해당.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/chat/chat_model.dart';
import 'package:app_flutter/core/chat/chat_providers.dart';
import 'package:app_flutter/core/file/store_document_file_picker.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/messenger/msg001/msg001_widgets.dart';

class Msg001ChatRoom extends ConsumerStatefulWidget {
  const Msg001ChatRoom({
    super.key,
    required this.roomId,
    required this.currentUserId,
    this.onBack,
    this.onDeleted,
  });

  final String roomId;
  final String currentUserId;

  /// 모바일(단일 페이지) 모드에서 뒤로가기. 데스크톱에선 null.
  final VoidCallback? onBack;

  /// 대화방을 삭제(숨김)했을 때 호출 — 선택 해제 등에 사용.
  final VoidCallback? onDeleted;

  @override
  ConsumerState<Msg001ChatRoom> createState() => _Msg001ChatRoomState();
}

class _Msg001ChatRoomState extends ConsumerState<Msg001ChatRoom> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _inputFocus = FocusNode();
  bool _uploading = false;

  /// 답장 대상 메시지(있으면 입력창 위에 인용 배너 노출).
  ChatMessage? _replyTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatServiceProvider).markRead(widget.roomId);
    });
  }

  @override
  void didUpdateWidget(covariant Msg001ChatRoom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      ref.read(chatServiceProvider).markRead(widget.roomId);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    final reply = _replyTo;
    final outgoing = reply == null ? text : _composeReply(reply, text);
    _input.clear();
    if (reply != null) setState(() => _replyTo = null);
    await ref.read(chatServiceProvider).sendMessage(widget.roomId, outgoing);
    _inputFocus.requestFocus();
  }

  /// 답장 전송 텍스트 — 원문 인용 한 줄을 앞에 붙인다(백엔드 인용 스키마 없이 동작).
  String _composeReply(ChatMessage src, String text) {
    final who = src.senderName.trim().isNotEmpty
        ? src.senderName.trim()
        : '메시지';
    final snippet = _previewText(src);
    final quoted = snippet.length > 40
        ? '${snippet.substring(0, 40)}…'
        : snippet;
    return '↪ $who: $quoted\n$text';
  }

  /// 메시지를 한 줄로 요약(목록·인용용).
  String _previewText(ChatMessage msg) {
    switch (msg.type) {
      case ChatMessageType.image:
        return '사진';
      case ChatMessageType.file:
        return msg.fileName ?? '파일';
      default:
        return msg.text;
    }
  }

  /// 복사 가능한 텍스트(없으면 null → 복사 메뉴 숨김).
  String? _copyableText(ChatMessage msg) {
    if (msg.text.trim().isNotEmpty) return msg.text;
    if (msg.type == ChatMessageType.file) return msg.fileName;
    return null;
  }

  /// 말풍선 위 우클릭·롱프레스 → 답장/복사/삭제 메뉴.
  Future<void> _showMessageMenu(ChatMessage msg, Offset globalPos) async {
    if (msg.type == ChatMessageType.system || msg.isDeleted) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(globalPos, globalPos),
      Offset.zero & overlay.size,
    );
    final mine = msg.isMine(widget.currentUserId);
    final copyable = _copyableText(msg);
    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(
          value: 'reply',
          child: _MenuRow(icon: Icons.reply, label: '답장'),
        ),
        if (copyable != null)
          const PopupMenuItem<String>(
            value: 'copy',
            child: _MenuRow(icon: Icons.content_copy, label: '복사'),
          ),
        if (mine)
          const PopupMenuItem<String>(
            value: 'delete',
            child: _MenuRow(
              icon: Icons.delete_outline,
              label: '삭제',
              danger: true,
            ),
          ),
      ],
    );
    if (!mounted || selected == null) return;
    switch (selected) {
      case 'reply':
        setState(() => _replyTo = msg);
        _inputFocus.requestFocus();
        break;
      case 'copy':
        if (copyable != null) {
          await Clipboard.setData(ClipboardData(text: copyable));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('복사했습니다.'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
        break;
      case 'delete':
        await _confirmDeleteMessage(msg);
        break;
    }
  }

  Future<void> _confirmDeleteMessage(ChatMessage msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 삭제할까요?\n모든 대화 참여자에게서 사라집니다.'),
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
    if (ok != true) return;
    try {
      await ref.read(chatServiceProvider).deleteMessage(widget.roomId, msg.id);
      if (mounted && _replyTo?.id == msg.id) {
        setState(() => _replyTo = null);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('메시지 삭제에 실패했습니다.')));
      }
    }
  }

  Future<void> _confirmDelete(ChatRoom? room) async {
    final title = room?.displayTitle(widget.currentUserId) ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('대화방 삭제'),
        content: Text(
          "${title.isEmpty ? '이' : "'$title'"} 대화방을 목록에서 삭제할까요?\n"
          '새 메시지가 오면 다시 나타납니다.',
        ),
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
    if (ok != true) return;
    try {
      await ref.read(chatServiceProvider).hideRoom(widget.roomId);
      widget.onDeleted?.call();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('대화방 삭제에 실패했습니다.')));
      }
    }
  }

  Future<void> _pickAttachment() async {
    if (_uploading) return;
    final file = await pickStoreDocumentFile();
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      await ref
          .read(chatServiceProvider)
          .sendAttachment(
            widget.roomId,
            fileName: file.name,
            bytes: file.bytes,
            contentType: guessAttachmentContentType(file.name),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('첨부 전송 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.roomId));
    final rooms =
        ref.watch(chatRoomsProvider).valueOrNull ?? const <ChatRoom>[];
    final room = rooms
        .where((r) => r.id == widget.roomId)
        .cast<ChatRoom?>()
        .firstWhere((r) => true, orElse: () => null);

    // 새 메시지가 오면 읽음 처리 + 맨 아래로 스크롤.
    ref.listen(chatMessagesProvider(widget.roomId), (_, _) {
      ref.read(chatServiceProvider).markRead(widget.roomId);
      _scrollToBottom();
    });

    return Column(
      children: [
        _ChatHeader(
          room: room,
          currentUserId: widget.currentUserId,
          onBack: widget.onBack,
          onDelete: () => _confirmDelete(room),
        ),
        const Divider(height: 1, color: Color(0xFFECECEC)),
        Expanded(
          child: ColoredBox(
            color: AppTheme.appSurface,
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('불러오기 실패: $e')),
              data: (messages) {
                _scrollToBottom();
                if (messages.isEmpty) {
                  return const _EmptyConversation();
                }
                return _MessageList(
                  controller: _scroll,
                  messages: messages,
                  currentUserId: widget.currentUserId,
                  isGroup: room?.isGroup ?? false,
                  attachmentUrlOf: ref.read(chatServiceProvider).attachmentUrl,
                  onMenu: _showMessageMenu,
                );
              },
            ),
          ),
        ),
        if (_replyTo != null)
          _ReplyComposeBanner(
            preview: _previewText(_replyTo!),
            senderName: _replyTo!.senderName,
            onCancel: () => setState(() => _replyTo = null),
          ),
        _InputBar(
          controller: _input,
          focusNode: _inputFocus,
          onSend: _send,
          onAttach: _pickAttachment,
          uploading: _uploading,
        ),
      ],
    );
  }
}

/// 컨텍스트 메뉴 한 줄(아이콘 + 라벨). [danger] 면 빨간색(삭제).
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.accentRed : const Color(0xFF495057);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }
}

/// 입력창 위 답장 인용 배너 — 답장 중인 원문을 보여주고 취소(X) 제공.
class _ReplyComposeBanner extends StatelessWidget {
  const _ReplyComposeBanner({
    required this.preview,
    required this.senderName,
    required this.onCancel,
  });

  final String preview;
  final String senderName;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final who = senderName.trim().isNotEmpty ? senderName.trim() : '메시지';
    return Container(
      color: const Color(0xFFF1ECE9),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.accentRed,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$who에게 답장',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B6560),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '답장 취소',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF868E96)),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.room,
    required this.currentUserId,
    this.onBack,
    this.onDelete,
  });

  final ChatRoom? room;
  final String currentUserId;
  final VoidCallback? onBack;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final title = room?.displayTitle(currentUserId) ?? '';
    final subtitle = room == null
        ? ''
        : room!.isGroup
        ? '멤버 ${room!.members.length}명'
        : (room!.others(currentUserId).isNotEmpty
              ? room!.others(currentUserId).first.deptNm
              : '');
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white,
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Color(0xFF495057)),
            ),
          ChatAvatar(name: title, isGroup: room?.isGroup ?? false, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212529),
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFADB5BD),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: '대화 검색',
            onPressed: () {},
            icon: const Icon(Icons.search, color: Color(0xFFADB5BD)),
          ),
          PopupMenuButton<String>(
            tooltip: '더보기',
            icon: const Icon(Icons.menu, color: Color(0xFFADB5BD)),
            position: PopupMenuPosition.under,
            onSelected: (value) {
              if (value == 'delete') onDelete?.call();
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTheme.accentRed,
                    ),
                    SizedBox(width: 8),
                    Text('삭제하기'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.controller,
    required this.messages,
    required this.currentUserId,
    required this.isGroup,
    required this.attachmentUrlOf,
    required this.onMenu,
  });

  final ScrollController controller;
  final List<ChatMessage> messages;
  final String currentUserId;
  final bool isGroup;
  final String? Function(ChatMessage) attachmentUrlOf;

  /// 말풍선 우클릭·롱프레스 시 (메시지, 전역좌표)로 메뉴를 띄운다.
  final void Function(ChatMessage, Offset) onMenu;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        if (msg.type == ChatMessageType.system) {
          return _SystemLine(text: msg.text);
        }
        final prev = i > 0 ? messages[i - 1] : null;
        final showDateDivider =
            prev == null || !isSameDay(prev.sentAt, msg.sentAt);
        final mine = msg.isMine(currentUserId);
        // 그룹방에서 상대 메시지는 발신자가 바뀔 때만 이름/아바타 표시.
        final showSender =
            isGroup &&
            !mine &&
            (prev == null ||
                prev.senderId != msg.senderId ||
                prev.type == ChatMessageType.system ||
                showDateDivider);
        return Column(
          children: [
            if (showDateDivider) _DateDivider(time: msg.sentAt),
            _Bubble(
              message: msg,
              mine: mine,
              showSender: showSender,
              showAvatar: isGroup && !mine,
              attachmentUrl: attachmentUrlOf(msg),
              onMenu: (pos) => onMenu(msg, pos),
            ),
          ],
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.showSender,
    required this.showAvatar,
    this.attachmentUrl,
    this.onMenu,
  });

  final ChatMessage message;
  final bool mine;
  final bool showSender;
  final bool showAvatar;
  final String? attachmentUrl;

  /// 우클릭(데스크톱)·롱프레스(모바일) 시 전역좌표로 메뉴 호출.
  final void Function(Offset globalPosition)? onMenu;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.62;
    final time = Text(
      formatBubbleTime(message.sentAt),
      style: const TextStyle(fontSize: 10.5, color: Color(0xFFADB5BD)),
    );

    final deleted = message.isDeleted;
    final isImage = !deleted && message.type == ChatMessageType.image;
    final Widget bubble = Container(
      constraints: BoxConstraints(maxWidth: maxW.clamp(180, 460)),
      padding: isImage
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        // 내 메시지 = 브랜드 레드 단색 / 상대 = 흰 카드 + 헤어라인(CHANGES_턴7 §2).
        color: deleted
            ? AppTheme.chipNeutralBackground
            : (isImage
                  ? Colors.white
                  : (mine ? AppTheme.accentRed : Colors.white)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
        border: (mine && !isImage && !deleted)
            ? null
            : Border.all(color: AppTheme.hairline),
      ),
      child: deleted
          ? const _DeletedBubbleText()
          : _BubbleContent(
              message: message,
              mine: mine,
              attachmentUrl: attachmentUrl,
            ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Opacity(
                opacity: showSender ? 1 : 0,
                child: ChatAvatar(name: message.senderName, size: 34),
              ),
            )
          else if (!mine)
            const SizedBox(width: 0),
          Flexible(
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (showSender)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF868E96),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: mine ? TextDirection.rtl : TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onSecondaryTapDown: onMenu == null
                            ? null
                            : (d) => onMenu!(d.globalPosition),
                        onLongPressStart: onMenu == null
                            ? null
                            : (d) => onMenu!(d.globalPosition),
                        child: bubble,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: time,
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

/// 말풍선 본문 — 텍스트 / 이미지 / 파일에 따라 내용이 달라진다.
/// 삭제된 메시지 자리 표시 — '삭제된 메시지입니다'.
class _DeletedBubbleText extends StatelessWidget {
  const _DeletedBubbleText();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.block, size: 14, color: Color(0xFFADB5BD)),
        SizedBox(width: 5),
        Text(
          '삭제된 메시지입니다',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.35,
            fontStyle: FontStyle.italic,
            color: Color(0xFF868E96),
          ),
        ),
      ],
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({
    required this.message,
    required this.mine,
    required this.attachmentUrl,
  });

  final ChatMessage message;
  final bool mine;
  final String? attachmentUrl;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case ChatMessageType.image:
        return _ImageAttachment(message: message, url: attachmentUrl);
      case ChatMessageType.file:
        return _FileAttachment(
          message: message,
          mine: mine,
          url: attachmentUrl,
        );
      default:
        return _buildText();
    }
  }

  /// 답장(`↪ 보낸이: 원문\n답장본문`)이면 인용부와 본문을 구분해 그린다.
  Widget _buildText() {
    const marker = '↪ ';
    final text = message.text;
    final bodyStyle = TextStyle(
      fontSize: 14,
      height: 1.35,
      color: mine ? Colors.white : const Color(0xFF212529),
    );
    final nl = text.indexOf('\n');
    if (!text.startsWith(marker) || nl <= 0) {
      return Text(text, style: bodyStyle);
    }
    final quote = text.substring(marker.length, nl).trim();
    final body = text.substring(nl + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: mine ? Colors.white24 : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  color: mine ? Colors.white70 : AppTheme.accentRed,
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(7, 5, 9, 5),
                    child: Text(
                      quote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: mine ? Colors.white : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (body.isNotEmpty) Text(body, style: bodyStyle),
      ],
    );
  }
}

class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({required this.message, required this.url});

  final ChatMessage message;
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return _FileAttachment(message: message, mine: false, url: null);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260, maxHeight: 280),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => openAttachment(url!),
              child: Image.network(
                url!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    width: 180,
                    height: 140,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, _, _) =>
                    _FileAttachment(message: message, mine: false, url: url),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => openAttachment(forceDownloadUrl(url!)),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.download_rounded,
                      size: 18,
                      color: Colors.white,
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
}

class _FileAttachment extends StatelessWidget {
  const _FileAttachment({
    required this.message,
    required this.mine,
    required this.url,
  });

  final ChatMessage message;
  final bool mine;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final fg = mine ? Colors.white : const Color(0xFF212529);
    final sub = mine ? Colors.white70 : const Color(0xFFADB5BD);
    return InkWell(
      onTap: url == null ? null : () => openAttachment(url!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 30, color: fg),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.fileName ?? '첨부 파일',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                if (message.fileSize != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      formatFileSize(message.fileSize!),
                      style: TextStyle(fontSize: 11.5, color: sub),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE9E2DE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            formatDateDivider(time),
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF6B6560),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SystemLine extends StatelessWidget {
  const _SystemLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFFADB5BD)),
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '첫 메시지를 보내보세요',
        style: TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.uploading,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: '사진·파일 첨부',
              onPressed: uploading ? null : onAttach,
              icon: uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFFADB5BD),
                    ),
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.enter): onSend,
                  },
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '메시지를 입력하세요',
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: AppTheme.accentRed,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSend,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
