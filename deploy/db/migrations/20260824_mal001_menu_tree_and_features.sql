-- 메일(mal001) 2차 — 좌측 메뉴 트리화 + 기능 확장
--
-- 배경
--   1차에서는 메일을 루트 메뉴 하나(mal001, /mail)로 넣었더니 받은메일함·보낸메일함이
--   페이지 안쪽 탭으로만 보였다. 다른 모듈(전자결재 grp_eap, 마스터 grp_mst)은 전부
--   좌측 사이드바에서 그룹 아래로 펼쳐지는데 메일만 달라서 쓰기 불편하다는 지적이 나왔다.
--   → 메일도 그룹(grp_mail) 아래 메일함들을 자식 메뉴로 올린다.
--
--   메일함 구성은 다우오피스 기본 6개함을 그대로 따랐다(사용자가 그것에 익숙하다):
--     받은메일함 / 보낸메일함 / 임시보관함 / 예약메일함 / 스팸메일함 / 휴지통
--   '내게쓴메일함'은 다우오피스에 없어서 넣지 않았고, '중요메일'은 다우에서도 폴더가
--   아니라 빠른검색 항목이라 폴더로 만들지 않고 star_yn 플래그 + 목록 필터로 처리한다.
--
-- 안전성
--   전부 IF NOT EXISTS / ON CONFLICT 라 여러 번 돌려도 안전하다.
--   기존 mal001 은 '메일' → '받은메일함' 으로 이름과 부모만 바뀐다. 권한 행은 그대로
--   살아 있으므로 이미 부여된 조회권한을 잃지 않는다.
--
-- 실행
--   psql -h localhost -p 5433 -U postgres -d yeokjeon_on -f 20260824_mal001_menu_tree_and_features.sql

BEGIN;

