import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/property_mst/property_mst_write_request.dart';
import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';
import 'package:app_flutter/pages/mail/shared/mail_routes.dart';

/// 현재 경로에 대응하는 메뉴 코드. 사이드바·라우터 가드 공통.
String? menuCdForPath(String path) {
  if (path == AppRoutes.board || path.startsWith('${AppRoutes.board}/')) {
    return kMenuBbs001;
  }
  if (path == AppRoutes.dashboard) {
    return kMenuDsh001;
  }
  if (path == AppRoutes.stores || path.startsWith('${AppRoutes.stores}/')) {
    return kMenuStr001;
  }
  if (path == AppRoutes.founders || path.startsWith('${AppRoutes.founders}/')) {
    return kMenuDev001;
  }
  if (path == AppRoutes.properties ||
      path.startsWith('${PropertyMstApiPaths.root}/')) {
    return kMenuDev002;
  }
  if (path == AppRoutes.salesAreas ||
      path.startsWith('${AppRoutes.salesAreas}/')) {
    return kMenuDev003;
  }
  if (path == AppRoutes.masterUsers ||
      path.startsWith('${AppRoutes.masterUsers}/')) {
    return kMenuMst001;
  }
  if (path == AppRoutes.masterDepartments ||
      path.startsWith('${AppRoutes.masterDepartments}/')) {
    return kMenuMst002;
  }
  if (path == AppRoutes.masterMenuPermissions ||
      path.startsWith('${AppRoutes.masterMenuPermissions}/')) {
    return kMenuMst003;
  }
  if (path == AppRoutes.masterChecklists ||
      path.startsWith('${AppRoutes.masterChecklists}/')) {
    return kMenuMst004;
  }
  if (path == AppRoutes.masterUsageLogs ||
      path.startsWith('${AppRoutes.masterUsageLogs}/')) {
    return kMenuMst005;
  }
  if (path == AppRoutes.masterOwnerUsers ||
      path.startsWith('${AppRoutes.masterOwnerUsers}/')) {
    return kMenuMst006;
  }
  if (path == EapRoutes.forms || path.startsWith('${EapRoutes.forms}/')) {
    return kMenuMst007;
  }
  if (path == EapRoutes.root || path.startsWith('${EapRoutes.root}/')) {
    return kMenuEap001;
  }
  // 메일 — **메일함마다 메뉴 코드가 다르다.** `/mail` 하위를 전부 mal001 로 뭉뚱그리면
  // 보낸메일함에 들어가도 사이드바 하이라이트가 받은메일함에 남는다. 그래서 구체적인
  // 경로를 먼저 하나씩 걸러 내고, 그 뒤에야 `/mail` 접두 처리로 내려간다.
  if (path == MailRoutes.root || path.startsWith('${MailRoutes.root}/')) {
    final mailCd = _mailMenuCdForPath(path);
    if (mailCd != null) return mailCd;
    // 상세(`/mail/m/123`)·작성(`/mail/compose`)은 자기 메뉴가 없다. 받은메일함
    // 권한으로 판정한다 — 여기서 null 을 주면 라우터 가드가 "권한 없음"으로 막는다.
    return kMenuMal001;
  }
  if (path.startsWith(kActivitiesRoot)) {
    if (path == ActivityRoutes.groupStatus ||
        path.startsWith('${ActivityRoutes.groupStatus}/') ||
        path.startsWith('$kActivitiesRoot/status/')) {
      return kMenuAct001;
    }
    if (path == ActivityRoutes.groupApproval ||
        path.startsWith('${ActivityRoutes.groupApproval}/') ||
        path.startsWith('$kActivitiesRoot/approval/')) {
      return kMenuAct003;
    }
    if (path == ActivityRoutes.calendar ||
        path.startsWith('${ActivityRoutes.calendar}/')) {
      return kMenuAct004;
    }
    return kMenuAct002;
  }
  return null;
}

/// 메일 경로 → 메일함 메뉴 코드. DB 메뉴 트리(grp_mail 아래 mal001~mal008)와 1:1.
///
/// 메일함이 아닌 경로(상세·작성)면 null 을 돌려주고 호출부가 기본값을 정한다.
String? _mailMenuCdForPath(String path) {
  for (final entry in _mailMenuRoutes) {
    if (path == entry.$2) return entry.$1;
  }
  return null;
}

/// 메일함 메뉴 코드 ↔ 경로 대응표. **여기 한 곳만 고치면 된다.**
const List<(String, String)> _mailMenuRoutes = <(String, String)>[
  (kMenuMal001, MailRoutes.inbox),
  (kMenuMal002, MailRoutes.sent),
  (kMenuMal003, MailRoutes.draft),
  (kMenuMal004, MailRoutes.scheduled),
  (kMenuMal005, MailRoutes.spam),
  (kMenuMal006, MailRoutes.trash),
  (kMenuMal007, MailRoutes.all),
  (kMenuMal008, MailRoutes.settings),
];

/// 등록·신규 화면 경로 여부 (`/new`, `/register` 등).
/// `/sales-areas/register/:rowId` 는 상세·수정 — [isMenuCreatePath] false.
bool isMenuCreatePath(String path) {
  if (path.endsWith('/new')) return true;
  if (path.endsWith('/register')) return true;
  return false;
}

/// 메뉴 코드에 대응하는 목록(허브) 경로.
String? listRouteForMenuCd(String menuCd) {
  for (final entry in _menuListRoutes) {
    if (entry.$1 == menuCd) {
      return entry.$2;
    }
  }
  return null;
}

final _menuListRoutes = <(String, String)>[
  (kMenuDsh001, AppRoutes.dashboard),
  (kMenuStr001, AppRoutes.stores),
  (kMenuDev001, AppRoutes.founders),
  (kMenuDev002, AppRoutes.properties),
  (kMenuDev003, AppRoutes.salesAreas),
  (kMenuAct001, ActivityRoutes.groupStatus),
  (kMenuAct002, ActivityRoutes.groupManage),
  (kMenuAct003, ActivityRoutes.approvalAll),
  (kMenuAct004, ActivityRoutes.calendar),
  (kMenuEap001, EapRoutes.home),
  (kMenuMst001, AppRoutes.masterUsers),
  (kMenuMst002, AppRoutes.masterDepartments),
  (kMenuMst003, AppRoutes.masterMenuPermissions),
  (kMenuMst004, AppRoutes.masterChecklists),
  (kMenuMst005, AppRoutes.masterUsageLogs),
  (kMenuMst006, AppRoutes.masterOwnerUsers),
  (kMenuMst007, EapRoutes.forms),
  (kMenuBbs001, AppRoutes.board),
  // 메일함 8개 — `firstAllowedRoute` 가 받은메일함부터 훑도록 순서를 지킨다.
  ..._mailMenuRoutes,
];

/// 조회 권한이 있는 첫 화면 경로(대시보드 우선).
String? firstAllowedRoute(bool Function(String menuCd) canViewMenu) {
  for (final entry in _menuListRoutes) {
    if (canViewMenu(entry.$1)) {
      return entry.$2;
    }
  }
  return null;
}
