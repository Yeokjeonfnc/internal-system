// 메일(mal001) 모델 — 백엔드 `com.yeokjeon.erp.mail.dto` 응답 DTO 와 필드명을 1:1 로 맞춘다.
//
// `json_serializable` 을 쓰지 않고 수동 `fromJson` 을 쓴다. 기존 화면(eap001·bbs001)이
// 전부 수동이라 빌드러너 산출물이 저장소에 섞이지 않게 하려는 것이고, 서버가 필드를
// 하나 더 내려보내도 화면이 그 자리에서 죽지 않아야 하기 때문이다.
//
// 날짜 표시는 `intl` 대신 `padLeft(2,'0')` 수동 포맷을 쓴다(기존 모델과 동일 규칙).
// 서버가 이미 Asia/Seoul 로 변환해 보내지만, 파싱 결과는 오프셋이 붙은 UTC 기준이라
// 표시 직전에 반드시 `.toLocal()` 을 한 번 더 태운다.

/// 메일함 폴더 코드 — 백엔드 `selectByFolder` 의 `<choose>` 분기 값과 같아야 한다.
/// 오타가 나면 서버는 `1 = 0` 으로 빈 목록을 돌려주고, 화면에는 "메일이 없습니다" 만
/// 뜬다(오류가 아니라서 더 찾기 어렵다). 그래서 문자열을 여기 한 곳에 모아 둔다.
abstract final class MailFolders {
  static const String inbox = 'inbox';
  static const String sent = 'sent';
  static const String draft = 'draft';
  static const String scheduled = 'scheduled';
  static const String failed = 'failed';
  static const String spam = 'spam';
  static const String trash = 'trash';
  static const String all = 'all';

  static String labelOf(String folder) => switch (folder) {
    inbox => '받은메일함',
    sent => '보낸메일함',
    draft => '임시보관함',
    scheduled => '예약메일함',
    failed => '발송실패함',
    spam => '스팸메일함',
    trash => '휴지통',
    all => '전체메일',
    _ => '메일',
  };

  /// 폴더별 "비었을 때" 문구 — 빈 목록과 오류를 절대 같은 문구로 보여 주지 않는다.
  static String emptyMessageOf(String folder) => switch (folder) {
    inbox => '받은 메일이 없습니다',
    sent => '보낸 메일이 없습니다',
    draft => '임시보관 중인 메일이 없습니다',
    scheduled => '예약된 메일이 없습니다',
    failed => '발송에 실패한 메일이 없습니다',
    spam => '스팸으로 분류된 메일이 없습니다',
    trash => '휴지통이 비어 있습니다',
    _ => '표시할 메일이 없습니다',
  };

  /// 휴지통에서는 "삭제"가 **완전삭제**를 뜻한다. 버튼 문구·확인 문구가 달라져야
  /// 사용자가 되돌릴 수 없는 동작을 모르고 누르는 일을 막을 수 있다.
  static bool isTrash(String folder) => folder == trash;

  /// 이 메일함에서 "복구" 버튼을 보여 줄지 — 휴지통·스팸함만 해당.
  static bool canRestore(String folder) => folder == trash || folder == spam;
}

/// 일괄 처리 동작 코드 — `POST /mail/messages/bulk` 의 `action` 값.
///
/// 서버와 문자열이 어긋나면 400 이 나거나(운이 좋으면) **아무 일도 안 일어난다.**
/// 후자가 훨씬 위험해서(사용자는 삭제된 줄 안다) 값을 여기 한 곳에 모아 둔다.
abstract final class MailBulkActions {
  static const String read = 'read';
  static const String unread = 'unread';
  static const String delete = 'delete';
  static const String restore = 'restore';
  static const String purge = 'purge';
  static const String spam = 'spam';
  // 서버 enum(MailBulkAction) 값은 NOTSPAM 이다. 'unspam' 이던 시절엔
  // MailBulkAction.from() 이 "알 수 없는 동작입니다: unspam" 으로 매번 400을
  // 냈다 — 대소문자만 안 가릴 뿐 철자가 아예 다른 값이라 못 맞았다.
  static const String unspam = 'notspam';
  static const String star = 'star';
  static const String unstar = 'unstar';
  static const String move = 'move';

  static String labelOf(String action) => switch (action) {
    read => '읽음처리',
    unread => '안읽음처리',
    delete => '삭제',
    restore => '복구',
    purge => '완전삭제',
    spam => '스팸신고',
    unspam => '스팸해제',
    star => '중요표시',
    unstar => '중요해제',
    move => '이동',
    _ => action,
  };

  /// 되돌릴 수 없는 동작 — 실행 전 반드시 확인 팝업을 띄운다.
  static bool isDestructive(String action) =>
      action == purge || action == delete;
}

String _str(dynamic v) => v?.toString() ?? '';

int _int(dynamic v) {
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool _bool(dynamic v) {
  if (v == true) return true;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    return s == 'true' || s == 'y' || s == '1';
  }
  return false;
}

DateTime? _dateTime(dynamic v) {
  final raw = v?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

List<Map<String, dynamic>> _mapList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}

String _fmtDate(DateTime? d) {
  if (d == null) return '-';
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')}';
}

