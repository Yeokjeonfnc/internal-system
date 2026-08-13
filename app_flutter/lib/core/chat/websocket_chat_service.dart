// 실서버 연동 메신저 서비스.
//
// 설계: REST 로 방/메시지/디렉터리/생성/읽음을 처리하고, WebSocket 은 서버→클라이언트
// 실시간 푸시(신규 메시지·새 방)만 받는다. 백엔드(Spring Boot) 구현과 1:1 로 맞춰져 있다.
//
//   REST  (ApiClient, base = .../api)
//     GET  /chat/rooms?userId=
//     GET  /chat/rooms/{roomId}/messages?userId=
//     POST /chat/rooms?userId=                (body: {memberIds:[...], title})
//     POST /chat/rooms/{roomId}/messages?userId=  (body: {text})
//     POST /chat/rooms/{roomId}/read?userId=
//     GET  /chat/directory?userId=
//   WebSocket  ws(s)://host/api/ws/chat?userId=
//     S→C  {"type":"message","message":{...}}
//     S→C  {"type":"roomCreated","room":{...}}
//
// 사용하려면 chat_service.dart 의 kUseMockChat = false 로 설정한다.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/core/auth/auth_token_store.dart';
import 'package:app_flutter/core/chat/chat_model.dart';
import 'package:app_flutter/core/chat/chat_service.dart';

class WebSocketChatService implements ChatService {
  final ApiClient _api = ApiClient();

  String _currentUserId = '';
  String _currentUserName = '';

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _heartbeat;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  Timer? _roomsPollTimer;
  Timer? _safetyPollTimer;
  bool _disposed = false;

  /// WebSocket 이 살아있는지. true 면 빠른 폴링을 멈추고 실시간 푸시에 의존한다.
  bool _wsAlive = false;

  /// 마지막으로 열람 중인 방 — 폴링 폴백에서 메시지를 다시 받아온다.
  String? _activeRoomId;

  final List<ChatRoom> _rooms = [];
  final Map<String, List<ChatMessage>> _messages = {};
  final Set<String> _historyLoaded = {};
  String _roomsSignature = '';

  final StreamController<List<ChatRoom>> _roomsCtrl =
      StreamController<List<ChatRoom>>.broadcast();
  final Map<String, StreamController<List<ChatMessage>>> _msgCtrls = {};

  @override
  String get currentUserId => _currentUserId;

  @override
  String get currentUserName => _currentUserName;

  @override
  void init({required String userId, required String userName}) {
    // 같은 사용자로 다시 들어오면(연결 유지 중) 캐시를 보존한다.
    if (!_disposed && _currentUserId == userId && _channel != null) {
      _currentUserName = userName;
      return;
    }
    // 사용자가 바뀌면 이전 사용자 방·메시지 캐시와 연결을 완전히 비운다.
    _resetForNewUser();
    _currentUserId = userId;
    _currentUserName = userName;
    _disposed = false;
    _connect();
    unawaited(_refreshRooms());
    _startPolling();
  }

  /// 로그인 사용자 변경 시 — 이전 사용자의 연결·타이머·캐시를 모두 정리하고
  /// 화면에 남은 이전 데이터(방/메시지)를 즉시 비운다.
  void _resetForNewUser() {
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    _roomsPollTimer?.cancel();
    _safetyPollTimer?.cancel();
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _wsAlive = false;
    _activeRoomId = null;
    _rooms.clear();
    _messages.clear();
    _historyLoaded.clear();
    _roomsSignature = '';
    // 이전 사용자 잔상 제거 — 빈 목록을 즉시 흘려보낸다.
    _emitRooms();
    for (final roomId in _msgCtrls.keys.toList()) {
      _emitMessages(roomId);
    }
  }

