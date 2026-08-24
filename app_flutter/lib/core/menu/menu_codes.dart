// ERP 메뉴 코드 — `lib/pages/<코드>/` 폴더·파일 접두사와 맞춘다.

/// 대시보드(홈)
const String kMenuDsh001 = 'dsh001';

/// 가맹점 관리
const String kMenuStr001 = 'str001';

/// 개발 관리 — 예비창업자
const String kMenuDev001 = 'dev001';

/// 개발 관리 — 물건
const String kMenuDev002 = 'dev002';

/// 개발 관리 — 영업지역
const String kMenuDev003 = 'dev003';

/// 활동관리 — 활동현황
const String kMenuAct001 = 'act001';

/// 활동관리 — 활동관리
const String kMenuAct002 = 'act002';

/// 활동관리 — 활동관리결재
const String kMenuAct003 = 'act003';

/// 활동관리 — 활동 계획 캘린더
const String kMenuAct004 = 'act004';

/// 전자결재
const String kMenuEap001 = 'eap001';

/// 사이드바 그룹(폴더) — DB menu_mst.menu_type = G
const String kMenuGrpEap = 'grp_eap';
const String kMenuGrpDev = 'grp_dev';
const String kMenuGrpAct = 'grp_act';
const String kMenuGrpMst = 'grp_mst';

/// 메일 그룹 — 메일함들이 이 아래로 펼쳐진다.
///
/// 예전에는 mal001 하나가 루트 메뉴였고 받은/보낸/임시보관은 **화면 안쪽 탭**이었다.
/// 메일함을 옮길 때마다 메일 화면에 들어가서 탭을 다시 골라야 해 불편하다는 지적이
/// 있어, 전자결재(grp_eap)·마스터(grp_mst)처럼 좌측 그룹 아래 메일함을 하나씩
/// 노출하는 구조로 바꿨다.
const String kMenuGrpMail = 'grp_mail';

/// 마스터 — 사원
const String kMenuMst001 = 'mst001';

/// 마스터 — 부서
const String kMenuMst002 = 'mst002';

/// 마스터 — 메뉴권한
const String kMenuMst003 = 'mst003';

/// 마스터 — 체크리스트
const String kMenuMst004 = 'mst004';

/// 게시판
const String kMenuBbs001 = 'bbs001';

/// 메신저
const String kMenuMsg001 = 'msg001';

/// 마스터 — 사용기록 조회
const String kMenuMst005 = 'mst005';

/// 마스터 — 가맹주관리
const String kMenuMst006 = 'mst006';

/// 마스터 — 서식관리
const String kMenuMst007 = 'mst007';

// 메일 — grp_mail 하위 메일함들.
//
// **코드 하나 = 메일함 하나**다. 예전처럼 `/mail` 전체를 mal001 로 뭉뚱그리면
// 보낸메일함에 들어가도 사이드바 하이라이트가 받은메일함에 남는다.
// (menu_route_access.dart 의 경로 매핑을 반드시 함께 맞출 것.)

/// 메일 — 받은메일함
const String kMenuMal001 = 'mal001';

/// 메일 — 보낸메일함
const String kMenuMal002 = 'mal002';

/// 메일 — 임시보관함
const String kMenuMal003 = 'mal003';

/// 메일 — 예약메일함
const String kMenuMal004 = 'mal004';

/// 메일 — 스팸메일함
const String kMenuMal005 = 'mal005';

/// 메일 — 휴지통
const String kMenuMal006 = 'mal006';

/// 메일 — 전체메일
const String kMenuMal007 = 'mal007';

/// 메일 — 메일설정
const String kMenuMal008 = 'mal008';
