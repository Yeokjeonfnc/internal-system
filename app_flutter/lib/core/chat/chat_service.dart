// 메신저 전송 계층 추상화.
//
// 화면(UI)·상태(provider)는 이 인터페이스에만 의존한다. 실제 구현은
//  - [MockChatService]        : 인메모리 + Stream 으로 실시간을 시뮬레이션 (백엔드 없이 동작)
//  - [WebSocketChatService]   : 백엔드 WebSocket/REST 연동 (서버 준비 시 교체)
//
// 백엔드가 준비되면 [kUseMockChat] 만 false 로 바꾸면 전체 화면이 그대로 실서버에 붙는다.

import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/chat/chat_model.dart';

/// true 면 목업(인메모리) 서비스를 사용한다. 백엔드(REST+WebSocket)가 준비되면 false.
///
/// `--dart-define=USE_MOCK_CHAT=true` 로도 덮어쓸 수 있다.
/// 실서버 주소는 [WebSocketChatService] 가 ApiClient 의 base URL 에서 자동 파생한다.
const bool kUseMockChat =
    bool.fromEnvironment('USE_MOCK_CHAT', defaultValue: false);

/// 메신저 데이터/실시간 송수신 계약.
abstract class ChatService {
  /// 현재 로그인 사용자. UI 진입 시 [init] 으로 주입한다.
  String get currentUserId;
  String get currentUserName;

  /// 사용자 컨텍스트 주입 + (필요 시) 연결/시드 준비.
  void init({required String userId, required String userName});

  /// 내가 속한 방 목록 스트림 (최신 메시지순). 구독 즉시 현재 스냅샷을 1회 방출한다.
  Stream<List<ChatRoom>> watchRooms();

  /// 특정 방의 메시지 스트림 (시간순). 구독 즉시 현재 히스토리를 1회 방출한다.
  Stream<List<ChatMessage>> watchMessages(String roomId);

  /// 메시지 전송.
  Future<void> sendMessage(String roomId, String text);

  /// 이미지/파일 첨부 전송. [bytes] 는 선택한 파일의 원본 바이트.
  Future<void> sendAttachment(
    String roomId, {
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  });

  /// 첨부(이미지/파일) 다운로드·표시 URL. 첨부가 아니면 null.
  String? attachmentUrl(ChatMessage message);

  /// 해당 방의 안 읽음 수를 0 으로.
  Future<void> markRead(String roomId);

  /// 대화방을 내 목록에서 삭제(숨김). 이후 새 메시지가 오면 다시 나타난다.
  Future<void> hideRoom(String roomId);

  /// 메시지 삭제 — 본인이 보낸 메시지만 가능. 모든 참여자에게서 사라진다.
  Future<void> deleteMessage(String roomId, String messageId);

  /// 새 방 생성(1:1 또는 그룹). 기존 1:1 방이 있으면 그 방을 반환한다.
  Future<ChatRoom> createRoom({
    required List<ChatMember> members,
    String? title,
  });

  /// 새 대화를 시작할 수 있는 동료(사원) 목록.
  Future<List<ChatMember>> directory();

  void dispose();
}
