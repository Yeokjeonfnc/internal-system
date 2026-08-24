package com.yeokjeon.erp.auth.access;

/** 권한 검사에 쓰는 메뉴 코드 — 프론트 {@code core/menu/menu_codes.dart} 와 동일한 값. */
public final class MenuCodes {

    private MenuCodes() {}

    /** 대시보드(홈) */
    public static final String DSH001 = "dsh001";

    /** 가맹점 관리 */
    public static final String STR001 = "str001";

    /** 개발 관리 — 예비창업자 */
    public static final String DEV001 = "dev001";

    /** 개발 관리 — 물건 */
    public static final String DEV002 = "dev002";

    /** 개발 관리 — 영업지역 */
    public static final String DEV003 = "dev003";

    /** 활동 관리 — 활동 현황 */
    public static final String ACT001 = "act001";

    /** 활동 관리 — 활동 등록 */
    public static final String ACT002 = "act002";

    /** 활동 관리 — 활동관리결재 */
    public static final String ACT003 = "act003";

    /** 활동 관리 — 활동 계획 캘린더 */
    public static final String ACT004 = "act004";

    /** 전자결재 */
    public static final String EAP001 = "eap001";

    /** 게시판 */
    public static final String BBS001 = "bbs001";

    /** 메신저 */
    public static final String MSG001 = "msg001";

    /** 사원관리 */
    public static final String MST001 = "mst001";

    /** 부서관리 */
    public static final String MST002 = "mst002";

    /** 메뉴권한 관리 */
    public static final String MST003 = "mst003";

    /** 체크리스트 관리 */
    public static final String MST004 = "mst004";

    /** 사용기록 조회 */
    public static final String MST005 = "mst005";

    /** 가맹점주 관리 */
    public static final String MST006 = "mst006";

    /** 서식관리 */
    public static final String MST007 = "mst007";

    /**
     * 메일 그룹(좌측 사이드바 상위 노드).
     *
     * <p>메뉴 타입이 {@code 'G'} 라 라우트가 없다. 권한 판정에는 쓰지 않고
     * 트리 렌더링·권한 부여 대상 식별용으로만 존재한다.
     */
    public static final String GRP_MAIL = "grp_mail";

    /**
     * 메일 — 받은메일함.
     *
     * <p>1차에서 만든 루트 메뉴 {@code mal001}(/mail) 을 그대로 물려받은 코드다.
     * 이름·부모만 바뀌고 코드를 유지한 이유는 {@code user_menu_auth} 에 이미 붙어 있는
     * 권한 행을 끊지 않기 위해서다. <b>메일 API 의 권한 판정은 전부 이 코드 하나로 한다</b> —
     * 메일함은 같은 데이터에 대한 필터일 뿐이라 함마다 권한을 나누면 "보낸메일함은 보이는데
     * 그 메일의 상세는 403" 같은 상태가 생긴다.
     */
    public static final String MAL001 = "mal001";

    /** 메일 — 보낸메일함 (/mail/sent). 화면 표시용이며 권한 판정은 {@link #MAL001} 로 한다. */
    public static final String MAL002 = "mal002";

    /** 메일 — 임시보관함 (/mail/draft) */
    public static final String MAL003 = "mal003";

    /** 메일 — 예약메일함 (/mail/scheduled) */
    public static final String MAL004 = "mal004";

    /** 메일 — 스팸메일함 (/mail/spam) */
    public static final String MAL005 = "mal005";

    /** 메일 — 휴지통 (/mail/trash) */
    public static final String MAL006 = "mal006";

    /** 메일 — 전체메일 (/mail/all) */
    public static final String MAL007 = "mal007";

    /** 메일 — 메일설정 (/mail/settings). 사용자 메일함·서명·개인설정 화면. */
    public static final String MAL008 = "mal008";
}
