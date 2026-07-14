// 메신저 대화목록 패널 — 사진의 가운데 화면(대화 목록)에 해당.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/chat/chat_model.dart';
import 'package:app_flutter/core/chat/chat_providers.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/messenger/msg001/msg001_widgets.dart';

class Msg001RoomList extends ConsumerStatefulWidget {
  const Msg001RoomList({
    super.key,
    required this.currentUserId,
    required this.selectedRoomId,
    required this.onSelect,
    required this.onNewChat,
  });

  final String currentUserId;
  final String? selectedRoomId;
  final ValueChanged<ChatRoom> onSelect;
  final VoidCallback onNewChat;

  @override
  ConsumerState<Msg001RoomList> createState() => _Msg001RoomListState();
}

class _Msg001RoomListState extends ConsumerState<Msg001RoomList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(chatRoomsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(onNewChat: widget.onNewChat),
        _SearchBox(onChanged: (v) => setState(() => _query = v.trim())),
        const Divider(height: 1, color: Color(0xFFECECEC)),
        Expanded(
          child: roomsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('불러오기 실패: $e')),
            data: (rooms) {
              final filtered = _query.isEmpty
                  ? rooms
                  : rooms
                        .where(
                          (r) => r
                              .displayTitle(widget.currentUserId)
                              .toLowerCase()
                              .contains(_query.toLowerCase()),
                        )
                        .toList();
              if (filtered.isEmpty) {
                return const _EmptyRooms();
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.only(left: 78),
                  child: Divider(height: 1, color: Color(0xFFF1F1F1)),
                ),
                itemBuilder: (context, i) {
                  final room = filtered[i];
                  return _RoomTile(
                    room: room,
                    currentUserId: widget.currentUserId,
                    selected: room.id == widget.selectedRoomId,
                    onTap: () => widget.onSelect(room),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNewChat});

  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
      child: Row(
        children: [
          const Text(
            '메신저',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: '새 대화',
            onPressed: onNewChat,
            icon: const Icon(Icons.edit_square, color: AppTheme.accentRed),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: SizedBox(
        height: 40,
        child: TextField(
          onChanged: onChanged,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isDense: true,
            hintText: '대화 검색',
            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9AA0A6)),
            filled: true,
            fillColor: const Color(0xFFF4F5F7),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.room,
    required this.currentUserId,
    required this.selected,
    required this.onTap,
  });

  final ChatRoom room;
  final String currentUserId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = room.displayTitle(currentUserId);
    final hasUnread = room.unreadCount > 0;
    return Material(
      color: selected ? AppTheme.tableRowSelectedTint : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ChatAvatar(name: title, isGroup: room.isGroup),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (room.isGroup) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${room.members.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFADB5BD),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room.lastText.isEmpty ? '새 대화를 시작하세요' : room.lastText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread
                            ? AppTheme.textSecondary
                            : AppTheme.textMuted,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatChatListTime(room.lastAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFADB5BD),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasUnread)
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        room.unreadCount > 99 ? '99+' : '${room.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 48, color: Color(0xFFCED4DA)),
          SizedBox(height: 12),
          Text(
            '대화가 없습니다',
            style: TextStyle(color: Color(0xFF9AA0A6), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
