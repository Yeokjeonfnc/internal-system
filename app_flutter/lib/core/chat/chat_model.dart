// 메신저 도메인 모델 — 채팅방·메시지·멤버.
//
// 백엔드(REST/WebSocket)와 주고받는 JSON 직렬화를 직접 구현한다.
// (json_serializable 빌드 러너 없이도 전송 계층 교체가 쉽도록 수동 매핑.)

import 'package:flutter/foundation.dart';

/// 메시지 종류. [system] 은 "방이 생성되었습니다" 같은 안내 줄.
enum ChatMessageType { text, system, image, file }

ChatMessageType _messageTypeFromRaw(Object? raw) {
  switch (raw) {
    case 'system':
      return ChatMessageType.system;
    case 'image':
      return ChatMessageType.image;
    case 'file':
      return ChatMessageType.file;
    default:
      return ChatMessageType.text;
  }
}

/// 채팅 참여자(사원). 현재 로그인 사용자도 멤버로 포함된다.
@immutable
class ChatMember {
  const ChatMember({
    required this.userId,
    required this.userName,
    this.deptNm = '',
  });

  final String userId;
  final String userName;
  final String deptNm;

  factory ChatMember.fromJson(Map<String, dynamic> json) {
    return ChatMember(
      userId: (json['userId'] ?? '').toString(),
      userName: (json['userName'] ?? json['userNm'] ?? '').toString(),
      deptNm: (json['deptNm'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    if (deptNm.isNotEmpty) 'deptNm': deptNm,
  };

  @override
  bool operator ==(Object other) =>
      other is ChatMember && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;
}

/// 한 건의 채팅 메시지.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    this.type = ChatMessageType.text,
    this.fileName,
    this.fileSize,
    this.contentType,
    this.isDeleted = false,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final ChatMessageType type;

  /// 삭제된 메시지. true 면 본문 대신 '삭제된 메시지입니다' 로 표시한다.
  final bool isDeleted;

  /// 첨부(이미지/파일) 메타. 텍스트 메시지는 null.
  final String? fileName;
  final int? fileSize;
  final String? contentType;

  bool isMine(String currentUserId) => senderId == currentUserId;

  bool get hasAttachment =>
      type == ChatMessageType.image || type == ChatMessageType.file;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? json['messageId'] ?? '').toString(),
      roomId: (json['roomId'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      senderName: (json['senderName'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      sentAt:
          DateTime.tryParse((json['sentAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      type: _messageTypeFromRaw(json['type']),
      fileName: (json['fileName'] as Object?)?.toString(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      contentType: (json['contentType'] as Object?)?.toString(),
      isDeleted: json['deleted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'sentAt': sentAt.toUtc().toIso8601String(),
    'type': type.name,
    if (fileName != null) 'fileName': fileName,
    if (fileSize != null) 'fileSize': fileSize,
    if (contentType != null) 'contentType': contentType,
    if (isDeleted) 'deleted': true,
  };

  ChatMessage copyWith({String? id, DateTime? sentAt, bool? isDeleted}) {
    return ChatMessage(
      id: id ?? this.id,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      sentAt: sentAt ?? this.sentAt,
      type: type,
      fileName: fileName,
      fileSize: fileSize,
      contentType: contentType,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// 채팅방. 1:1 이면 [isGroup] = false, 멤버 2명.
@immutable
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.title,
    required this.isGroup,
    required this.members,
    this.lastText = '',
    this.lastAt,
    this.unreadCount = 0,
  });

  final String id;

  /// 그룹방의 표시명. 1:1 방은 비어 있을 수 있어 UI 에서 상대 이름으로 대체한다.
  final String title;
  final bool isGroup;
  final List<ChatMember> members;
  final String lastText;
  final DateTime? lastAt;
  final int unreadCount;

  /// 현재 사용자를 제외한 상대 멤버들.
  List<ChatMember> others(String currentUserId) =>
      members.where((m) => m.userId != currentUserId).toList();

  /// 화면에 표시할 방 이름 (그룹은 title, 1:1 은 상대 이름).
  String displayTitle(String currentUserId) {
    if (isGroup && title.isNotEmpty) return title;
    final rest = others(currentUserId);
    if (rest.isEmpty) return title.isEmpty ? '(알 수 없음)' : title;
    return rest.map((m) => m.userName).join(', ');
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final rawMembers = (json['members'] as List?) ?? const [];
    return ChatRoom(
      id: (json['id'] ?? json['roomId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      isGroup: json['isGroup'] == true,
      members: rawMembers
          .whereType<Map<String, dynamic>>()
          .map(ChatMember.fromJson)
          .toList(),
      lastText: (json['lastText'] ?? '').toString(),
      lastAt: DateTime.tryParse((json['lastAt'] ?? '').toString())?.toLocal(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isGroup': isGroup,
    'members': members.map((m) => m.toJson()).toList(),
    'lastText': lastText,
    'lastAt': lastAt?.toUtc().toIso8601String(),
    'unreadCount': unreadCount,
  };

  ChatRoom copyWith({
    String? title,
    List<ChatMember>? members,
    String? lastText,
    DateTime? lastAt,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id,
      title: title ?? this.title,
      isGroup: isGroup,
      members: members ?? this.members,
      lastText: lastText ?? this.lastText,
      lastAt: lastAt ?? this.lastAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