-- ── 1) 메뉴 트리 ────────────────────────────────────────────────────────────
--    grp_mail(그룹) 아래에 메일함들을 붙인다. sort_order 는 게시판(15)과
--    가맹점관리(20) 사이인 17 을 그룹이 쓰고, 자식은 171~178 로 둔다.

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('grp_mail', '메일', NULL, NULL, 'G', 17, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm, parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path, menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order, use_yn = EXCLUDED.use_yn, updated_at = now();

-- mal001 은 이미 존재한다(1차에서 만든 루트 메뉴). 부모를 grp_mail 로 옮기고
-- 이름을 '받은메일함' 으로 바꾼다. menu_cd 를 그대로 두는 이유는 user_menu_auth 에
-- 이미 72명분 권한이 붙어 있어서다 — 코드를 바꾸면 그 권한이 전부 끊긴다.
INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES
    ('mal001', '받은메일함', 'grp_mail', '/mail/inbox',     'L', 171, 'Y'),
    ('mal002', '보낸메일함', 'grp_mail', '/mail/sent',      'L', 172, 'Y'),
    ('mal003', '임시보관함', 'grp_mail', '/mail/draft',     'L', 173, 'Y'),
    ('mal004', '예약메일함', 'grp_mail', '/mail/scheduled', 'L', 174, 'Y'),
    ('mal005', '스팸메일함', 'grp_mail', '/mail/spam',      'L', 175, 'Y'),
    ('mal006', '휴지통',     'grp_mail', '/mail/trash',     'L', 176, 'Y'),
    ('mal007', '전체메일',   'grp_mail', '/mail/all',       'L', 177, 'Y'),
    ('mal008', '메일설정',   'grp_mail', '/mail/settings',  'L', 178, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm, parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path, menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order, use_yn = EXCLUDED.use_yn, updated_at = now();

-- 새로 생긴 메일함 메뉴에도 전 사용자 조회권한을 준다.
-- 발송·삭제 권한은 주지 않는다(관리자가 mst003 에서 개별 부여).
INSERT INTO user_menu_auth (user_idx, menu_cd, can_view, can_create, can_update, can_delete)
SELECT u.user_idx, m.menu_cd, 'Y', 'N', 'N', 'N'
FROM user_mst u
CROSS JOIN (VALUES ('grp_mail'),('mal002'),('mal003'),('mal004'),
                   ('mal005'),('mal006'),('mal007'),('mal008')) AS m(menu_cd)
WHERE NOT EXISTS (SELECT 1 FROM user_menu_auth a
                  WHERE a.user_idx = u.user_idx AND a.menu_cd = m.menu_cd);


-- ── 2) 사용자 정의 메일함 ───────────────────────────────────────────────────
--    다우오피스는 개수·계층 무제한이지만, 실사용에서 3단계를 넘는 경우가 드물고
--    깊어질수록 좌측 사이드바가 읽기 어려워진다. 여기서는 계층 제한을 DB 로 강제하지
--    않고 화면에서 2단계까지만 만들게 한다(구조는 열어 두되 UI 로 절제).
CREATE TABLE IF NOT EXISTS public.mail_folder_mst (
    mail_folder_idx   bigserial    PRIMARY KEY,
    user_id           varchar(50)  NOT NULL,
    parent_folder_idx bigint       REFERENCES public.mail_folder_mst(mail_folder_idx) ON DELETE CASCADE,
    folder_nm         varchar(100) NOT NULL,
    sort_order        integer      NOT NULL DEFAULT 0,
    created_at        timestamptz  NOT NULL DEFAULT now(),
    updated_at        timestamptz  NOT NULL DEFAULT now()
);
COMMENT ON TABLE  public.mail_folder_mst              IS '사용자가 직접 만드는 메일함. 기본 6개함과 별개다.';
COMMENT ON COLUMN public.mail_folder_mst.user_id      IS '소유자. user_mst.user_id 문자열 연결(기존 관례대로 FK 없음).';
COMMENT ON COLUMN public.mail_folder_mst.sort_order   IS '다우오피스는 가나다순 고정이라 사용자가 "1_영업" 식으로 머릿말을 붙여야 했다. 순서를 직접 정하게 한다.';

CREATE UNIQUE INDEX IF NOT EXISTS uq_mail_folder_owner_name
    ON public.mail_folder_mst (user_id, COALESCE(parent_folder_idx, 0), folder_nm);
CREATE INDEX IF NOT EXISTS idx_mail_folder_owner
    ON public.mail_folder_mst (user_id, sort_order, mail_folder_idx);


-- ── 3) 서명 ─────────────────────────────────────────────────────────────────
--    네이버웍스처럼 여러 개를 두고 새메일/답장에 각각 기본값을 지정할 수 있게 한다.
CREATE TABLE IF NOT EXISTS public.mail_signature (
    mail_sign_idx bigserial   PRIMARY KEY,
    user_id       varchar(50) NOT NULL,
    sign_nm       varchar(100) NOT NULL,
    sign_html     text        NOT NULL DEFAULT '',
    default_new_yn   char(1)  NOT NULL DEFAULT 'N',
    default_reply_yn char(1)  NOT NULL DEFAULT 'N',
    sort_order    integer     NOT NULL DEFAULT 0,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_mail_sign_new   CHECK (default_new_yn   IN ('Y','N')),
    CONSTRAINT ck_mail_sign_reply CHECK (default_reply_yn IN ('Y','N'))
);
COMMENT ON TABLE public.mail_signature IS '개인 서명. 관리자 전사 배너와는 별개다(그건 설정값으로 따로 둔다).';

CREATE INDEX IF NOT EXISTS idx_mail_signature_owner
    ON public.mail_signature (user_id, sort_order, mail_sign_idx);


-- ── 4) mail_mst 확장 ────────────────────────────────────────────────────────
ALTER TABLE public.mail_mst
    ADD COLUMN IF NOT EXISTS star_yn          char(1)     NOT NULL DEFAULT 'N',
    ADD COLUMN IF NOT EXISTS folder_idx       bigint,
    ADD COLUMN IF NOT EXISTS scheduled_at     timestamptz,
    ADD COLUMN IF NOT EXISTS read_receipt_yn  char(1)     NOT NULL DEFAULT 'N',
    ADD COLUMN IF NOT EXISTS opened_at        timestamptz,
    ADD COLUMN IF NOT EXISTS open_cnt         smallint    NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS importance       char(1)     NOT NULL DEFAULT 'N';

