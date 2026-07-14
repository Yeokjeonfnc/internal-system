// 백엔드 없이 동작하는 인메모리 메신저 서비스.
//
// StreamController 로 방·메시지 변경을 흘려보내 실시간 UX 를 그대로 시뮬레이션한다.
// 내가 메시지를 보내면 잠시 뒤 상대가 자동으로 응답해 "살아있는" 대화처럼 보인다.
// 백엔드가 준비되면 [WebSocketChatService] 로 교체한다. (UI 변경 불필요)

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/chat/chat_model.dart';
import 'package:app_flutter/core/chat/chat_service.dart';

class MockChatService implements ChatService {
  final _rng = Random();

  String _currentUserId = '';
  String _currentUserName = '';
  bool _seeded = false;

  final List<ChatRoom> _rooms = [];
  final Map<String, List<ChatMessage>> _messages = {};

  final StreamController<List<ChatRoom>> _roomsCtrl =
      StreamController<List<ChatRoom>>.broadcast();
  final Map<String, StreamController<List<ChatMessage>>> _msgCtrls = {};

  int _seq = 0;
  String _nextId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';

  @override
  String get currentUserId => _currentUserId;

  @override
  String get currentUserName => _currentUserName;

  @override
  void init({required String userId, required String userName}) {
    _currentUserId = userId.isEmpty ? 'me' : userId;
    _currentUserName = userName.isEmpty ? '나' : userName;
    if (!_seeded) {
      _seed();
      _seeded = true;
    }
  }

  // ── 동료(사원) 디렉터리: 새 대화 상대 후보 ──────────────────────────────
  static const List<ChatMember> _directory = [
    ChatMember(userId: 'u_kim', userName: '김영업', deptNm: '영업팀'),
    ChatMember(userId: 'u_lee', userName: '이개발', deptNm: '개발팀'),
    ChatMember(userId: 'u_park', userName: '박지원', deptNm: '개발팀'),
    ChatMember(userId: 'u_choi', userName: '최민수', deptNm: '운영팀'),
    ChatMember(userId: 'u_jung', userName: '정수진', deptNm: '마케팅팀'),
    ChatMember(userId: 'u_kang', userName: '강하늘', deptNm: '영업팀'),
    ChatMember(userId: 'u_yoon', userName: '윤서연', deptNm: '경영지원'),
  ];

  ChatMember get _me =>
      ChatMember(userId: _currentUserId, userName: _currentUserName);

  void _seed() {
    final now = DateTime.now();
    final kim = _directory[0];
    final lee = _directory[1];
    final park = _directory[2];
    final choi = _directory[3];
    final jung = _directory[4];

    // 1:1 방 — 김영업
    _addSeedRoom(
      ChatRoom(
        id: 'room_kim',
        title: '',
        isGroup: false,
        members: [_me, kim],
        unreadCount: 2,
      ),
      [
        _seedMsg('room_kim', kim, '점장님 미팅 자료 받으셨나요?', now.subtract(const Duration(minutes: 32))),
        _seedMsg('room_kim', _me, '네, 방금 확인했습니다. 검토 후 회신드릴게요.', now.subtract(const Duration(minutes: 28))),
        _seedMsg('room_kim', kim, '감사합니다. 오후 3시 회의 전까지 부탁드려요.', now.subtract(const Duration(minutes: 12))),
        _seedMsg('room_kim', kim, '추가로 매출 보고서도 같이 보면 좋을 것 같습니다.', now.subtract(const Duration(minutes: 11))),
      ],
    );

    // 그룹방 — 개발팀
    _addSeedRoom(
      ChatRoom(
        id: 'room_dev',
        title: '개발팀 단톡방',
        isGroup: true,
        members: [_me, lee, park, jung],
        unreadCount: 0,
      ),
      [
        _seedMsg('room_dev', lee, '오늘 배포 일정 공유드립니다.', now.subtract(const Duration(hours: 3))),
        _seedMsg('room_dev', park, '확인했습니다. QA 먼저 돌릴게요.', now.subtract(const Duration(hours: 2, minutes: 50))),
        _seedMsg('room_dev', _me, '좋습니다. 이슈 있으면 바로 공유해주세요.', now.subtract(const Duration(hours: 2, minutes: 40))),
      ],
    );

    // 1:1 방 — 이개발
    _addSeedRoom(
      ChatRoom(
        id: 'room_lee',
        title: '',
        isGroup: false,
        members: [_me, lee],
        unreadCount: 0,
      ),
      [
        _seedMsg('room_lee', _me, '메신저 기능 테스트 중입니다.', now.subtract(const Duration(days: 1))),
        _seedMsg('room_lee', lee, '오 좋네요. 잘 동작하나요?', now.subtract(const Duration(days: 1)).add(const Duration(minutes: 3))),
      ],
    );

    // 그룹방 — 가맹점 오픈 TF
    _addSeedRoom(
      ChatRoom(
        id: 'room_tf',
        title: '가맹점 오픈 TF',
        isGroup: true,
        members: [_me, kim, choi, jung],
        unreadCount: 5,
      ),
      [
        _seedMsg('room_tf', choi, '신규 점포 인테리어 견적 정리해서 올렸습니다.', now.subtract(const Duration(hours: 6))),
        _seedMsg('room_tf', jung, '오픈 프로모션 시안도 공유드려요.', now.subtract(const Duration(hours: 5, minutes: 30))),
        _seedMsg('room_tf', kim, '두 건 모두 확인하겠습니다.', now.subtract(const Duration(hours: 1))),
      ],
    );
  }