String _fmtDateTime(DateTime? d) {
  if (d == null) return '-';
  final l = d.toLocal();
  return '${_fmtDate(l)} ${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}

/// 목록 한 줄 — 백엔드 `MailListItemDto`.
class MailListItem {
  const MailListItem({
    required this.mailIdx,
    required this.threadIdx,
    required this.direction,
    required this.subject,
    required this.fromEmail,
    required this.fromNm,
    required this.toSummary,
    required this.snippet,
    required this.attCnt,
    required this.bodyStatus,
    required this.sendStatus,
    required this.lastStatus,
    required this.read,
    required this.spam,
    required this.userId,
    this.partnerIdx,
    this.mappingId,
    this.mailAt,
    // 아래 넷은 백엔드가 아직 안 내려줄 수 있어 기본값을 둔다. 값이 없으면
    // "기능이 없다"가 아니라 "표시할 것이 없다"로 화면이 조용히 넘어가야 한다.
    this.starred = false,
    this.importance = '',
    this.scheduledAt,
    this.openedAt,
    this.openCnt = 0,
    this.readReceipt = false,
    this.folder = '',
  });

  factory MailListItem.fromJson(Map<String, dynamic> json) {
    return MailListItem(
      mailIdx: _int(json['mailIdx']),
      threadIdx: _int(json['threadIdx']),
      direction: _str(json['direction']),
      subject: _str(json['subject']),
      fromEmail: _str(json['fromEmail']),
      fromNm: _str(json['fromNm']),
      toSummary: _str(json['toSummary']),
      snippet: _str(json['snippet']),
      attCnt: _int(json['attCnt']),
      bodyStatus: _str(json['bodyStatus']),
      sendStatus: _str(json['sendStatus']),
      lastStatus: _str(json['lastStatus']),
      read: _bool(json['read']),
      spam: _bool(json['spam']),
      userId: _str(json['userId']),
      // partnerIdx·mappingId 는 "연결 없음"(null)과 "0번"을 구분해야 하므로
      // 다른 필드와 달리 0 으로 뭉개지 않는다(서버 DTO 규약과 동일).
      partnerIdx: _intOrNull(json['partnerIdx']),
      mappingId: _intOrNull(json['mappingId']),
      mailAt: _dateTime(json['mailAt']),
      // 서버가 `starred` 로 줄지 `important` 로 줄지 아직 확정되지 않았다.
      // 둘 다 받아 준다 — 이름이 어긋나면 별표가 **조용히 안 켜지는** 버그가 되고,
      // 그건 오류 화면 하나 없이 "기능이 안 된다"로만 보여서 찾기가 가장 어렵다.
      starred: _bool(
        json['starred'] ?? json['star'] ?? json['important'] ?? json['starYn'],
      ),
      importance: _str(json['importance']),
      scheduledAt: _dateTime(json['scheduledAt']),
      openedAt: _dateTime(json['openedAt'] ?? json['readAt']),
      // 수신확인 **횟수**. 서버가 안 주면 0 이고, 0 이면 화면은 횟수를 아예 안 쓴다
      // ("0회 확인"이라고 찍으면 확인된 메일을 안 열어 본 것처럼 보인다).
      openCnt: _int(json['openCnt']),
      readReceipt: _bool(json['readReceipt'] ?? json['readReceiptYn']),
      folder: _str(json['folder']),
    );
  }

  final int mailIdx;
  final int threadIdx;
  final String direction;
  final String subject;
  final String fromEmail;
  final String fromNm;
  final String toSummary;
  final String snippet;
  final int attCnt;
  final String bodyStatus;
  final String sendStatus;
  final String lastStatus;
  final bool read;
  final bool spam;
  final String userId;
  final int? partnerIdx;
  final int? mappingId;
  final DateTime? mailAt;
  final bool starred;
  final String importance;
  final DateTime? scheduledAt;

  /// 수신확인 시각 — 내가 **보낸** 메일의 확인 픽셀이 처음 호출된 시각.
  /// null 이면 "확인되지 않음"이다. **"안 읽음"이 아니다** — 아래 주석 참고.
  final DateTime? openedAt;

  /// 확인 픽셀 누적 호출 횟수. 0 이면 표시하지 않는다.
  final int openCnt;

  /// 보낼 때 수신확인을 요청한 메일인지. 요청 자체를 안 했으면 "확인되지 않음"이
  /// 아니라 "요청 안 함"으로 보여야 한다.
  final bool readReceipt;

  /// 서버가 알려 주는 현재 메일함. 목록은 이미 폴더별로 부르므로 참고용이다.
  final String folder;

  bool get inbound => direction.toUpperCase() == 'IN';
  bool get outbound => !inbound;

  /// 수신 메일 중 아직 안 읽은 것 — 목록에서 굵게 표시한다.
  bool get unread => inbound && !read;

  bool get hasAttachment => attCnt > 0;

  /// 본문 수집이 끝나지 않은 수신 메일(웹훅은 메타만 주고 본문은 워커가 채운다).
  bool get bodyPending =>
      inbound && bodyStatus.toUpperCase() != 'DONE' && bodyStatus.isNotEmpty;

  bool get bodyFailed => bodyStatus.toUpperCase() == 'FAILED';

  String get subjectLabel => subject.trim().isEmpty ? '(제목 없음)' : subject;

  /// 목록의 "보낸사람/받는사람" 한 칸 — 방향에 따라 보여 줄 사람이 다르다.
  String get counterpartLabel {
    if (inbound) {
      final nm = fromNm.trim();
      final email = fromEmail.trim();
      if (nm.isEmpty) return email.isEmpty ? '-' : email;
      return email.isEmpty ? nm : '$nm <$email>';
    }
    final to = toSummary.trim();
    return to.isEmpty ? '-' : to;
  }

  String get fromLabel {
    final nm = fromNm.trim();
    final email = fromEmail.trim();
    if (nm.isEmpty) return email.isEmpty ? '-' : email;
    return email.isEmpty ? nm : '$nm <$email>';
  }

  String get mailAtLabel => _fmtDateTime(mailAt);
  String get mailAtDateLabel => _fmtDate(mailAt);
  String get scheduledAtLabel => _fmtDateTime(scheduledAt);

  // 서버가 돌려주는 값은 한 글자('H')다. 'HIGH' 로 비교하면 영원히 false 라
  // 중요 표시가 목록·상세에 절대 안 나온다.
  bool get highImportance => importance.toUpperCase() == 'H';

  /// 발송 메일의 수신확인 상태 한 줄(상세 화면용). 수신 메일에는 의미가 없어 빈 문자열.
  ///
  /// **"읽음/읽지 않음"이라고 쓰지 않는다.** 수신확인은 본문에 심은 1픽셀 이미지가
  /// 불러와졌는지로만 판정한다. 그런데
  ///  - 대부분의 웹메일이 외부 이미지를 기본 차단한다 → 읽어도 확인이 안 잡히고,
  ///  - Gmail 등의 이미지 프록시는 메일이 도착하면 미리 받아 간다 → 안 읽어도 잡힌다.
  /// 그래서 이 값이 말할 수 있는 것은 "확인됐다/확인되지 않았다"까지다.
  /// (다우오피스도 같은 한계를 FAQ 로 안내한다.)
  String get readReceiptLabel {
    if (inbound) return '';
    if (openedAt != null) {
      final at = _fmtDateTime(openedAt);
      return openCnt > 1 ? '확인됨 · $at ($openCnt회)' : '확인됨 · $at';
    }
    // `opened` 이벤트가 왔는데 시각이 안 내려온 경우까지 "확인되지 않음"이라고
    // 하면 거짓말이 된다. 이벤트 코드가 열람을 말하면 시각 없이 "확인됨"으로 둔다.
    if (lastStatus.toLowerCase() == 'opened') return '확인됨';
    return '확인되지 않음';
  }

  /// 목록 한 칸에 들어갈 짧은 수신확인 문구 — 확인됐으면 **일시**, 아니면 "미확인".
  String get readReceiptShortLabel {
    if (inbound) return '';
    if (openedAt != null) return _fmtDateTime(openedAt);
    if (lastStatus.toLowerCase() == 'opened') return '확인됨';
    return '미확인';
  }

  bool get opened => openedAt != null || lastStatus.toLowerCase() == 'opened';

  /// 별표 토글처럼 서버 응답을 기다리기 전에 화면만 먼저 바꿔야 할 때 쓴다.
  /// (요청이 실패하면 호출부가 원본으로 되돌린다 — 실패를 삼키지 않는다.)
  MailListItem copyWith({bool? read, bool? spam, bool? starred}) =>
      MailListItem(
        mailIdx: mailIdx,
        threadIdx: threadIdx,
        direction: direction,
        subject: subject,
        fromEmail: fromEmail,
        fromNm: fromNm,
        toSummary: toSummary,
        snippet: snippet,
        attCnt: attCnt,
        bodyStatus: bodyStatus,
        sendStatus: sendStatus,
        lastStatus: lastStatus,
        read: read ?? this.read,
        spam: spam ?? this.spam,
        userId: userId,
        partnerIdx: partnerIdx,
        mappingId: mappingId,
        mailAt: mailAt,
        starred: starred ?? this.starred,
        importance: importance,
        scheduledAt: scheduledAt,
        openedAt: openedAt,
        openCnt: openCnt,
        readReceipt: readReceipt,
        folder: folder,
      );

  /// 화면에 뱃지로 찍을 상태 문구.
  ///
  /// 발신은 `send_status` 가 1차, Resend 이벤트(`last_status`)가 2차다.
  /// 수신은 상태 개념이 없으므로 읽음 여부를 대신 보여 준다.
  String get statusLabel {
    if (spam) return '스팸';
    if (outbound) {
      final send = sendStatus.toUpperCase();
      if (send == 'FAILED') return '발송실패';
      // 예약은 "아직 안 나갔다"는 뜻이라 발송대기와 구분해서 보여 준다 —
      // 사용자가 예약을 취소할 수 있는 마지막 구간이다.
      if (send == 'SCHEDULED' || scheduledAt != null && send != 'SENT') {
        return '예약';
      }
      if (send == 'DRAFT') return '임시저장';
      if (send == 'QUEUED') return '발송대기';
      final last = lastStatusLabel;
      return last.isEmpty ? '발송완료' : last;
    }
    if (bodyFailed) return '본문실패';
    if (bodyPending) return '본문수집중';
    return read ? '읽음' : '안읽음';
  }

  /// Resend 이벤트 코드(`delivered`, `bounced` …)를 한글로. 모르면 빈 문자열.
  String get lastStatusLabel => switch (lastStatus.toLowerCase()) {
    'scheduled' => '예약',
    'sent' => '발송완료',
    'delivery_delayed' => '전달지연',
    'delivered' => '전달완료',
    'opened' => '열람',
    'clicked' => '클릭',
    'bounced' => '반송',
    'complained' => '스팸신고',
    'failed' => '발송실패',
    'suppressed' => '차단',
    _ => '',
  };
}

/// 참여자 — 백엔드 `MailAddressDto`.
class MailAddress {
  const MailAddress({
    required this.addrType,
    required this.seq,
    required this.email,
    required this.dispNm,
  });

  factory MailAddress.fromJson(Map<String, dynamic> json) => MailAddress(
    addrType: _str(json['addrType']),
    seq: _int(json['seq']),
    email: _str(json['email']),
    dispNm: _str(json['dispNm']),
  );

  final String addrType;
  final int seq;
  final String email;
  final String dispNm;

  /// `TO` / `CC` / `BCC` / `FROM` / `REPLY_TO` — 구분자는 서버가 정하므로
  /// 하이픈·언더스코어를 모두 받아들이고 대문자로 맞춰 비교한다.
  String get normalizedType =>
      addrType.trim().toUpperCase().replaceAll('-', '_');

  String get label {
    final nm = dispNm.trim();
    if (nm.isEmpty) return email;
    return '$nm <$email>';
  }

  String get typeLabel => switch (normalizedType) {
    'FROM' => '보낸사람',
    'TO' => '받는사람',
    'CC' => '참조',
    'BCC' => '숨은참조',
    'REPLY_TO' => '회신주소',
    _ => addrType,
  };
}

/// 첨부 — 백엔드 `MailAttachmentDto`.
class MailAttachment {
  const MailAttachment({
    required this.mailAttIdx,
    required this.mailIdx,
    required this.fileName,
    required this.fileSize,
    required this.contentType,
    required this.contentId,
    required this.inline,
    required this.downloadable,
    this.fetchedAt,
  });

  factory MailAttachment.fromJson(Map<String, dynamic> json) => MailAttachment(
    mailAttIdx: _int(json['mailAttIdx']),
    mailIdx: _int(json['mailIdx']),
    fileName: _str(json['fileName']),
    fileSize: _int(json['fileSize']),
    contentType: _str(json['contentType']),
    contentId: _str(json['contentId']),
    inline: _bool(json['inline']),
    downloadable: _bool(json['downloadable']),
    // fetchedAt 은 "아직 안 받았다"(null)와 "받았다"를 구분하는 유일한 신호라
    // 기본값으로 채우지 않는다.
    fetchedAt: _dateTime(json['fetchedAt']),
  );

  final int mailAttIdx;
  final int mailIdx;
  final String fileName;
  final int fileSize;
  final String contentType;
  final String contentId;
  final bool inline;
  final bool downloadable;
  final DateTime? fetchedAt;

  String get fileNameLabel => fileName.trim().isEmpty ? '(이름 없음)' : fileName;

  String get sizeLabel {
    if (fileSize <= 0) return '-';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 수신 첨부는 워커가 Resend 에서 내려받아야 열 수 있다. 아직이면 이유를 보여 준다.
  String get pendingReason =>
      downloadable ? '' : (fetchedAt == null ? '수집 대기중' : '내려받을 수 없음');
}

/// 발송 이벤트 이력 — 백엔드 `MailEventDto`.
class MailEvent {
  const MailEvent({
    required this.eventIdx,
    required this.eventType,
    required this.recipient,
    required this.detail,
    this.occurredAt,
  });

  factory MailEvent.fromJson(Map<String, dynamic> json) => MailEvent(
    eventIdx: _int(json['eventIdx']),
    eventType: _str(json['eventType']),
    recipient: _str(json['recipient']),
    detail: _str(json['detail']),
    occurredAt: _dateTime(json['occurredAt']),
  );

  final int eventIdx;
  final String eventType;
  final String recipient;
  final String detail;
  final DateTime? occurredAt;

  /// 서버는 `email.` 접두를 뗀 값(`delivered`, `bounced` …)을 저장한다.
  String get typeLabel => switch (eventType.toLowerCase()) {
    'received' => '수신',
    'scheduled' => '예약',
    'sent' => '발송',
    'delivery_delayed' => '전달지연',
    'delivered' => '전달완료',
    'opened' => '열람',
    'clicked' => '클릭',
    'bounced' => '반송',
    'complained' => '스팸신고',
    'failed' => '실패',
    'suppressed' => '차단',
    _ => eventType,
  };

  String get occurredAtLabel => _fmtDateTime(occurredAt);
}

/// 상세 — 백엔드 `MailDetailDto`. 목록 한 줄(`summary`)을 그대로 품고 있다.
class MailDetail {
  const MailDetail({
    required this.summary,
    required this.bodyText,
    required this.bodyHtml,
    required this.truncated,
    required this.headersRaw,
    required this.rfcMessageId,
    required this.inReplyTo,
    required this.bodyErr,
    required this.sendErr,
    required this.addresses,
    required this.attachments,
    required this.events,
  });

  factory MailDetail.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['summary'];
    final summaryMap = rawSummary is Map
        ? Map<String, dynamic>.from(rawSummary)
        : <String, dynamic>{};
    return MailDetail(
      summary: MailListItem.fromJson(summaryMap),
      bodyText: _str(json['bodyText']),
      bodyHtml: _str(json['bodyHtml']),
      truncated: _bool(json['truncated']),
      headersRaw: _str(json['headersRaw']),
      rfcMessageId: _str(json['rfcMessageId']),
      inReplyTo: _str(json['inReplyTo']),
      bodyErr: _str(json['bodyErr']),
      sendErr: _str(json['sendErr']),
      addresses: _mapList(
        json['addresses'],
      ).map(MailAddress.fromJson).toList(growable: false),
      attachments: _mapList(
        json['attachments'],
      ).map(MailAttachment.fromJson).toList(growable: false),
      events: _mapList(
        json['events'],
      ).map(MailEvent.fromJson).toList(growable: false),
    );
  }

  final MailListItem summary;
  final String bodyText;
  final String bodyHtml;
  final bool truncated;
  final String headersRaw;
  final String rfcMessageId;
  final String inReplyTo;
  final String bodyErr;
  final String sendErr;
  final List<MailAddress> addresses;
  final List<MailAttachment> attachments;
  final List<MailEvent> events;

  int get mailIdx => summary.mailIdx;

  List<MailAddress> addressesOf(String type) {
    final want = type.trim().toUpperCase().replaceAll('-', '_');
    final rows = addresses.where((a) => a.normalizedType == want).toList()
      ..sort((a, b) => a.seq.compareTo(b.seq));
    return rows;
  }

  String _joinAddresses(String type) =>
      addressesOf(type).map((a) => a.label).join(', ');

  String get toLine => _joinAddresses('TO');
  String get ccLine => _joinAddresses('CC');
  String get bccLine => _joinAddresses('BCC');
  String get replyToLine => _joinAddresses('REPLY_TO');

  bool get hasHtml => bodyHtml.trim().isNotEmpty;
  bool get hasText => bodyText.trim().isNotEmpty;

  /// 화면에 실패 사유를 그대로 노출하기 위한 한 줄. 없으면 빈 문자열.
  String get errorLine {
    final parts = <String>[
      if (bodyErr.trim().isNotEmpty) '본문 수집 실패: ${bodyErr.trim()}',
      if (sendErr.trim().isNotEmpty) '발송 실패: ${sendErr.trim()}',
    ];
    return parts.join('\n');
  }

  /// 답장 시 기본 수신자 — 회신주소가 있으면 그쪽이 우선이다(RFC 규약).
  List<String> get replyRecipients {
    final replyTo = addressesOf(
      'REPLY_TO',
    ).map((a) => a.email).where((e) => e.trim().isNotEmpty).toList();
    if (replyTo.isNotEmpty) return replyTo;
    final from = summary.fromEmail.trim();
    return from.isEmpty ? const [] : [from];
  }
}

/// 메일함 건수 — 백엔드 `MailCountsDto`.
class MailCounts {
  const MailCounts({
    required this.inbox,
    required this.inboxUnread,
    required this.sent,
    required this.draft,
    required this.failed,
    required this.spam,
    this.scheduled = 0,
    this.trash = 0,
  });

  factory MailCounts.fromJson(Map<String, dynamic> json) => MailCounts(
    inbox: _int(json['inbox']),
    inboxUnread: _int(json['inboxUnread']),
    sent: _int(json['sent']),
    draft: _int(json['draft']),
    failed: _int(json['failed']),
    spam: _int(json['spam']),
    // 예약·휴지통은 서버가 아직 안 줄 수 있다. 없으면 0 이고, 0 은 뱃지를
    // 아예 안 그리므로 "없는 기능"이 "0건"으로 잘못 보이지 않는다.
    scheduled: _int(json['scheduled']),
    trash: _int(json['trash']),
  );

  static const MailCounts empty = MailCounts(
    inbox: 0,
    inboxUnread: 0,
    sent: 0,
    draft: 0,
    failed: 0,
    spam: 0,
  );

  final int inbox;
  final int inboxUnread;
  final int sent;
  final int draft;
  final int failed;
  final int spam;
  final int scheduled;
  final int trash;

  int countOf(String folder) => switch (folder) {
    MailFolders.inbox => inbox,
    MailFolders.sent => sent,
    MailFolders.draft => draft,
    MailFolders.scheduled => scheduled,
    MailFolders.failed => failed,
    MailFolders.spam => spam,
    MailFolders.trash => trash,
    _ => 0,
  };

  /// 사이드바 뱃지에 쓸 값 — **안 읽은 건수만** 뱃지로 띄운다.
  /// 전체 건수를 띄우면 숫자가 늘 커서 아무도 안 보게 된다.
  int badgeCountOf(String folder) =>
      folder == MailFolders.inbox ? inboxUnread : 0;
}

/// 스레드 — 백엔드 `MailThreadDto`.
class MailThread {
  const MailThread({
    required this.threadIdx,
    required this.subjectNorm,
    required this.mailCnt,
    required this.mails,
    this.firstMailAt,
    this.lastMailAt,
  });

  factory MailThread.fromJson(Map<String, dynamic> json) => MailThread(
    threadIdx: _int(json['threadIdx']),
    subjectNorm: _str(json['subjectNorm']),
    mailCnt: _int(json['mailCnt']),
    firstMailAt: _dateTime(json['firstMailAt']),
    lastMailAt: _dateTime(json['lastMailAt']),
    mails: _mapList(
      json['mails'],
    ).map(MailListItem.fromJson).toList(growable: false),
  );

  final int threadIdx;
  final String subjectNorm;
  final int mailCnt;
  final DateTime? firstMailAt;
  final DateTime? lastMailAt;
  final List<MailListItem> mails;

  String get subjectLabel =>
      subjectNorm.trim().isEmpty ? '(제목 없음)' : subjectNorm;

  String get lastMailAtLabel => _fmtDateTime(lastMailAt);
}

/// 작성·발송 결과 — 백엔드 `MailSendResultDto`.
class MailSendResult {
  const MailSendResult({
    required this.mailIdx,
    required this.sendStatus,
    required this.resendEmailId,
    required this.message,
  });

  factory MailSendResult.fromJson(Map<String, dynamic> json) => MailSendResult(
    mailIdx: _int(json['mailIdx']),
    sendStatus: _str(json['sendStatus']),
    resendEmailId: _str(json['resendEmailId']),
    message: _str(json['message']),
  );

  final int mailIdx;
  final String sendStatus;
  final String resendEmailId;
  final String message;

  bool get queued => sendStatus.toUpperCase() == 'QUEUED';
  bool get sent => sendStatus.toUpperCase() == 'SENT';
  bool get draft => sendStatus.toUpperCase() == 'DRAFT';
}

/// 작성 요청 — 백엔드 `MailSendRequestDto` (요청 전용, `toJson` 만 있다).
class MailSendRequest {
  const MailSendRequest({
    required this.to,
    required this.subject,
    this.fromEmail = '',
    this.fromNm = '',
    this.cc = const [],
    this.bcc = const [],
    this.replyTo = const [],
    this.bodyText = '',
    this.bodyHtml = '',
    this.replyToMailIdx,
    this.partnerIdx,
    this.mappingId,
    this.sendNow = true,
    this.scheduledAt,
    this.requestReadReceipt = false,
    this.importance = '',
    this.forward = false,
  });

  final List<String> to;
  final String subject;
  final String fromEmail;
  final String fromNm;
  final List<String> cc;
  final List<String> bcc;
  final List<String> replyTo;
  final String bodyText;
  final String bodyHtml;

  /// 답장일 때 원본 mail_idx — 서버가 스레드·In-Reply-To 를 여기서 잇는다.
  final int? replyToMailIdx;
  final int? partnerIdx;
  final int? mappingId;

  /// false 면 DRAFT 로만 저장한다(첨부를 붙이려면 mail_idx 가 먼저 필요하다).
  final bool sendNow;

  /// 예약발송 시각. null 이면 즉시 발송.
  final DateTime? scheduledAt;

  final bool requestReadReceipt;

  /// `HIGH` / `LOW`. 보통이면 빈 문자열로 두고 아예 안 보낸다.
  final String importance;

  /// 전달(Forward) 여부 — 서버가 답장과 다르게 스레드를 잇도록 구분해 준다.
  final bool forward;

  /// 비어 있는 값은 아예 보내지 않는다. 서버 DTO 가 전부 nullable 이라
  /// `""` 를 보내면 "빈 값으로 덮어쓰라"는 뜻이 되어 기본 발신 주소가 날아간다.
  Map<String, dynamic> toJson() => {
    if (fromEmail.trim().isNotEmpty) 'fromEmail': fromEmail.trim(),
    if (fromNm.trim().isNotEmpty) 'fromNm': fromNm.trim(),
    'to': to,
    if (cc.isNotEmpty) 'cc': cc,
    if (bcc.isNotEmpty) 'bcc': bcc,
    if (replyTo.isNotEmpty) 'replyTo': replyTo,
    'subject': subject,
    if (bodyHtml.trim().isNotEmpty) 'bodyHtml': bodyHtml,
    if (bodyText.trim().isNotEmpty) 'bodyText': bodyText,
    if (replyToMailIdx != null) 'replyToMailIdx': replyToMailIdx,
    if (partnerIdx != null) 'partnerIdx': partnerIdx,
    if (mappingId != null) 'mappingId': mappingId,
    'sendNow': sendNow,
    // 예약 시각은 **UTC ISO8601** 로 보낸다. 로컬 시각을 그대로 보내면 서버가
    // 자기 타임존으로 읽어서 9시간 어긋난 시각에 메일이 나간다.
    if (scheduledAt != null)
      'scheduledAt': scheduledAt!.toUtc().toIso8601String(),
    if (requestReadReceipt) 'requestReadReceipt': true,
    if (importance.trim().isNotEmpty) 'importance': importance.trim(),
    if (forward) 'forward': true,
  };
}

/// 받는사람 자동완성 후보 — `GET /mail/recipients?q=`.
///
/// 직원·거래처·부서를 한 목록으로 돌려받는다. **부서를 고르면 부서원 전체가
/// 수신자로 들어간다** — 72명 조직에서 가장 자주 쓰는 기능이라 [members] 를
/// 후보에 함께 담아 두고, 화면은 서버를 한 번 더 부르지 않고 바로 펼친다.
class MailRecipient {
  const MailRecipient({
    required this.kind,
    required this.id,
    required this.name,
    required this.email,
    required this.deptNm,
    required this.members,
  });

  factory MailRecipient.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final members = <MailRecipient>[];
    if (rawMembers is List) {
      for (final m in rawMembers) {
        if (m is Map) {
          members.add(MailRecipient.fromJson(Map<String, dynamic>.from(m)));
        } else if (m is String && m.trim().isNotEmpty) {
          // 서버가 이메일 문자열 배열만 줄 수도 있다. 그 경우도 받아 준다.
          members.add(
            MailRecipient(
              kind: kindUser,
              id: m.trim(),
              name: '',
              email: m.trim(),
              deptNm: '',
              members: const [],
            ),
          );
        }
      }
    }
    return MailRecipient(
      kind: _str(json['kind'] ?? json['type']).toUpperCase(),
      id: _str(json['id'] ?? json['userId'] ?? json['deptCd']),
      name: _str(json['name'] ?? json['userNm'] ?? json['deptNm']),
      email: _str(json['email']),
      deptNm: _str(json['deptNm']),
      members: List<MailRecipient>.unmodifiable(members),
    );
  }

  static const String kindUser = 'USER';
  static const String kindPartner = 'PARTNER';
  static const String kindDept = 'DEPT';

  final String kind;
  final String id;
  final String name;
  final String email;
  final String deptNm;

  /// 부서 후보일 때의 부서원. 직원·거래처면 비어 있다.
  final List<MailRecipient> members;

  bool get isDept => kind == kindDept;

  String get kindLabel => switch (kind) {
    kindUser => '직원',
    kindPartner => '거래처',
    kindDept => '부서',
    _ => '',
  };

  /// 이 후보를 고르면 실제로 수신자로 들어갈 주소들.
  List<String> get emails {
    if (isDept) {
      return members
          .map((m) => m.email.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    final e = email.trim();
    return e.isEmpty ? const [] : [e];
  }

  /// 목록에 보여 줄 한 줄.
  String get label {
    final nm = name.trim();
    if (isDept) {
      final n = members.length;
      return n > 0 ? '$nm (부서원 $n명)' : nm;
    }
    if (nm.isEmpty) return email;
    final dept = deptNm.trim();
    return dept.isEmpty ? '$nm <$email>' : '$nm ($dept) <$email>';
  }
}

/// 서명 — `GET /mail/signatures`.
class MailSignature {
  const MailSignature({
    required this.signIdx,
    required this.signNm,
    required this.bodyText,
    required this.bodyHtml,
    required this.defaultForNew,
    required this.defaultForReply,
  });

  factory MailSignature.fromJson(Map<String, dynamic> json) => MailSignature(
    signIdx: _int(json['signIdx'] ?? json['id']),
    signNm: _str(json['signNm'] ?? json['name']),
    bodyText: _str(json['bodyText']),
    bodyHtml: _str(json['bodyHtml']),
    defaultForNew: _bool(json['defaultForNew']),
    defaultForReply: _bool(json['defaultForReply']),
  );

  final int signIdx;
  final String signNm;
  final String bodyText;
  final String bodyHtml;
  final bool defaultForNew;
  final bool defaultForReply;

  String get signNmLabel => signNm.trim().isEmpty ? '(이름 없음)' : signNm;

  /// 평문 본문에 끼워 넣을 내용. HTML 만 있으면 태그를 걷어 낸다.
  String get insertText {
    final t = bodyText.trim();
    if (t.isNotEmpty) return t;
    return stripHtmlToText(bodyHtml);
  }

  Map<String, dynamic> toJson() => {
    if (signIdx > 0) 'signIdx': signIdx,
    'signNm': signNm.trim(),
    'bodyText': bodyText,
    if (bodyHtml.trim().isNotEmpty) 'bodyHtml': bodyHtml,
    'defaultForNew': defaultForNew,
    'defaultForReply': defaultForReply,
  };
}

/// 사용자 정의 메일함 — `GET /mail/folders`.
class MailUserFolder {
  const MailUserFolder({
    required this.folderIdx,
    required this.folderNm,
    required this.sortOrder,
    required this.mailCnt,
  });

  factory MailUserFolder.fromJson(Map<String, dynamic> json) => MailUserFolder(
    folderIdx: _int(json['folderIdx'] ?? json['id']),
    folderNm: _str(json['folderNm'] ?? json['name']),
    sortOrder: _int(json['sortOrder']),
    mailCnt: _int(json['mailCnt']),
  );

  final int folderIdx;
  final String folderNm;
  final int sortOrder;
  final int mailCnt;

  String get folderNmLabel => folderNm.trim().isEmpty ? '(이름 없음)' : folderNm;

  Map<String, dynamic> toJson() => {
    if (folderIdx > 0) 'folderIdx': folderIdx,
    'folderNm': folderNm.trim(),
    'sortOrder': sortOrder,
  };
}

/// 개인 환경설정 — `GET /mail/preferences`.
class MailPreferences {
  const MailPreferences({
    this.confirmBeforeSend = false,
    this.warnExternalRecipients = false,
    this.requestReadReceiptByDefault = false,
    this.blockExternalImages = true,
    this.pageSize = 50,
    this.defaultSignIdx,
  });

  factory MailPreferences.fromJson(Map<String, dynamic> json) =>
      MailPreferences(
        // 발송 확인·외부수신자 경고는 기본 꺼짐이다. 거래처 대부분이 외부
        // 주소라 매번 팝업이 뜨면 확인 없이 넘기는 습관만 들고, 정작 필요할 때
        // (내부 문서를 실수로 사외에 보낼 때) 도 무시하게 된다. 원하는 사용자는
        // 메일설정에서 각자 켜면 된다. 외부 이미지 차단(추적픽셀 방어)은 그대로 켜 둔다.
        confirmBeforeSend: json.containsKey('confirmBeforeSend')
            ? _bool(json['confirmBeforeSend'])
            : false,
        warnExternalRecipients: json.containsKey('warnExternalRecipients')
            ? _bool(json['warnExternalRecipients'])
            : false,
        requestReadReceiptByDefault: _bool(
          json['requestReadReceiptByDefault'],
        ),
        blockExternalImages: json.containsKey('blockExternalImages')
            ? _bool(json['blockExternalImages'])
            : true,
        pageSize: _int(json['pageSize']) == 0 ? 50 : _int(json['pageSize']),
        defaultSignIdx: _intOrNull(json['defaultSignIdx']),
      );

  static const MailPreferences defaults = MailPreferences();

  final bool confirmBeforeSend;
  final bool warnExternalRecipients;
  final bool requestReadReceiptByDefault;
  final bool blockExternalImages;
  final int pageSize;
  final int? defaultSignIdx;

  MailPreferences copyWith({
    bool? confirmBeforeSend,
    bool? warnExternalRecipients,
    bool? requestReadReceiptByDefault,
    bool? blockExternalImages,
    int? pageSize,
    int? defaultSignIdx,
  }) => MailPreferences(
    confirmBeforeSend: confirmBeforeSend ?? this.confirmBeforeSend,
    warnExternalRecipients:
        warnExternalRecipients ?? this.warnExternalRecipients,
    requestReadReceiptByDefault:
        requestReadReceiptByDefault ?? this.requestReadReceiptByDefault,
    blockExternalImages: blockExternalImages ?? this.blockExternalImages,
    pageSize: pageSize ?? this.pageSize,
    defaultSignIdx: defaultSignIdx ?? this.defaultSignIdx,
  );

  Map<String, dynamic> toJson() => {
    'confirmBeforeSend': confirmBeforeSend,
    'warnExternalRecipients': warnExternalRecipients,
    'requestReadReceiptByDefault': requestReadReceiptByDefault,
    'blockExternalImages': blockExternalImages,
    'pageSize': pageSize,
    if (defaultSignIdx != null) 'defaultSignIdx': defaultSignIdx,
  };
}

/// 일괄 처리 결과 — `POST /mail/messages/bulk`.
///
/// [affected] 를 반드시 확인한다. 요청 10건에 처리 0건이면 **성공이 아니다** —
/// 화면은 "10건 처리했습니다" 대신 사유를 물어보게 만들어야 한다.
class MailBulkResult {
  const MailBulkResult({
    required this.requested,
    required this.affected,
    required this.message,
  });

  factory MailBulkResult.fromJson(Map<String, dynamic> json) => MailBulkResult(
    requested: _int(json['requested']),
    affected: _int(json['affected'] ?? json['updated'] ?? json['count']),
    message: _str(json['message']),
  );

  final int requested;
  final int affected;
  final String message;
}

// ───────────────────────── 자동분류(규칙) ─────────────────────────

/// 자동분류 규칙이 할 수 있는 처리 — `GET /mail/rules` 의 `actionType`.
///
/// **규칙 하나당 처리 하나**다. 다우오피스도 같다. "이동하고 읽음처리까지" 를
/// 허용하면 규칙 순서가 꼬였을 때 어디로 갔는지 추적할 수 없다.
abstract final class MailRuleActions {
  /// 지정한 사용자 메일함으로 옮긴다.
  static const String move = 'move';

  /// 읽음으로 표시만 한다(메일함은 그대로).
  static const String read = 'read';

  static String labelOf(String action) => switch (action) {
    move => '메일함 이동',
    read => '읽음처리',
    _ => action,
  };

  static const List<String> all = <String>[move, read];
}

/// 자동분류 규칙 한 건 — `GET /mail/rules`.
///
/// 조건은 **AND 로만** 묶인다(다우오피스와 같다). 비어 있는 조건은 무시한다.
/// OR 이 필요하면 규칙을 두 개 만드는 것이 사용자에게도 훨씬 읽기 쉽다.
class MailRule {
  const MailRule({
    required this.ruleIdx,
    required this.ruleNm,
    required this.enabled,
    required this.sortOrder,
    required this.fromContains,
    required this.toContains,
    required this.subjectContains,
    required this.actionType,
    this.targetFolderIdx,
    this.targetFolderNm = '',
  });

  factory MailRule.fromJson(Map<String, dynamic> json) => MailRule(
    ruleIdx: _int(json['ruleIdx'] ?? json['id']),
    ruleNm: _str(json['ruleNm'] ?? json['name']),
    // 서버가 필드를 안 주면 **켜진 것으로 본다** — 목록에 보이는 규칙이 실제로는
    // 안 도는 상태가 가장 찾기 어렵다.
    enabled: json.containsKey('enabled') || json.containsKey('useYn')
        ? _bool(json['enabled'] ?? json['useYn'])
        : true,
    sortOrder: _int(json['sortOrder']),
    fromContains: _str(json['fromContains']),
    toContains: _str(json['toContains']),
    subjectContains: _str(json['subjectContains']),
    actionType: _str(json['actionType']).isEmpty
        ? MailRuleActions.move
        : _str(json['actionType']),
    targetFolderIdx: _intOrNull(json['targetFolderIdx']),
    targetFolderNm: _str(json['targetFolderNm']),
  );

  final int ruleIdx;
  final String ruleNm;
  final bool enabled;
  final int sortOrder;

  /// 보낸사람에 이 문자열이 들어가면 — 빈 값이면 이 조건은 안 본다.
  final String fromContains;

  /// 수신자(To/Cc)에 이 문자열이 들어가면.
  final String toContains;

  /// 제목에 이 문자열이 들어가면.
  final String subjectContains;

  final String actionType;
  final int? targetFolderIdx;
  final String targetFolderNm;

  String get ruleNmLabel => ruleNm.trim().isEmpty ? '(이름 없음)' : ruleNm;

  bool get isMove => actionType == MailRuleActions.move;

  /// 조건이 하나도 없으면 **모든 메일**에 걸린다. 저장 전에 막아야 한다.
  bool get hasCondition =>
      fromContains.trim().isNotEmpty ||
      toContains.trim().isNotEmpty ||
      subjectContains.trim().isNotEmpty;

  /// "보낸사람에 a, 제목에 b" 처럼 사람이 읽는 한 줄.
  String get conditionLabel {
    final parts = <String>[
      if (fromContains.trim().isNotEmpty) '보낸사람 「${fromContains.trim()}」',
      if (toContains.trim().isNotEmpty) '수신자 「${toContains.trim()}」',
      if (subjectContains.trim().isNotEmpty) '제목 「${subjectContains.trim()}」',
    ];
    if (parts.isEmpty) return '조건 없음 (모든 메일)';
    // AND 라는 사실을 문장에 드러낸다. "그리고"를 빼면 OR 로 오해한다.
    return parts.join(' 그리고 ');
  }

  String get actionLabel {
    if (!isMove) return MailRuleActions.labelOf(actionType);
    final nm = targetFolderNm.trim();
    return nm.isEmpty ? '메일함 이동' : '「$nm」(으)로 이동';
  }

  MailRule copyWith({
    String? ruleNm,
    bool? enabled,
    int? sortOrder,
    String? fromContains,
    String? toContains,
    String? subjectContains,
    String? actionType,
    int? targetFolderIdx,
    String? targetFolderNm,
  }) => MailRule(
    ruleIdx: ruleIdx,
    ruleNm: ruleNm ?? this.ruleNm,
    enabled: enabled ?? this.enabled,
    sortOrder: sortOrder ?? this.sortOrder,
    fromContains: fromContains ?? this.fromContains,
    toContains: toContains ?? this.toContains,
    subjectContains: subjectContains ?? this.subjectContains,
    actionType: actionType ?? this.actionType,
    targetFolderIdx: targetFolderIdx ?? this.targetFolderIdx,
    targetFolderNm: targetFolderNm ?? this.targetFolderNm,
  );

  /// 빈 조건은 **키 자체를 보내지 않는다**. `""` 를 보내면 서버가 "빈 문자열을
  /// 포함하는 메일"로 읽어 모든 메일에 걸릴 수 있다.
  Map<String, dynamic> toJson() => {
    if (ruleIdx > 0) 'ruleIdx': ruleIdx,
    'ruleNm': ruleNm.trim(),
    'enabled': enabled,
    'sortOrder': sortOrder,
    if (fromContains.trim().isNotEmpty) 'fromContains': fromContains.trim(),
    if (toContains.trim().isNotEmpty) 'toContains': toContains.trim(),
    if (subjectContains.trim().isNotEmpty)
      'subjectContains': subjectContains.trim(),
    'actionType': actionType,
    if (isMove && targetFolderIdx != null) 'targetFolderIdx': targetFolderIdx,
  };
}

// ───────────────────────── 자동전달 ─────────────────────────

/// 전체 자동전달 설정 — `GET/PUT /mail/forward`.
class MailForwardSetting {
  const MailForwardSetting({
    this.enabled = false,
    this.forwardTo = '',
    this.keepOriginal = true,
  });

  factory MailForwardSetting.fromJson(Map<String, dynamic> json) =>
      MailForwardSetting(
        enabled: _bool(json['enabled'] ?? json['useYn']),
        forwardTo: _str(json['forwardTo']),
        // 기본은 **원본을 남기는 쪽**이다. 서버가 값을 안 주는데 "삭제"로 시작하면
        // 사용자가 모르는 사이에 받은메일함이 비어 간다.
        keepOriginal: json.containsKey('keepOriginal')
            ? _bool(json['keepOriginal'])
            : true,
      );

  static const MailForwardSetting off = MailForwardSetting();

  final bool enabled;
  final String forwardTo;

  /// true = 내 메일함에도 남긴다 / false = 전달 후 원본을 지운다.
  final bool keepOriginal;

  MailForwardSetting copyWith({
    bool? enabled,
    String? forwardTo,
    bool? keepOriginal,
  }) => MailForwardSetting(
    enabled: enabled ?? this.enabled,
    forwardTo: forwardTo ?? this.forwardTo,
    keepOriginal: keepOriginal ?? this.keepOriginal,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'forwardTo': forwardTo.trim(),
    'keepOriginal': keepOriginal,
  };
}

/// 자동전달 예외 규칙의 판정 기준.
abstract final class MailForwardMatchTypes {
  /// 주소 하나가 정확히 일치할 때.
  static const String address = 'address';

  /// `@` 뒤 도메인이 같을 때.
  static const String domain = 'domain';

  static String labelOf(String type) => switch (type) {
    address => '보낸사람 주소',
    domain => '보낸사람 도메인',
    _ => type,
  };

  static String hintOf(String type) => switch (type) {
    address => '예) partner@example.com',
    domain => '예) example.com',
    _ => '',
  };

  static const List<String> all = <String>[address, domain];
}

/// 자동전달 예외 규칙 — `GET /mail/forward/rules`.
///
/// "이 거래처 메일만 다른 담당자에게" 같은 용도다. 전체 자동전달보다 **먼저** 본다.
class MailForwardRule {
  const MailForwardRule({
    required this.ruleIdx,
    required this.matchType,
    required this.matchValue,
    required this.forwardTo,
    required this.enabled,
    this.sortOrder = 0,
  });

  factory MailForwardRule.fromJson(Map<String, dynamic> json) =>
      MailForwardRule(
        ruleIdx: _int(json['ruleIdx'] ?? json['id']),
        matchType: _str(json['matchType']).isEmpty
            ? MailForwardMatchTypes.address
            : _str(json['matchType']),
        matchValue: _str(json['matchValue']),
        forwardTo: _str(json['forwardTo']),
        enabled: json.containsKey('enabled') || json.containsKey('useYn')
            ? _bool(json['enabled'] ?? json['useYn'])
            : true,
        sortOrder: _int(json['sortOrder']),
      );

  final int ruleIdx;
  final String matchType;
  final String matchValue;
  final String forwardTo;
  final bool enabled;
  final int sortOrder;

  String get matchLabel =>
      '${MailForwardMatchTypes.labelOf(matchType)} 「${matchValue.trim()}」';

  MailForwardRule copyWith({
    String? matchType,
    String? matchValue,
    String? forwardTo,
    bool? enabled,
  }) => MailForwardRule(
    ruleIdx: ruleIdx,
    matchType: matchType ?? this.matchType,
    matchValue: matchValue ?? this.matchValue,
    forwardTo: forwardTo ?? this.forwardTo,
    enabled: enabled ?? this.enabled,
    sortOrder: sortOrder,
  );

  Map<String, dynamic> toJson() => {
    if (ruleIdx > 0) 'ruleIdx': ruleIdx,
    'matchType': matchType,
    'matchValue': matchValue.trim(),
    'forwardTo': forwardTo.trim(),
    'enabled': enabled,
    'sortOrder': sortOrder,
  };
}

/// 예외 규칙 상한. 서버와 같은 값이어야 한다 —
/// 화면에서 11개째를 만들게 두면 저장 순간에야 거절당해 입력이 통째로 날아간다.
const int kMailForwardRuleMax = 10;

/// 메일 주소 형식인지 — 자동전달 주소를 저장하기 전에 막는 최소한의 검사.
///
/// 완벽한 RFC 검증이 아니다(그건 서버 몫이다). 오타 하나로 회사 메일이 엉뚱한
/// 곳으로 새는 것을 막는 것이 목적이라 `a@b.c` 꼴만 통과시킨다.
bool isLikelyEmail(String value) {
  final v = value.trim();
  if (v.isEmpty) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
}

/// HTML 을 사람이 읽을 평문으로. 서명 미리보기·인용문에 쓴다.
///
/// **보안 목적이 아니다.** 본문을 화면에 그릴 때의 sanitize 는
/// `mal001_html_sanitize.dart` 를 쓴다.
String stripHtmlToText(String html) {
  if (html.trim().isEmpty) return '';
  var s = html;
  s = s.replaceAll(
    RegExp(r'<(script|style)[^>]*>.*?</\1>', caseSensitive: false, dotAll: true),
    '',
  );
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');
  s = s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  return s.trim();
}