COMMENT ON COLUMN public.mail_mst.star_yn         IS '중요표시. 다우오피스에서도 폴더가 아니라 플래그 + 빠른검색이다.';
COMMENT ON COLUMN public.mail_mst.folder_idx      IS '사용자 정의 메일함. NULL 이면 기본 6개함 규칙으로 분류된다.';
COMMENT ON COLUMN public.mail_mst.scheduled_at    IS '예약발송 시각. Resend scheduled_at 에 그대로 넘긴다. 값이 있고 send_status=SCHEDULED 면 예약메일함에 보인다.';
COMMENT ON COLUMN public.mail_mst.read_receipt_yn IS '수신확인 요청 여부. 추적픽셀을 본문에 심을지 결정한다.';
COMMENT ON COLUMN public.mail_mst.opened_at       IS '수신확인이 처음 걸린 시각. 외부 수신자는 이미지 차단으로 안 잡힐 수 있어 신뢰도는 사내 발송에 한한다.';
COMMENT ON COLUMN public.mail_mst.importance      IS '중요도 H(높음)/N(보통)/L(낮음). 발송 시 X-Priority 헤더로 나간다.';

-- folder_idx 는 FK 를 건다. 메일함을 지우면 그 안의 메일은 기본함으로 돌아가야 하므로
-- CASCADE 가 아니라 SET NULL 이다.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_mail_mst_folder') THEN
        ALTER TABLE public.mail_mst
            ADD CONSTRAINT fk_mail_mst_folder
            FOREIGN KEY (folder_idx) REFERENCES public.mail_folder_mst(mail_folder_idx)
            ON DELETE SET NULL;
    END IF;
END $$;

-- 중요표시·예약함·사용자메일함 조회용. 전부 부분 인덱스 — 해당하는 행이 소수라
-- 전체 인덱스를 만들면 낭비다.
CREATE INDEX IF NOT EXISTS idx_mail_mst_star
    ON public.mail_mst (user_id, mail_at DESC) WHERE star_yn = 'Y' AND deleted_yn = false;
CREATE INDEX IF NOT EXISTS idx_mail_mst_scheduled
    ON public.mail_mst (scheduled_at) WHERE scheduled_at IS NOT NULL AND send_status = 'SCHEDULED';
CREATE INDEX IF NOT EXISTS idx_mail_mst_folder
    ON public.mail_mst (folder_idx, mail_at DESC) WHERE folder_idx IS NOT NULL AND deleted_yn = false;
-- 휴지통 — deleted_yn = true 인 행만
CREATE INDEX IF NOT EXISTS idx_mail_mst_trash
    ON public.mail_mst (user_id, updated_at DESC) WHERE deleted_yn = true;


-- ── 5) 개인 환경설정 ────────────────────────────────────────────────────────
--    다우오피스는 읽기/쓰기 설정을 20개 넘게 쪼개 두었는데, 실제로 손대는 항목은
--    소수다. 키-값으로 두면 화면을 늘릴 때 스키마를 다시 안 바꿔도 된다.
CREATE TABLE IF NOT EXISTS public.mail_pref (
    user_id    varchar(50)  NOT NULL,
    pref_key   varchar(50)  NOT NULL,
    pref_val   varchar(500) NOT NULL DEFAULT '',
    updated_at timestamptz  NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, pref_key)
);
COMMENT ON TABLE public.mail_pref IS '개인 메일 환경설정. 항목이 자주 늘어서 컬럼 대신 키-값으로 둔다.';

COMMIT;

-- 되돌리려면:
--   DELETE FROM user_menu_auth WHERE menu_cd IN ('grp_mail','mal002','mal003','mal004','mal005','mal006','mal007','mal008');
--   DELETE FROM menu_mst WHERE menu_cd IN ('grp_mail','mal002','mal003','mal004','mal005','mal006','mal007','mal008');
--   UPDATE menu_mst SET menu_nm='메일', parent_menu_cd=NULL, route_path='/mail', sort_order=17 WHERE menu_cd='mal001';
--   ALTER TABLE public.mail_mst DROP COLUMN IF EXISTS star_yn, DROP COLUMN IF EXISTS folder_idx,
--       DROP COLUMN IF EXISTS scheduled_at, DROP COLUMN IF EXISTS read_receipt_yn,
--       DROP COLUMN IF EXISTS opened_at, DROP COLUMN IF EXISTS open_cnt, DROP COLUMN IF EXISTS importance;
--   DROP TABLE IF EXISTS public.mail_pref;
--   DROP TABLE IF EXISTS public.mail_signature;
--   DROP TABLE IF EXISTS public.mail_folder_mst;
