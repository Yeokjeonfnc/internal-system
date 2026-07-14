// 메신저 메인 화면.
//
// - 넓은 화면(데스크톱): 좌측 대화목록 + 우측 채팅방 마스터-디테일.
// - 좁은 화면(모바일):   대화목록 ↔ 채팅방 단일 페이지 전환 (사진과 동일한 흐름).
//
// 앱 셸(MainFrameLayout)의 사이드바/상단 배너 안쪽 본문으로 렌더링된다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/chat/chat_model.dart';
import 'package:app_flutter/core/chat/chat_providers.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/messenger/msg001/msg001_chat_room.dart';
import 'package:app_flutter/pages/messenger/msg001/msg001_new_chat_dialog.dart';
import 'package:app_flutter/pages/messenger/msg001/msg001_room_list.dart';

/// 이 폭 이상이면 대화목록 + 채팅방을 동시에 보여준다.
const double _kTwoPaneBreakpoint = 760;
const double _kRoomListWidth = 340;

class Msg001View extends ConsumerStatefulWidget {
  const Msg001View({super.key});

  @override
  ConsumerState<Msg001View> createState() => _Msg001ViewState();
}

class _Msg001ViewState extends ConsumerState<Msg001View> {
  String? _selectedRoomId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final auth = provider.Provider.of<AuthProvider>(context, listen: false);
    ref
        .read(chatServiceProvider)
        .init(
          userId: auth.userId.isEmpty ? 'me' : auth.userId,
          userName: auth.userName.isEmpty ? '나' : auth.userName,
        );
  }

  void _onSelect(ChatRoom room) {
    setState(() => _selectedRoomId = room.id);
  }

  void _onDeleted(String roomId) {
    if (_selectedRoomId == roomId) {
      setState(() => _selectedRoomId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.read(chatServiceProvider).currentUserId;

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoPane = constraints.maxWidth >= _kTwoPaneBreakpoint;

        // 첫 방을 자동 선택하지 않는다(자동 선택 시 새 메시지가 바로 읽음 처리됨).
        // 사용자가 방을 직접 누를 때만 해당 방을 열고 읽음 처리한다.

        final card = Container(
          margin: const EdgeInsets.all(14),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: twoPane
              ? _TwoPane(
                  currentUserId: currentUserId,
                  selectedRoomId: _selectedRoomId,
                  onSelect: _onSelect,
                  onNewChat: _handleNewChat,
                  onDeleted: _onDeleted,
                )
              : _SinglePane(
                  currentUserId: currentUserId,
                  selectedRoomId: _selectedRoomId,
                  onSelect: _onSelect,
                  onNewChat: _handleNewChat,
                  onBack: () => setState(() => _selectedRoomId = null),
                  onDeleted: _onDeleted,
                ),
        );

        return ColoredBox(color: AppTheme.appSurface, child: card);
      },
    );
  }

  Future<void> _handleNewChat() async {
    final room = await showNewChatDialog(context);
    if (room != null && mounted) {
      setState(() => _selectedRoomId = room.id);
    }
  }
}

class _TwoPane extends StatelessWidget {
  const _TwoPane({
    required this.currentUserId,
    required this.selectedRoomId,
    required this.onSelect,
    required this.onNewChat,
    required this.onDeleted,
  });

  final String currentUserId;
  final String? selectedRoomId;
  final ValueChanged<ChatRoom> onSelect;
  final VoidCallback onNewChat;
  final ValueChanged<String> onDeleted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: _kRoomListWidth,
          child: Msg001RoomList(
            currentUserId: currentUserId,
            selectedRoomId: selectedRoomId,
            onSelect: onSelect,
            onNewChat: onNewChat,
          ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFFECECEC)),
        Expanded(
          child: selectedRoomId == null
              ? const _NoRoomSelected()
              : Msg001ChatRoom(
                  key: ValueKey(selectedRoomId),
                  roomId: selectedRoomId!,
                  currentUserId: currentUserId,
                  onDeleted: () => onDeleted(selectedRoomId!),
                ),
        ),
      ],
    );
  }
}

class _SinglePane extends StatelessWidget {
  const _SinglePane({
    required this.currentUserId,
    required this.selectedRoomId,
    required this.onSelect,
    required this.onNewChat,
    required this.onBack,
    required this.onDeleted,
  });

  final String currentUserId;
  final String? selectedRoomId;
  final ValueChanged<ChatRoom> onSelect;
  final VoidCallback onNewChat;
  final VoidCallback onBack;
  final ValueChanged<String> onDeleted;

  @override
  Widget build(BuildContext context) {
    if (selectedRoomId == null) {
      return Msg001RoomList(
        currentUserId: currentUserId,
        selectedRoomId: null,
        onSelect: onSelect,
        onNewChat: onNewChat,
      );
    }
    return Msg001ChatRoom(
      key: ValueKey(selectedRoomId),
      roomId: selectedRoomId!,
      currentUserId: currentUserId,
      onBack: onBack,
      onDeleted: () => onDeleted(selectedRoomId!),
    );
  }
}

class _NoRoomSelected extends StatelessWidget {
  const _NoRoomSelected();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7F4F2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentRed.withValues(alpha: 0.92),
                    const Color(0xFFD8434A),
                  ],
                ),
              ),
              child: const Icon(
                Icons.forum_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '메신저',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF212529),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '대화를 선택하거나 새 대화를 시작하세요',
              style: TextStyle(fontSize: 14, color: Color(0xFF868E96)),
            ),
          ],
        ),
      ),
    );
  }
}