  /// 폴링 폴백 — WebSocket 이 끊겼을 때만 동작한다(WS 정상이면 자원 낭비를 막기 위해 멈춤).
  /// 열린 방 메시지 2초, 방 목록 5초로 빠르게 따라잡고,
  /// WS 가 살아있어도 20초마다 한 번씩만 가볍게 보정(self-heal)한다.
  void _startPolling() {
    _pollTimer?.cancel();
    _roomsPollTimer?.cancel();
    _safetyPollTimer?.cancel();

    // WS 끊김 시 빠른 폴백.
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_disposed || _currentUserId.isEmpty || _wsAlive) return;
      final active = _activeRoomId;
      if (active != null) {
        unawaited(_loadHistory(active, silentIfSame: true));
      }
    });
    _roomsPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_disposed || _currentUserId.isEmpty || _wsAlive) return;
      unawaited(_refreshRooms());
    });

    // WS 정상이어도 혹시 모를 누락 대비 — 20초 1회(부하 미미).
    _safetyPollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_disposed || _currentUserId.isEmpty || !_wsAlive) return;
      unawaited(_refreshRooms());
      final active = _activeRoomId;
      if (active != null) {
        unawaited(_loadHistory(active, silentIfSame: true));
      }
    });
  }

  // ── WebSocket ────────────────────────────────────────────────────────
  /// REST base URL 에서 WebSocket 주소를 파생한다.
  ///  - 절대(http/https): 그대로 ws/wss 로 치환  (모바일·로컬)
  ///  - 상대('/api'):      현재 페이지(Uri.base) 기준 절대 주소로 구성 (웹 동일 출처)
  String _wsUrl() {
    final base = ApiClient.resolveBaseUrl(); // 'http://host:3001/api' 또는 '/api'
    final Uri origin;
    if (base.startsWith('http')) {
      origin = Uri.parse(base);
    } else {
      // 웹은 해시(#) 라우팅이라 Uri.base 에 프래그먼트(#/founders 등)가 붙는다.
      final path = base.startsWith('/') ? base : '/$base';
      origin = Uri.base.replace(path: path);
    }
    final wsScheme = origin.scheme == 'https' ? 'wss' : 'ws';
    final basePath = origin.path.endsWith('/')
        ? origin.path.substring(0, origin.path.length - 1)
        : origin.path;
    // 프래그먼트가 들어가면 'WebSocket URL must not contain fragment' 로 실패하므로
    // 깨끗한 Uri 를 새로 구성한다(쿼리/프래그먼트 미포함).
    // 브라우저 WebSocket API 는 커스텀 헤더를 못 넣으므로 인증 토큰을 쿼리로 전달한다.
    // (서버 AuthTokenFilter 가 /ws/chat 만 ?token= 을 허용한다.)
    final uri = Uri(
      scheme: wsScheme,
      host: origin.host,
      port: origin.hasPort ? origin.port : null,
      path: '$basePath/ws/chat',
      queryParameters: {
        'userId': _currentUserId,
        if (AuthTokenStore.hasToken) 'token': AuthTokenStore.token,
      },
    ).removeFragment(); // 혹시 모를 프래그먼트까지 한 번 더 제거
    return uri.toString();
  }

  void _connect() {
    if (_disposed || _currentUserId.isEmpty) return;
    // 기존 연결 정리(중복 방지).
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {
      // no-op
    }
    try {
      final url = _wsUrl();
      debugPrint('채팅 소켓 연결 시도: $url'); // 새 빌드 확인용 — 프래그먼트(#) 없어야 정상
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channel = channel;
      _sub = channel.stream.listen(
        _onFrame,
        onError: (e) {
          debugPrint('채팅 소켓 오류: $e');
          _wsAlive = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('채팅 소켓 종료');
          _wsAlive = false;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
      _wsAlive = true; // 낙관적 활성 — 끊기면 onError/onDone 이 즉시 false 로 되돌린다.
      _startHeartbeat();
    } catch (e) {
      debugPrint('채팅 소켓 연결 실패: $e');
      _wsAlive = false;
      _scheduleReconnect();
    }
  }

  /// 프록시(Cloudflare/Caddy) 의 idle 타임아웃으로 소켓이 끊기지 않도록 주기적 ping.
  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      try {
        _channel?.sink.add('{"type":"ping"}');
      } catch (_) {
        // no-op — 실패 시 onDone/onError 가 재연결을 트리거한다.
      }
    });
  }

  /// 끊긴 소켓을 3초 뒤 재연결하고, 누락분을 REST 로 보정한다.
  void _scheduleReconnect() {
    _heartbeat?.cancel();
    if (_disposed || _currentUserId.isEmpty) return;
    if (_reconnectTimer != null) return; // 이미 예약됨
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _reconnectTimer = null;
      _connect();
      unawaited(_refreshRooms());
      final active = _activeRoomId;
      if (active != null) unawaited(_loadHistory(active));
    });
  }

  void _onFrame(dynamic raw) {
    _wsAlive = true; // 어떤 프레임이든(pong 포함) 수신 = 연결 정상.
    Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (frame['type']) {
      case 'message':
        final msg = ChatMessage.fromJson(
          (frame['message'] as Map).cast<String, dynamic>(),
        );
        _appendIncoming(msg);
        unawaited(_refreshRooms());
        break;
      case 'roomCreated':
        unawaited(_refreshRooms());
        break;
      case 'messageDeleted':
        final roomId = (frame['roomIdx'] ?? '').toString();
        final messageId = (frame['messageIdx'] ?? '').toString();
        _markLocalMessageDeleted(roomId, messageId);
        unawaited(_refreshRooms());
        break;
    }
  }

  /// 로컬 캐시의 메시지를 '삭제됨' 으로 표시하고 해당 방 스트림을 갱신.
  /// (제거하지 않고 '삭제된 메시지입니다' 로 남긴다.)
  void _markLocalMessageDeleted(String roomId, String messageId) {
    final list = _messages[roomId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1 || list[idx].isDeleted) return;
    list[idx] = list[idx].copyWith(isDeleted: true);
    _emitMessages(roomId);
  }

  void _appendIncoming(ChatMessage msg) {
    final list = _messages[msg.roomId] ??= [];
    if (list.any((m) => m.id == msg.id)) return; // 중복 방지(REST 응답과 겹칠 수 있음)
    list.add(msg);
    _emitMessages(msg.roomId);
  }

  // ── REST ─────────────────────────────────────────────────────────────
  Future<void> _refreshRooms() async {
    if (_currentUserId.isEmpty) return;
    try {
      final res = await _api.get(
        '/chat/rooms',
        queryParameters: {'userId': _currentUserId},
      );
      final data =
          (res.data is Map ? res.data['data'] : null) as List? ?? const [];
      _rooms
        ..clear()
        ..addAll(data.whereType<Map<String, dynamic>>().map(ChatRoom.fromJson));
      // 변동이 없으면 emit 하지 않아 폴링 시 불필요한 리빌드를 막는다.
      final sig = _rooms
          .map(
            (r) =>
                '${r.id}:${r.lastAt?.millisecondsSinceEpoch}:'
                '${r.lastText.hashCode}:${r.unreadCount}',
          )
          .join('|');
      if (sig != _roomsSignature) {
        _roomsSignature = sig;
        _emitRooms();
      }
    } catch (e) {
      debugPrint('채팅방 목록 조회 실패: $e');
    }
  }

  Future<void> _loadHistory(String roomId, {bool silentIfSame = false}) async {
    if (_currentUserId.isEmpty) return;
    try {
      final res = await _api.get(
        '/chat/rooms/$roomId/messages',
        queryParameters: {'userId': _currentUserId},
      );
      final data =
          (res.data is Map ? res.data['data'] : null) as List? ?? const [];
      final newList = data
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
      final old = _messages[roomId];
      final changed =
          old == null ||
          old.length != newList.length ||
          (newList.isNotEmpty &&
              old.isNotEmpty &&
              old.last.id != newList.last.id);
      _messages[roomId] = newList;
      _historyLoaded.add(roomId);
      if (changed || !silentIfSame) _emitMessages(roomId);
    } catch (e) {
      debugPrint('메시지 조회 실패: $e');
    }
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
    _activeRoomId = roomId;
    if (!_historyLoaded.contains(roomId)) {
      unawaited(_loadHistory(roomId));
    }
    yield List.unmodifiable(_messages[roomId] ?? const []);
    yield* _ctrlFor(roomId).stream;
  }

  // ── 동작 ─────────────────────────────────────────────────────────────
  @override
  Future<void> sendMessage(String roomId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      final res = await _api.post(
        '/chat/rooms/$roomId/messages',
        queryParameters: {'userId': _currentUserId},
        data: {'text': trimmed},
      );
      final data = (res.data is Map ? res.data['data'] : null);
      if (data is Map<String, dynamic>) {
        _appendIncoming(ChatMessage.fromJson(data));
      }
      unawaited(_refreshRooms());
    } catch (e) {
      debugPrint('메시지 전송 실패: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendAttachment(
    String roomId, {
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    if (bytes.isEmpty) return;
    try {
      // contentType 은 서버가 파일명 확장자로 추론한다(불필요한 http_parser 의존 제거).
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final res = await _api.postMultipart(
        '/chat/rooms/$roomId/attachments',
        formData: formData,
        queryParameters: {'userId': _currentUserId},
      );
      final data = (res.data is Map ? res.data['data'] : null);
      if (data is Map<String, dynamic>) {
        _appendIncoming(ChatMessage.fromJson(data));
      }
      unawaited(_refreshRooms());
    } catch (e) {
      debugPrint('첨부 전송 실패: $e');
      rethrow;
    }
  }

  @override
  String? attachmentUrl(ChatMessage message) {
    if (!message.hasAttachment) return null;
    final uid = Uri.encodeQueryComponent(_currentUserId);
    // 이 URL 은 <img src> 나 새 탭으로 직접 열려 Authorization 헤더를 못 싣는다.
    // 서버가 /download 경로에 한해 쿼리 토큰을 허용하므로 함께 붙인다.
    final token = AuthTokenStore.hasToken
        ? '&token=${Uri.encodeQueryComponent(AuthTokenStore.token)}'
        : '';
    return '${_httpBase()}/chat/attachments/${message.id}/download?userId=$uid$token';
  }

  /// REST 절대 base URL. 웹에서 base 가 상대('/api')면 현재 origin 을 붙여
  /// 절대 URL 로 만든다. (url_launcher 는 스킴 없는 상대 URL 을 못 연다.)
  String _httpBase() {
    final base = ApiClient.resolveBaseUrl(); // 'http://host/api' 또는 '/api'
    final String abs;
    if (base.startsWith('http')) {
      abs = base;
    } else {
      final path = base.startsWith('/') ? base : '/$base';
      final o = Uri.base;
      abs = Uri(
        scheme: o.scheme,
        host: o.host,
        port: o.hasPort ? o.port : null,
        path: path,
      ).toString();
    }
    return abs.endsWith('/') ? abs.substring(0, abs.length - 1) : abs;
  }

  @override
  Future<void> markRead(String roomId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1 && _rooms[idx].unreadCount != 0) {
      _rooms[idx] = _rooms[idx].copyWith(unreadCount: 0);
      _emitRooms();
    }
    try {
      await _api.post(
        '/chat/rooms/$roomId/read',
        queryParameters: {'userId': _currentUserId},
      );
    } catch (e) {
      debugPrint('읽음 처리 실패: $e');
    }
  }

  @override
  Future<void> hideRoom(String roomId) async {
    // 낙관적 제거 — 목록에서 즉시 사라지게 한다.
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      _rooms.removeAt(idx);
      _emitRooms();
    }
    if (_activeRoomId == roomId) _activeRoomId = null;
    try {
      await _api.post(
        '/chat/rooms/$roomId/hide',
        queryParameters: {'userId': _currentUserId},
      );
      // 서버가 숨김을 반영했는지 재동기화(서명 기준).
      _roomsSignature = '';
      await _refreshRooms();
    } catch (e) {
      debugPrint('대화방 삭제 실패: $e');
      // 실패 시 서버 상태로 복원.
      _roomsSignature = '';
      await _refreshRooms();
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String roomId, String messageId) async {
    // 낙관적 처리 — 화면에서 즉시 '삭제된 메시지입니다' 로 바뀌게 한다.
    _markLocalMessageDeleted(roomId, messageId);
    try {
      await _api.post(
        '/chat/messages/$messageId/delete',
        queryParameters: {'userId': _currentUserId},
      );
      unawaited(_refreshRooms());
    } catch (e) {
      debugPrint('메시지 삭제 실패: $e');
      // 실패 시 서버 기준으로 복원.
      await _loadHistory(roomId);
      rethrow;
    }
  }

  @override
  Future<ChatRoom> createRoom({
    required List<ChatMember> members,
    String? title,
  }) async {
    final res = await _api.post(
      '/chat/rooms',
      queryParameters: {'userId': _currentUserId},
      data: {
        'memberIds': members.map((m) => m.userId).toList(),
        if (title != null && title.isNotEmpty) 'title': title,
      },
    );
    final data = (res.data is Map ? res.data['data'] : null);
    if (data is! Map<String, dynamic>) {
      throw Exception('방 생성 응답이 올바르지 않습니다.');
    }
    final room = ChatRoom.fromJson(data);
    final existing = _rooms.indexWhere((r) => r.id == room.id);
    if (existing == -1) {
      _rooms.add(room);
      _emitRooms();
    }
    return room;
  }

  @override
  Future<List<ChatMember>> directory() async {
    if (_currentUserId.isEmpty) return const [];
    try {
      final res = await _api.get(
        '/chat/directory',
        queryParameters: {'userId': _currentUserId},
      );
      final data =
          (res.data is Map ? res.data['data'] : null) as List? ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatMember.fromJson)
          .toList();
    } catch (e) {
      debugPrint('동료 목록 조회 실패: $e');
      return const [];
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    _roomsPollTimer?.cancel();
    _safetyPollTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _roomsCtrl.close();
    for (final c in _msgCtrls.values) {
      c.close();
    }
    _msgCtrls.clear();
  }
}
