// 메신저 Riverpod providers.
//
// 화면은 이 provider 들만 watch 한다. 실제 구현(mock/websocket)은
// [kUseMockChat] 플래그로 결정되며 UI 는 영향받지 않는다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/chat/chat_model.dart';
import 'package:app_flutter/core/chat/chat_service.dart';
import 'package:app_flutter/core/chat/mock_chat_service.dart';
import 'package:app_flutter/core/chat/websocket_chat_service.dart';

ChatService _createChatService() =>
    kUseMockChat ? MockChatService() : WebSocketChatService();

/// 앱 수명 동안 유지되는 단일 채팅 서비스. (방·메시지 상태 보존)
final chatServiceProvider = Provider<ChatService>((ref) {
  final service = _createChatService();
  ref.onDispose(service.dispose);
  return service;
});

/// 내 채팅방 목록 (최신순).
final chatRoomsProvider = StreamProvider.autoDispose<List<ChatRoom>>((ref) {
  return ref.watch(chatServiceProvider).watchRooms();
});

/// 특정 방의 메시지 목록 (시간순).
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, roomId) {
      return ref.watch(chatServiceProvider).watchMessages(roomId);
    });

/// 새 대화 상대 후보(동료) 목록.
final chatDirectoryProvider = FutureProvider.autoDispose<List<ChatMember>>((
  ref,
) {
  return ref.watch(chatServiceProvider).directory();
});
