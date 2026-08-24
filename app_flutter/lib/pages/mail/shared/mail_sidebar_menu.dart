// 좌측 사이드바에 그릴 메일 메뉴 정의 — **사이드바 파일에서 가져다 쓰는 데이터**.
//
// ── 왜 이 파일이 따로 있는가 ──
// 사이드바(`core/layout/main_frame_layout.dart`)는 DB 메뉴 트리를 순회하지 않는다.
// 메뉴 한 줄 한 줄이 하드코딩돼 있고, `MenuPermission` 은 "이 줄을 보여 줄지"만
// 판정하는 데 쓰인다. 그래서 DB 에 grp_mail 트리를 넣고 route→menuCd 매핑을 맞춰도
// **사이드바에는 자동으로 뜨지 않는다.** 사이드바 파일을 직접 고쳐야 한다.
//
// 사이드바가 필요한 정보(메뉴 코드·이름·경로·순서·계층)를 이 목록 하나로 내보내 둔다.
// 사이드바 쪽에서는 이 목록을 **순회만** 하면 되고, 메일함이 늘거나 이름이 바뀌거나
// 계층이 달라져도 이 파일만 고치면 양쪽이 어긋나지 않는다.

import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';
import 'package:app_flutter/pages/mail/shared/mail_routes.dart';

/// 사이드바 메일 그룹 아래에 들어갈 항목 하나.
///
/// [children] 이 있으면 그 항목은 **접었다 펼 수 있는 3단계 부모**가 된다.
/// (예: 보낸메일함 ▾ └ 예약메일함) 부모 자신도 누르면 이동하는 실제 메일함이다 —
/// 순수한 폴더가 아니라서 `_SidebarExpandableMenuItem` 을 그대로 쓸 수 없다.
class MailSidebarEntry {
  const MailSidebarEntry({
    required this.menuCd,
    required this.title,
    required this.path,
    this.folder,
    this.children = const <MailSidebarEntry>[],
  });

  /// 권한 판정용 메뉴 코드 — `auth.canViewMenu(menuCd)`.
  final String menuCd;

  /// 사이드바에 보일 이름.
  final String title;

  /// 이동 경로 — `context.go(path)`.
  final String path;

  /// 안읽음 뱃지를 붙일 메일함 코드. null 이면 뱃지 없음(설정 메뉴 등).
  final String? folder;

  /// 이 항목 아래로 한 단계 더 들어가는 메일함들.
  final List<MailSidebarEntry> children;

  bool get hasChildren => children.isNotEmpty;
}

/// grp_mail 아래 메뉴 트리.
///
/// ── 전체메일(mal007)이 여기 없는 이유 ──
/// 전체메일은 조건이 `deleted_yn = false` 하나뿐이라 보낸메일·스팸까지 전부 섞여
/// 나왔다. "받은메일함과 뭐가 다르냐"는 질문이 반복됐고 실제로 다우오피스에도 없는
/// 메뉴다. 그래서 **사이드바에서만 뺀다** — 라우트(`/mail/all`)와 화면은 그대로 두어
/// 즐겨찾기·링크로 들어온 사람이 흰 화면을 보지 않게 한다. DB 메뉴 비활성은 별도.
///
/// ── 예약메일함(mal004)이 보낸메일함 아래로 들어간 이유 ──
/// 예약메일은 "아직 안 나간 보낸메일"이다. 형제로 나란히 두면 보낸메일함을 볼 때
/// 예약 건을 못 보고 지나친다. 계층으로 묶어 두면 보낸메일함을 열 때 함께 펼쳐진다.
const List<MailSidebarEntry> kMailSidebarEntries = <MailSidebarEntry>[
  MailSidebarEntry(
    menuCd: kMenuMal001,
    title: '받은메일함',
    path: MailRoutes.inbox,
    folder: MailFolders.inbox,
  ),
  MailSidebarEntry(
    menuCd: kMenuMal002,
    title: '보낸메일함',
    path: MailRoutes.sent,
    folder: MailFolders.sent,
    children: <MailSidebarEntry>[
      MailSidebarEntry(
        menuCd: kMenuMal004,
        title: '예약메일함',
        path: MailRoutes.scheduled,
        folder: MailFolders.scheduled,
      ),
    ],
  ),
  MailSidebarEntry(
    menuCd: kMenuMal003,
    title: '임시보관함',
    path: MailRoutes.draft,
    folder: MailFolders.draft,
  ),
  MailSidebarEntry(
    menuCd: kMenuMal005,
    title: '스팸메일함',
    path: MailRoutes.spam,
    folder: MailFolders.spam,
  ),
  MailSidebarEntry(
    menuCd: kMenuMal006,
    title: '휴지통',
    path: MailRoutes.trash,
    folder: MailFolders.trash,
  ),
  MailSidebarEntry(
    menuCd: kMenuMal008,
    title: '메일설정',
    path: MailRoutes.settings,
  ),
];

/// 현재 경로가 메일 영역인지 — 사이드바 그룹을 펼친 채로 둘지 판정할 때 쓴다.
bool isMailSidebarPath(String currentPath) =>
    currentPath == MailRoutes.root ||
    currentPath.startsWith('${MailRoutes.root}/');

/// 사이드바 항목이 선택 상태인지.
///
/// 단순 `==` 로 하면 상세(`/mail/m/123`)에 들어갔을 때 아무 메뉴도 선택되지 않는다.
/// 상세·작성은 어느 메일함에서 왔는지 알 수 없으므로 받은메일함을 켜 둔다
/// (`menu_route_access.dart` 의 기본값과 같은 규칙이다).
///
/// **자식은 보지 않는다.** 예약메일함에 있을 때 부모(보낸메일함)까지 같이 켜지면
/// 지금 어느 메일함을 보고 있는지 알 수 없다. 부모는 [mailSidebarEntryHasSelectedChild]
/// 로 "펼침" 여부만 판정한다.
bool isMailSidebarEntrySelected(MailSidebarEntry entry, String currentPath) {
  if (currentPath == entry.path) return true;
  if (entry.menuCd != kMenuMal001) return false;
  if (currentPath == MailRoutes.root) return true;
  // 상세·작성은 자기 메뉴가 없다 → 받은메일함으로 귀속.
  return MailRoutes.mailIdxFromPath(currentPath) != null ||
      currentPath == MailRoutes.compose;
}

/// 자식 중에 지금 보고 있는 메일함이 있는지 — 부모를 펼친 채로 시작할지 판정한다.
bool mailSidebarEntryHasSelectedChild(
  MailSidebarEntry entry,
  String currentPath,
) => entry.children.any((c) => isMailSidebarEntrySelected(c, currentPath));