  ChatMessage _seedMsg(
    String roomId,
    ChatMember sender,
    String text,
    DateTime at,
  ) {
    return ChatMessage(
      id: _nextId('m'),
      roomId: roomId,
      senderId: sender.userId,
      senderName: sender.userName,
      text: text,
      sentAt: at,
    );
  }

  void _addSeedRoom(ChatRoom room, List<ChatMessage> msgs) {
    final last = msgs.isNotEmpty ? msgs.last : null;
    _rooms.add(
      room.copyWith(
        lastText: last?.text ?? '',
        lastAt: last?.sentAt,
      ),
    );
    _messages[room.id] = msgs;
  }

  // ── 스트림 ───────────────────────────────────────────────────────────
  List<ChatRoom> _sortedRooms() {
    final list = List<ChatRoom>.from(_rooms);
    list.sort((a, b) {
      final at = a.lastAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.lastAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return List.unmodifiable(list);
  }

  StreamController<List<ChatMessage>> _ctrlFor(String roomId) {
    return _msgCtrls.putIfAbsent(
      roomId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
  }

  void _emitRooms() {
    if (!_roomsCtrl.isClosed) _roomsCtrl.add(_sortedRooms());
  }

  void _emitMessages(String roomId) {
    final ctrl = _ctrlFor(roomId);
    if (!ctrl.isClosed) {
      ctrl.add(List.unmodifiable(_messages[roomId] ?? const []));
    }
  }

  @override
  Stream<List<ChatRoom>> watchRooms() async* {
    yield _sortedRooms();
    yield* _roomsCtrl.stream;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) async* {
    yield List.unmodifiable(_messages[roomId] ?? const []);
    yield* _ctrlFor(roomId).stream;
  }

  // ── 동작 ─────────────────────────────────────────────────────────────
  @override
  Future<void> sendMessage(String roomId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final msg = ChatMessage(
      id: _nextId('m'),
      roomId: roomId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      text: trimmed,
      sentAt: DateTime.now(),
    );
    _appendMessage(msg, resetUnread: true);
    _scheduleAutoReply(roomId);
  }

  @override
  Future<void> sendAttachment(
    String roomId, {
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    if (bytes.isEmpty) return;
    final isImage = (contentType ?? '').startsWith('image/');
    final msg = ChatMessage(
      id: _nextId('m'),
      roomId: roomId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      text: '',
      sentAt: DateTime.now(),
      type: isImage ? ChatMessageType.image : ChatMessageType.file,
      fileName: fileName,
      fileSize: bytes.length,
      contentType: contentType,
    );
    _appendMessage(msg, resetUnread: true);
  }

  // 목업은 실제 파일 서버가 없어 미리보기/다운로드 URL 을 제공하지 않는다.
  @override
  String? attachmentUrl(ChatMessage message) => null;

  void _appendMessage(ChatMessage msg, {required bool resetUnread}) {
    (_messages[msg.roomId] ??= []).add(msg);
    final idx = _rooms.indexWhere((r) => r.id == msg.roomId);
    if (idx != -1) {
      final room = _rooms[idx];
      final preview = switch (msg.type) {
        ChatMessageType.image => '사진',
        ChatMessageType.file => msg.fileName ?? '파일',
        _ => msg.text,
      };
      _rooms[idx] = room.copyWith(
        lastText: preview,
        lastAt: msg.sentAt,
        unreadCount: resetUnread
            ? 0
            : (msg.senderId == _currentUserId
                  ? room.unreadCount
                  : room.unreadCount + 1),
      );
    }
    _emitMessages(msg.roomId);
    _emitRooms();
  }

  /// 내가 보낸 뒤 상대가 자동 응답 — 실시간 수신을 시연하기 위한 목업 동작.
  void _scheduleAutoReply(String roomId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;
    final others = _rooms[idx].others(_currentUserId);
    if (others.isEmpty) return;
    // 그룹방은 가끔만 응답해 과한 알림을 막는다.
    if (_rooms[idx].isGroup && _rng.nextBool()) return;

    final replier = others[_rng.nextInt(others.length)];
    final delay = Duration(milliseconds: 900 + _rng.nextInt(1200));
    Future.delayed(delay, () {
      if (_roomsCtrl.isClosed) return;
      final reply = ChatMessage(
        id: _nextId('m'),
        roomId: roomId,
        senderId: replier.userId,
        senderName: replier.userName,
        text: _cannedReplies[_rng.nextInt(_cannedReplies.length)],
        sentAt: DateTime.now(),
      );
      _appendMessage(reply, resetUnread: false);
    });
  }

  static const List<String> _cannedReplies = [
    '네 확인했습니다.',
    '알겠습니다, 바로 처리할게요.',
    '잠시 후 다시 말씀드리겠습니다.',
    '좋은 의견이네요.',
    '공유 감사합니다.',
    '회의 때 자세히 논의하시죠.',
    '넵 반영하겠습니다.',
  ];

  @override
  Future<void> markRead(String roomId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1 || _rooms[idx].unreadCount == 0) return;
    _rooms[idx] = _rooms[idx].copyWith(unreadCount: 0);
    _emitRooms();
  }

  @override
  Future<void> hideRoom(String roomId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;
    _rooms.removeAt(idx);
    _emitRooms();
  }

  @override
  Future<void> deleteMessage(String roomId, String messageId) async {
    final list = _messages[roomId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    // 본인이 보낸 메시지만 삭제.
    if (list[idx].senderId != _currentUserId) return;
    if (list[idx].isDeleted) return;
    // 제거하지 않고 '삭제된 메시지입니다' 로 표시.
    list[idx] = list[idx].copyWith(isDeleted: true);
    _emitMessages(roomId);
  }

  @override
  Future<ChatRoom> createRoom({
    required List<ChatMember> members,
    String? title,
  }) async {
    final all = <ChatMember>[_me, ...members];
    final unique = <String, ChatMember>{for (final m in all) m.userId: m};
    final memberList = unique.values.toList();
    final isGroup = memberList.length > 2 || (title != null && title.isNotEmpty);

    // 동일 멤버 1:1 방이 이미 있으면 재사용.
    if (!isGroup) {
      final existing = _rooms.where((r) {
        if (r.isGroup) return false;
        final ids = r.members.map((m) => m.userId).toSet();
        return ids.length == memberList.length &&
            ids.containsAll(memberList.map((m) => m.userId));
      });
      if (existing.isNotEmpty) return existing.first;
    }

    final room = ChatRoom(
      id: _nextId('room'),
      title: title ?? '',
      isGroup: isGroup,
      members: memberList,
      lastText: '',
      lastAt: DateTime.now(),
    );
    _rooms.add(room);
    _messages[room.id] = [
      ChatMessage(
        id: _nextId('m'),
        roomId: room.id,
        senderId: 'system',
        senderName: '',
        text: '대화가 시작되었습니다.',
        sentAt: DateTime.now(),
        type: ChatMessageType.system,
      ),
    ];
    _emitMessages(room.id);
    _emitRooms();
    return room;
  }

  @override
  Future<List<ChatMember>> directory() async {
    return _directory.where((m) => m.userId != _currentUserId).toList();
  }

  @override
  void dispose() {
    _roomsCtrl.close();
    for (final c in _msgCtrls.values) {
      c.close();
    }
    _msgCtrls.clear();
  }
}
