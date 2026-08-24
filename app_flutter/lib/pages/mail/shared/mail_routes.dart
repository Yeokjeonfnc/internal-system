// 메일(mal001) — SPA 경로 상수.
//
// 전자결재([EapRoutes])와 같은 방식이다. 라우터에는 얇은 `GoRoute` 만 등록하고
// 실제 화면 선택은 셸([MailShell])이 경로를 보고 한다. 그래야 목록 → 상세 →
// 작성으로 오갈 때 상단 히스토리 탭이 하나로 유지된다.
//
// 메일함은 **경로 하나 = 사이드바 메뉴 하나**다. 예전에는 `/mail` 하나에 화면
// 안쪽 탭으로 메일함을 갈아 끼웠는데, 메일함을 옮길 때마다 메일 화면에 들어가
// 탭을 다시 골라야 해서 불편했다. 지금은 DB 메뉴 트리(grp_mail 아래 mal001~mal008)와
// 경로가 1:1 로 대응하고, 그 대응표는 `core/menu/menu_route_access.dart` 에 있다.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';

abstract final class MailRoutes {
  static const String root = '/mail';

  static const String inbox = '$root/inbox';
  static const String sent = '$root/sent';
  static const String draft = '$root/draft';
  static const String scheduled = '$root/scheduled';
  static const String spam = '$root/spam';
  static const String trash = '$root/trash';
  static const String all = '$root/all';
  static const String settings = '$root/settings';
  static const String compose = '$root/compose';

  /// 사이드바에 뜨는 메일함 경로들(설정 제외). 라우터 등록·이동 메뉴에서 함께 쓴다.
  static const List<String> folderPaths = <String>[
    inbox,
    sent,
    draft,
    scheduled,
    spam,
    trash,
    all,
  ];

  /// 상세 경로. [folder] 를 함께 넘기면 상세에서 **그 메일함 기준으로** 이전/다음
  /// 메일을 오갈 수 있다. 안 넘기면 상세는 수신/발신 방향으로 메일함을 추측한다.
  static String detail(int mailIdx, {String? folder}) {
    final f = folder?.trim() ?? '';
    if (f.isEmpty) return '$root/m/$mailIdx';
    return '$root/m/$mailIdx?folder=${Uri.encodeQueryComponent(f)}';
  }

  /// `/mail/m/123` → 123. 형식이 다르면 null(상세가 아니라는 뜻).
  static int? mailIdxFromPath(String path) {
    const prefix = '$root/m/';
    if (!path.startsWith(prefix)) return null;
    final raw = path.substring(prefix.length);
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  /// 답장 — 원본 mail_idx 를 **쿼리로** 넘긴다.
  ///
  /// 경로 파라미터로 하지 않는 이유: 작성 화면은 라우트가 하나뿐인데(셸 방식)
  /// "새 메일"과 "답장"이 같은 위젯을 공유해야 한다. 쿼리면 같은 GoRoute 로
  /// 처리되고, 셸에서 `ValueKey(query['reply'])` 만으로 상태를 갈아끼울 수 있다.
  static String composeReply(int mailIdx) => '$compose?reply=$mailIdx';

  /// 전체답장 — 참조까지 모두 수신자로 끌어온다.
  static String composeReplyAll(int mailIdx) =>
      '$compose?reply=$mailIdx&mode=$composeModeReplyAll';

  /// 전달 — 수신자는 비우고 본문·제목만 원본에서 가져온다.
  static String composeForward(int mailIdx) =>
      '$compose?reply=$mailIdx&mode=$composeModeForward';

  /// 특정 주소로 새 메일 쓰기 — 상세의 보낸사람/받는사람을 더블클릭했을 때 쓴다.
  ///
  /// `reply` 가 아니라 별도 쿼리(`to`)를 쓰는 이유: 이건 원본 메일의 스레드를
  /// 잇는 답장이 아니라 완전히 새 메일이다(제목·본문이 비어 있어야 한다).
  static String composeTo(String email) =>
      '$compose?to=${Uri.encodeQueryComponent(email)}';

  /// 작성 화면 모드 쿼리 값. 셸이 이 문자열을 그대로 넘긴다.
  static const String composeModeReply = 'reply';
  static const String composeModeReplyAll = 'replyAll';
  static const String composeModeForward = 'forward';

  /// 경로 → 메일함 폴더 코드. 상세·작성·설정처럼 폴더가 아닌 경로면 null.
  static String? folderFromPath(String path) {
    if (path == root || path == inbox) return MailFolders.inbox;
    if (path == sent) return MailFolders.sent;
    if (path == draft) return MailFolders.draft;
    if (path == scheduled) return MailFolders.scheduled;
    if (path == spam) return MailFolders.spam;
    if (path == trash) return MailFolders.trash;
    if (path == all) return MailFolders.all;
    return null;
  }

  /// 폴더 코드 → 경로. 메일함 이동(사이드바 하이라이트 포함)에 쓴다.
  static String pathForFolder(String folder) => switch (folder) {
    MailFolders.inbox => inbox,
    MailFolders.sent => sent,
    MailFolders.draft => draft,
    MailFolders.scheduled => scheduled,
    MailFolders.spam => spam,
    MailFolders.trash => trash,
    MailFolders.all => all,
    _ => inbox,
  };

  static String titleFor(String path) {
    if (mailIdxFromPath(path) != null) return '메일 상세';
    if (path == compose) return '메일쓰기';
    if (path == settings) return '메일설정';
    final folder = folderFromPath(path);
    if (folder != null) return MailFolders.labelOf(folder);
    return '메일';
  }

  static String? parentFor(String path) {
    if (mailIdxFromPath(path) != null) return inbox;
    if (path == compose) return inbox;
    if (path == inbox || path == root) return '/';
    return inbox;
  }

  /// 목록 행에서 상세로. `go` 가 아니라 `push` 를 쓰는 이유는 상세에서
  /// 뒤로가기 했을 때 보고 있던 메일함(스크롤 위치 포함)으로 돌아와야 하기 때문이다.
  static void openMail(
    BuildContext context,
    MailListItem item, {
    String? folder,
  }) {
    context.push(detail(item.mailIdx, folder: folder));
  }
}
