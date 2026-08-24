// 실시간 알림 수신 허브 (mal001-N2).
//
// 서버는 `notif_mst` 에 알림을 넣은 뒤 같은 내용을 WebSocket 프레임으로도 쏜다.
//   S→C  {"type":"notification","notifTyp":"MAIL_RECEIVED",
//         "msgTxt":"[메일] 홍길동(a@b.com) : 제목","mailIdx":123,"createDt":"..."}
//
// 그 프레임을 받는 곳은 [WebSocketChatService] 하나뿐인데(소켓이 하나라서),
// 그것을 보여줘야 하는 곳은 사이드바 알림 배지·알림함 다이얼로그처럼 여럿이다.
// 이 파일이 그 사이를 잇는다.
//
// **왜 Riverpod provider 가 아니라 싱글턴 스트림인가.**
// 프레임을 흘려보내는 [WebSocketChatService] 는 provider 가 만들어 주긴 하지만
// 자기 `ref` 를 들고 있지 않다(순수 서비스 클래스). 반대편 수신자인
// [NotificationBellIconButton] 은 Riverpod 이 아니라 `provider` 패키지 +
// setState 로 돌아간다. 양쪽 다 ref 가 없는 상황에서 provider 를 끼우려면 서비스에
// ref 를 주입하는 개조가 필요하고, 그건 메신저 동작을 건드리는 위험을 만든다.
// [AuthTokenStore] 처럼 "전역 상태 한 조각"으로 두는 편이 기존 코드 스타일과도 맞다.

import 'dart:async';

/// 서버가 보낸 알림 푸시 1건.
///
/// 이 값만으로 화면을 그리지는 않는다 — 알림함 목록·미읽음 수는 REST 로 다시
/// 받아 온다(서버가 진실). 여기 담긴 값은 "지금 뭐가 왔는지"를 토스트에 쓰고,
/// 내가 있는 화면과 겹치는지 판단하는 용도다.
class NotifPushEvent {
  const NotifPushEvent({
    required this.notifTyp,
    required this.msgTxt,
    this.mailIdx,
    this.createDt = '',
  });

  /// `notif_mst.notif_typ`.
  final String notifTyp;

  /// `notif_mst.msg_txt` — 예: `[메일] 홍길동(a@b.com) : 회의 일정`.
  final String msgTxt;

  /// 메일 수신 알림일 때 `mail_idx`. 다른 종류면 null.
  final int? mailIdx;

  final String createDt;

  /// 메일 수신 — 백엔드 `MailNotifyService.NOTIF_TYP` 과 같은 값이어야 한다.
  static const String typMailReceived = 'MAIL_RECEIVED';

  bool get isMailReceived => notifTyp == typMailReceived;

  /// WebSocket 프레임 → 이벤트. 값이 빠져 있어도 던지지 않는다(푸시는 부가 기능).
  factory NotifPushEvent.fromFrame(Map<String, dynamic> frame) {
    final raw = frame['mailIdx'];
    return NotifPushEvent(
      notifTyp: (frame['notifTyp'] ?? '').toString(),
      msgTxt: (frame['msgTxt'] ?? '').toString(),
      mailIdx: raw is int ? raw : int.tryParse('${raw ?? ''}'),
      createDt: (frame['createDt'] ?? '').toString(),
    );
  }
}

/// 소켓 → 화면 알림 브로드캐스트.
///
/// 브로드캐스트 스트림이라 듣는 사람이 없어도(로그인 화면 등) 이벤트는 그냥
/// 버려진다. 그래도 알림 자체는 이미 DB 에 있으므로 다음 조회 때 보인다.
class NotificationRealtime {
  NotificationRealtime._();

  static final NotificationRealtime instance = NotificationRealtime._();

  final StreamController<NotifPushEvent> _ctrl =
      StreamController<NotifPushEvent>.broadcast();

  /// 알림 푸시 스트림. 구독자는 반드시 dispose 에서 취소할 것.
  Stream<NotifPushEvent> get stream => _ctrl.stream;

  void publish(NotifPushEvent event) {
    if (_ctrl.isClosed) return;
    _ctrl.add(event);
  }
}
