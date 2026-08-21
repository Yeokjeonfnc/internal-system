-- =====================================================================
-- yj_db_test 통합 변경 DDL (001_schema.sql 기준 base 이후 적용된 변경분)
-- 생성: db/004~007_*.sql (db/ 루트) + db/migrations/*.sql + db/20260807_*.sql
--       을 실제 적용 순서(파일 수정일 기준)대로 그대로 이어붙인 것입니다.
-- 제외: 002_seed_test.sql, 003_store_mst_real_stores.sql,
--       007_property_mst_coords_from_store_map.sql(좌표 데이터 UPDATE, 1000행+),
--       900_admin_account_setup.sql(admin 비밀번호 해시 UPDATE)
--       => 구조(DDL)가 아니라 데이터(DML)라서 뺐습니다. 필요하면 별도로 드릴게요.
--
-- DataGrip: 이전 실패 세션이면 아래 ROLLBACK 이 풀어 줍니다.
-- 실행은 한 문장(Ctrl+Enter)이 아니라 파일 전체(Ctrl+A 후 Execute).
-- =====================================================================
ROLLBACK;


-- ---------------------------------------------------------------------
-- [2026-05-29] db/migrations/20260529_align_dept_mst_with_db_structure.sql
-- dept_mst: 엑셀 설계 기준 컬럼 보정
-- ---------------------------------------------------------------------
ALTER TABLE public.dept_mst ADD COLUMN IF NOT EXISTS dept_type character varying(50);
ALTER TABLE public.dept_mst ADD COLUMN IF NOT EXISTS use_yn character(1) DEFAULT 'Y'::bpchar;
ALTER TABLE public.dept_mst ADD COLUMN IF NOT EXISTS create_dt timestamp with time zone DEFAULT CURRENT_TIMESTAMP;

UPDATE public.dept_mst
SET use_yn = 'Y'
WHERE use_yn IS NULL;

COMMENT ON COLUMN public.dept_mst.dept_type IS '부서타입';
COMMENT ON COLUMN public.dept_mst.use_yn IS '사용여부';
COMMENT ON COLUMN public.dept_mst.create_dt IS '생성일시';


-- ---------------------------------------------------------------------
-- [2026-06-01] db/migrations/20260601_code_mst_grp_cd_integer.sql
-- code_mst.grp_cd: varchar -> integer 타입 변경
-- ---------------------------------------------------------------------
ALTER TABLE code_mst ALTER COLUMN grp_cd TYPE integer USING grp_cd::integer;


-- ---------------------------------------------------------------------
-- [2026-06-02] db/004_sale_zone_geometry.sql
-- sale_zone_mst: 영업지역 도형(폴리곤/원) 컬럼 추가
-- ---------------------------------------------------------------------
ALTER TABLE sale_zone_mst ADD COLUMN IF NOT EXISTS geometry_type varchar(20), ADD COLUMN IF NOT EXISTS geometry_data jsonb;

CREATE INDEX IF NOT EXISTS idx_sale_zone_mst_geometry_data
    ON sale_zone_mst USING gin (geometry_data);

COMMENT ON COLUMN sale_zone_mst.geometry_type IS 'POLYGON | CIRCLE';
COMMENT ON COLUMN sale_zone_mst.geometry_data IS '영역 좌표 JSON (paths / center+radius)';


-- ---------------------------------------------------------------------
-- [2026-06-02] db/005_property_mst_zone_idx.sql
-- property_mst: 영업지역 FK 컬럼 추가
-- ---------------------------------------------------------------------
ALTER TABLE property_mst ADD COLUMN IF NOT EXISTS zone_idx integer;

COMMENT ON COLUMN property_mst.zone_idx IS '영업지역(sale_zone_mst.zone_idx)';

CREATE INDEX IF NOT EXISTS idx_property_mst_zone_idx
    ON property_mst (zone_idx)
    WHERE zone_idx IS NOT NULL;


-- ---------------------------------------------------------------------
-- [2026-06-04] db/006_sale_zone_use_yn_store_zone.sql
-- sale_zone_mst: 사용여부(물건 연결 여부) 컬럼 추가 + 데이터 보정
-- ---------------------------------------------------------------------
ALTER TABLE sale_zone_mst ADD COLUMN IF NOT EXISTS use_yn boolean DEFAULT false;

COMMENT ON COLUMN sale_zone_mst.use_yn IS 'true=물건(property_mst.zone_idx) 연결, false=전략출점';

UPDATE sale_zone_mst szm
   SET use_yn = true
 WHERE EXISTS (
     SELECT 1 FROM property_mst pm WHERE pm.zone_idx = szm.zone_idx
 );

UPDATE sale_zone_mst szm
   SET use_yn = false
 WHERE NOT EXISTS (
     SELECT 1 FROM property_mst pm WHERE pm.zone_idx = szm.zone_idx
 );


-- ---------------------------------------------------------------------
-- [2026-06-05] db/migrations/20260605_active_signature_attachment.sql
-- active_mst: 전자서명 컬럼 추가 + active_att(활동 첨부파일) 테이블 신설
-- ---------------------------------------------------------------------
ALTER TABLE public.active_mst ADD COLUMN IF NOT EXISTS signature_stored_name character varying(255);

COMMENT ON COLUMN public.active_mst.signature_stored_name IS '전자서명 PNG 디스크 저장 파일명(UUID 기반)';

CREATE SEQUENCE IF NOT EXISTS public.active_att_act_att_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE IF NOT EXISTS public.active_att (
    act_att_idx integer NOT NULL DEFAULT nextval('public.active_att_act_att_idx_seq'::regclass),
    act_idx integer NOT NULL,
    file_name character varying(255) NOT NULL,
    stored_name character varying(255) NOT NULL,
    file_size bigint NOT NULL DEFAULT 0,
    content_type character varying(127),
    attached_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by character varying(50),
    deleted_yn boolean NOT NULL DEFAULT false,
    CONSTRAINT active_att_pkey PRIMARY KEY (act_att_idx)
);

ALTER SEQUENCE public.active_att_act_att_idx_seq
    OWNED BY public.active_att.act_att_idx;

CREATE INDEX IF NOT EXISTS idx_active_att_act_idx
    ON public.active_att (act_idx)
    WHERE deleted_yn = false;

COMMENT ON TABLE public.active_att IS '활동관리 첨부파일 메타';
COMMENT ON COLUMN public.active_att.stored_name IS '디스크 저장 파일명(UUID 기반)';


-- ---------------------------------------------------------------------
-- [2026-06-05] db/migrations/20260605_store_document.sql
-- store_doc(가맹점 첨부문서) 테이블 신설
-- ---------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS public.store_doc_store_doc_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE IF NOT EXISTS public.store_doc (
    store_doc_idx integer NOT NULL DEFAULT nextval('public.store_doc_store_doc_idx_seq'::regclass),
    store_idx integer NOT NULL,
    file_name character varying(255) NOT NULL,
    stored_name character varying(255) NOT NULL,
    file_size bigint NOT NULL DEFAULT 0,
    content_type character varying(127),
    attachment_base_date date,
    attached_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by character varying(50),
    deleted_yn boolean NOT NULL DEFAULT false,
    CONSTRAINT store_doc_pkey PRIMARY KEY (store_doc_idx)
);

ALTER SEQUENCE public.store_doc_store_doc_idx_seq
    OWNED BY public.store_doc.store_doc_idx;

CREATE INDEX IF NOT EXISTS idx_store_doc_store_idx
    ON public.store_doc (store_idx)
    WHERE deleted_yn = false;

COMMENT ON TABLE public.store_doc IS '가맹점 첨부 문서 메타';
COMMENT ON COLUMN public.store_doc.stored_name IS '디스크 저장 파일명(UUID 기반)';
COMMENT ON COLUMN public.store_doc.attachment_base_date IS '첨부 기준일';


-- ---------------------------------------------------------------------
-- [2026-06-05] db/migrations/20260605_store_mst_closed_yn.sql
-- store_mst: 폐점 여부 컬럼 추가 + 데이터 보정
-- ---------------------------------------------------------------------
ALTER TABLE public.store_mst ADD COLUMN IF NOT EXISTS closed_yn CHAR(1) NOT NULL DEFAULT 'N';

COMMENT ON COLUMN public.store_mst.closed_yn IS '폐점 여부 (Y/N). 계약상태 closed 선택 시 Y';

UPDATE public.store_mst
SET closed_yn = 'Y'
WHERE LOWER(TRIM(COALESCE(store_status, ''))) = 'closed';

UPDATE public.code_mst
SET code_nm = '폐점'
WHERE grp_cd = 10
  AND LOWER(TRIM(code_cd)) = 'closed';


-- ---------------------------------------------------------------------
-- [2026-06-05] db/migrations/20260605_store_mst_transfer_date.sql
-- store_mst: 양수도 계약일자 컬럼 추가 (최초 버전, 이후 07/14에 재정의됨)
-- ---------------------------------------------------------------------
ALTER TABLE public.store_mst ADD COLUMN IF NOT EXISTS transfer_date date;

COMMENT ON COLUMN public.store_mst.transfer_date IS '양수도 계약일자';


-- ---------------------------------------------------------------------
-- [2026-06-05] db/migrations/20260605_usage_log.sql
-- usage_log(로그인/메뉴 사용기록) 테이블 신설 + 메뉴 등록
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.usage_log (
    log_idx     SERIAL PRIMARY KEY,
    user_id     VARCHAR(50)  NOT NULL,
    user_nm     VARCHAR(100) NOT NULL,
    dept_nm     VARCHAR(100),
    position_nm VARCHAR(100),
    tag_yn      CHAR(1)      DEFAULT 'N',
    use_type    VARCHAR(20)  NOT NULL,
    use_detail  TEXT         NOT NULL,
    menu_cd     VARCHAR(20),
    used_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.usage_log IS 'ERP 사용기록(로그인·메뉴 사용)';
COMMENT ON COLUMN public.usage_log.use_type IS 'LOGIN | MENU';
COMMENT ON COLUMN public.usage_log.tag_yn IS '기록 시점 사용자 tag_yn 스냅샷(공용사용자 탭 필터)';

CREATE INDEX IF NOT EXISTS ix_usage_log_used_at ON public.usage_log (used_at DESC);
CREATE INDEX IF NOT EXISTS ix_usage_log_user_id ON public.usage_log (user_id);
CREATE INDEX IF NOT EXISTS ix_usage_log_use_type ON public.usage_log (use_type);

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('mst005', '사용기록 조회', 'grp_mst', '/master/usage-logs', 'L', 55, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();


-- ---------------------------------------------------------------------
-- [2026-06-08] db/migrations/20260608_property_document.sql
-- property_doc(물건 첨부파일) 테이블 신설
-- ---------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS public.property_doc_property_doc_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE IF NOT EXISTS public.property_doc (
    property_doc_idx integer NOT NULL DEFAULT nextval('public.property_doc_property_doc_idx_seq'::regclass),
    prop_idx integer NOT NULL,
    file_name character varying(255) NOT NULL,
    stored_name character varying(255) NOT NULL,
    file_size bigint NOT NULL DEFAULT 0,
    content_type character varying(127),
    attachment_base_date date,
    attached_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by character varying(50),
    deleted_yn boolean NOT NULL DEFAULT false,
    CONSTRAINT property_doc_pkey PRIMARY KEY (property_doc_idx)
);

ALTER SEQUENCE public.property_doc_property_doc_idx_seq
    OWNED BY public.property_doc.property_doc_idx;

CREATE INDEX IF NOT EXISTS idx_property_doc_prop_idx
    ON public.property_doc (prop_idx)
    WHERE deleted_yn = false;

COMMENT ON TABLE public.property_doc IS '물건 첨부 문서(사진) 메타';
COMMENT ON COLUMN public.property_doc.stored_name IS '디스크 저장 파일명(UUID 기반)';


-- ---------------------------------------------------------------------
-- [2026-06-09] db/migrations/20260609_activity_plan.sql
-- activity_plan(시간 단위 캘린더 일정) + team_view_permission 테이블 신설
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.activity_plan (
    plan_idx            SERIAL PRIMARY KEY,
    assignee_user_idx   INTEGER      NOT NULL REFERENCES user_mst(user_idx),
    title               VARCHAR(200) NOT NULL,
    plan_start_at       TIMESTAMPTZ  NOT NULL,
    plan_end_at         TIMESTAMPTZ  NOT NULL,
    all_day_yn          CHAR(1)      NOT NULL DEFAULT 'N',
    location_txt        VARCHAR(300),
    online_meeting_yn   CHAR(1)      NOT NULL DEFAULT 'N',
    plan_status         VARCHAR(20)  NOT NULL DEFAULT 'PLANNED',
    memo_txt            TEXT,
    created_by          VARCHAR(50),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ck_activity_plan_all_day_yn CHECK (all_day_yn IN ('Y', 'N')),
    CONSTRAINT ck_activity_plan_online_meeting_yn CHECK (online_meeting_yn IN ('Y', 'N')),
    CONSTRAINT ck_activity_plan_status CHECK (plan_status IN ('PLANNED', 'DONE', 'CANCELLED'))
);

COMMENT ON TABLE public.activity_plan IS '활동 계획(캘린더 일정)';
COMMENT ON COLUMN public.activity_plan.assignee_user_idx IS '담당자 user_mst.user_idx — 캘린더 소유자';

CREATE INDEX IF NOT EXISTS ix_activity_plan_assignee_start
    ON public.activity_plan (assignee_user_idx, plan_start_at);
CREATE INDEX IF NOT EXISTS ix_activity_plan_range
    ON public.activity_plan (plan_start_at, plan_end_at);

CREATE TABLE IF NOT EXISTS public.team_view_permission (
    viewer_user_idx INTEGER NOT NULL REFERENCES user_mst(user_idx),
    target_dept_idx INTEGER NOT NULL REFERENCES dept_mst(dept_idx),
    can_view        CHAR(1)   NOT NULL DEFAULT 'Y',
    granted_by      VARCHAR(50),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (viewer_user_idx, target_dept_idx),
    CONSTRAINT ck_team_view_permission_can_view CHECK (can_view IN ('Y', 'N'))
);

COMMENT ON TABLE public.team_view_permission IS '팀 캘린더 열람 권한 — viewer 가 target 부서(팀) 소속 사원 계획 조회';

CREATE INDEX IF NOT EXISTS ix_team_view_permission_viewer
    ON public.team_view_permission (viewer_user_idx);

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('act004', '활동 계획', 'grp_act', '/activities/calendar', 'L', 35, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();


-- ---------------------------------------------------------------------
-- [2026-06-10] db/migrations/20260610_activity_plan_store.sql
-- activity_plan_store(월간 방문 예정 가맹점) 테이블 신설
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.activity_plan_store (
    plan_store_idx    SERIAL PRIMARY KEY,
    assignee_user_idx INTEGER      NOT NULL REFERENCES user_mst(user_idx),
    plan_date         DATE         NOT NULL,
    store_idx         INTEGER      NOT NULL REFERENCES store_mst(store_idx),
    sort_order        INTEGER      NOT NULL DEFAULT 0,
    created_by        VARCHAR(50),
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uq_activity_plan_store_day UNIQUE (assignee_user_idx, plan_date, store_idx)
);

COMMENT ON TABLE public.activity_plan_store IS '활동 계획 — 담당자·날짜별 방문 예정 가맹점';
COMMENT ON COLUMN public.activity_plan_store.plan_date IS '계획 일자(벽시계, 시간 없음)';

CREATE INDEX IF NOT EXISTS ix_activity_plan_store_assignee_date
    ON public.activity_plan_store (assignee_user_idx, plan_date);

CREATE INDEX IF NOT EXISTS ix_activity_plan_store_date
    ON public.activity_plan_store (plan_date);


-- ---------------------------------------------------------------------
-- [2026-06-16] db/migrations/20260616_user_mst_store_idx_mst006.sql
-- user_mst: 가맹점 연결(store_idx) + 점주 플래그(owner_yn) 컬럼 추가
-- ---------------------------------------------------------------------
ALTER TABLE user_mst ADD COLUMN IF NOT EXISTS store_idx INTEGER;

COMMENT ON COLUMN user_mst.store_idx IS '소속 가맹점 (가맹점주 계정)';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_mst_store_idx'
    ) THEN
        ALTER TABLE user_mst ADD CONSTRAINT fk_user_mst_store_idx FOREIGN KEY (store_idx) REFERENCES store_mst (store_idx);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_user_mst_store_idx ON user_mst (store_idx);

ALTER TABLE user_mst ADD COLUMN IF NOT EXISTS owner_yn CHAR(1) DEFAULT 'N'::bpchar;

COMMENT ON COLUMN user_mst.owner_yn IS '가맹점주 여부 (Y: 가맹점주·게시판만 접근, N: 일반)';

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('mst006', '가맹주관리', 'grp_mst', '/master/owner-users', 'L', 56, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();


-- ---------------------------------------------------------------------
-- [2026-06-17] db/migrations/20260617_bbs001_board.sql
-- 게시판: bbs_folder / bbs_post / bbs_doc 테이블 신설 + 기본 폴더/메뉴
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bbs_folder (
    folder_idx     SERIAL PRIMARY KEY,
    folder_nm      VARCHAR(100) NOT NULL,
    sort_order     INTEGER      NOT NULL DEFAULT 0,
    use_yn         CHAR(1)      NOT NULL DEFAULT 'Y',
    owner_view_yn  CHAR(1)      NOT NULL DEFAULT 'Y',
    staff_view_yn  CHAR(1)      NOT NULL DEFAULT 'Y',
    created_by     VARCHAR(50),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ck_bbs_folder_use_yn CHECK (use_yn IN ('Y', 'N')),
    CONSTRAINT ck_bbs_folder_owner_view_yn CHECK (owner_view_yn IN ('Y', 'N')),
    CONSTRAINT ck_bbs_folder_staff_view_yn CHECK (staff_view_yn IN ('Y', 'N'))
);

COMMENT ON TABLE public.bbs_folder IS '게시판 폴더';
COMMENT ON COLUMN public.bbs_folder.folder_nm IS '폴더명';

CREATE TABLE IF NOT EXISTS public.bbs_post (
    post_idx     SERIAL PRIMARY KEY,
    folder_idx   INTEGER      NOT NULL REFERENCES public.bbs_folder (folder_idx),
    store_idx    INTEGER REFERENCES public.store_mst (store_idx),
    title        VARCHAR(200) NOT NULL,
    body_txt     TEXT,
    private_yn   CHAR(1)      NOT NULL DEFAULT 'N',
    notice_yn    CHAR(1)      NOT NULL DEFAULT 'N',
    view_cnt     INTEGER      NOT NULL DEFAULT 0,
    created_by   VARCHAR(50),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    deleted_yn   BOOLEAN      NOT NULL DEFAULT false,
    CONSTRAINT ck_bbs_post_private_yn CHECK (private_yn IN ('Y', 'N')),
    CONSTRAINT ck_bbs_post_notice_yn CHECK (notice_yn IN ('Y', 'N'))
);

CREATE INDEX IF NOT EXISTS idx_bbs_post_folder_created
    ON public.bbs_post (folder_idx, created_at DESC)
    WHERE deleted_yn = false;

COMMENT ON TABLE public.bbs_post IS '게시판 글';

CREATE SEQUENCE IF NOT EXISTS public.bbs_doc_bbs_doc_idx_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

CREATE TABLE IF NOT EXISTS public.bbs_doc (
    bbs_doc_idx  INTEGER      NOT NULL DEFAULT nextval('public.bbs_doc_bbs_doc_idx_seq'::regclass),
    post_idx     INTEGER      NOT NULL REFERENCES public.bbs_post (post_idx),
    file_name    VARCHAR(255) NOT NULL,
    stored_name  VARCHAR(255) NOT NULL,
    file_size    BIGINT       NOT NULL DEFAULT 0,
    content_type VARCHAR(127),
    attached_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    modified_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    modified_by  VARCHAR(50),
    deleted_yn   BOOLEAN      NOT NULL DEFAULT false,
    CONSTRAINT bbs_doc_pkey PRIMARY KEY (bbs_doc_idx)
);

ALTER SEQUENCE public.bbs_doc_bbs_doc_idx_seq OWNED BY public.bbs_doc.bbs_doc_idx;

CREATE INDEX IF NOT EXISTS idx_bbs_doc_post_idx
    ON public.bbs_doc (post_idx)
    WHERE deleted_yn = false;

COMMENT ON TABLE public.bbs_doc IS '게시판 첨부파일 메타';

INSERT INTO public.bbs_folder (folder_nm, sort_order, use_yn, owner_view_yn, staff_view_yn, created_by)
SELECT v.folder_nm, v.sort_order, v.use_yn, v.owner_view_yn, v.staff_view_yn, v.created_by
FROM (VALUES ('공지사항', 10, 'Y', 'Y', 'Y', 'system'),
             ('일반', 20, 'Y', 'N', 'Y', 'system'),
             ('가맹점주', 30, 'Y', 'Y', 'N', 'system')) AS v(folder_nm, sort_order, use_yn, owner_view_yn, staff_view_yn, created_by)
WHERE NOT EXISTS (SELECT 1 FROM public.bbs_folder f WHERE f.folder_nm = v.folder_nm);

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('bbs001', '게시판', NULL, '/board', 'L', 15, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();


-- ---------------------------------------------------------------------
-- [2026-06-17] db/migrations/20260617_bbs_folder_visibility.sql
-- bbs_folder: 조회 권한 컬럼 재확정 + 기본 폴더 데이터 보정
-- ---------------------------------------------------------------------
ALTER TABLE public.bbs_folder ADD COLUMN IF NOT EXISTS owner_view_yn CHAR(1) NOT NULL DEFAULT 'Y', ADD COLUMN IF NOT EXISTS staff_view_yn CHAR(1) NOT NULL DEFAULT 'Y';
ALTER TABLE public.bbs_folder DROP CONSTRAINT IF EXISTS ck_bbs_folder_owner_view_yn;
ALTER TABLE public.bbs_folder ADD CONSTRAINT ck_bbs_folder_owner_view_yn CHECK (owner_view_yn IN ('Y', 'N'));
ALTER TABLE public.bbs_folder DROP CONSTRAINT IF EXISTS ck_bbs_folder_staff_view_yn;
ALTER TABLE public.bbs_folder ADD CONSTRAINT ck_bbs_folder_staff_view_yn CHECK (staff_view_yn IN ('Y', 'N'));

COMMENT ON COLUMN public.bbs_folder.owner_view_yn IS '가맹점주 조회 가능 여부';
COMMENT ON COLUMN public.bbs_folder.staff_view_yn IS '사원(내부) 조회 가능 여부';

UPDATE public.bbs_folder SET owner_view_yn = 'Y', staff_view_yn = 'Y' WHERE folder_nm = '공지사항';
UPDATE public.bbs_folder SET owner_view_yn = 'N', staff_view_yn = 'Y' WHERE folder_nm = '일반';
UPDATE public.bbs_folder SET owner_view_yn = 'Y', staff_view_yn = 'N' WHERE folder_nm = '가맹점주';


-- ---------------------------------------------------------------------
-- [2026-06-17] db/migrations/20260617_store_nfc_tag.sql
-- store_nfc_tag(가맹점 NFC 출입 태그) 테이블 신설 + usage_log/active_mst 연동 컬럼
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.store_nfc_tag (
    store_idx       INT          PRIMARY KEY REFERENCES public.store_mst (store_idx),
    tag_uid         VARCHAR(32)  NOT NULL UNIQUE,
    use_yn          CHAR(1)      NOT NULL DEFAULT 'Y',
    registered_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    registered_by   VARCHAR(50)
);

COMMENT ON TABLE public.store_nfc_tag IS '가맹점 출입 NFC 태그 UID (1매장 1태그)';
COMMENT ON COLUMN public.store_nfc_tag.tag_uid IS 'NFC 태그 시리얼(콜론 제거, 대문자 HEX)';

CREATE INDEX IF NOT EXISTS ix_store_nfc_tag_uid ON public.store_nfc_tag (tag_uid);

ALTER TABLE public.usage_log ADD COLUMN IF NOT EXISTS store_idx INT, ADD COLUMN IF NOT EXISTS tag_uid VARCHAR(32), ADD COLUMN IF NOT EXISTS tag_lat NUMERIC(10, 7), ADD COLUMN IF NOT EXISTS tag_lng NUMERIC(10, 7), ADD COLUMN IF NOT EXISTS distance_m INT;

COMMENT ON COLUMN public.usage_log.store_idx IS '출입태그(TAG) 시 가맹점 FK';
COMMENT ON COLUMN public.usage_log.tag_uid IS '출입태그(TAG) 시 NFC UID';
COMMENT ON COLUMN public.usage_log.distance_m IS '출입태그 시 매장 좌표 대비 거리(m)';

CREATE INDEX IF NOT EXISTS ix_usage_log_tag_store
    ON public.usage_log (store_idx, used_at DESC)
    WHERE use_type = 'TAG';

ALTER TABLE public.active_mst ADD COLUMN IF NOT EXISTS usage_log_idx INT;

COMMENT ON COLUMN public.active_mst.usage_log_idx IS '활동 상신 시 연결한 출입 태그 usage_log.log_idx';

CREATE INDEX IF NOT EXISTS ix_active_mst_usage_log_idx
    ON public.active_mst (usage_log_idx)
    WHERE usage_log_idx IS NOT NULL;


-- ---------------------------------------------------------------------
-- [2026-06-18] db/migrations/20260618_msg001_chat.sql
-- 메신저: chat_room / chat_room_member / chat_message 테이블 신설 + 메뉴 등록
-- (hidden_at ALTER 보다 먼저 실행해야 함 — 파일 수정일 순서는 반대였음)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_room (
    room_idx   SERIAL PRIMARY KEY,
    title      VARCHAR(200),
    is_group   BOOLEAN     NOT NULL DEFAULT false,
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.chat_room IS '채팅방 (1:1 / 그룹)';
COMMENT ON COLUMN public.chat_room.is_group IS '그룹방 여부';

CREATE TABLE IF NOT EXISTS public.chat_room_member (
    room_idx     INTEGER     NOT NULL REFERENCES public.chat_room (room_idx) ON DELETE CASCADE,
    user_id      VARCHAR(50) NOT NULL,
    joined_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_read_at TIMESTAMPTZ,
    CONSTRAINT pk_chat_room_member PRIMARY KEY (room_idx, user_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_room_member_user
    ON public.chat_room_member (user_id);

COMMENT ON TABLE public.chat_room_member IS '채팅방 참여자';
COMMENT ON COLUMN public.chat_room_member.last_read_at IS '마지막으로 읽은 시각 (안읽음 수 계산 기준)';

CREATE TABLE IF NOT EXISTS public.chat_message (
    message_idx BIGSERIAL   PRIMARY KEY,
    room_idx    INTEGER     NOT NULL REFERENCES public.chat_room (room_idx) ON DELETE CASCADE,
    sender_id   VARCHAR(50) NOT NULL,
    msg_txt     TEXT        NOT NULL,
    msg_type    VARCHAR(20) NOT NULL DEFAULT 'text',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_message_room_created
    ON public.chat_message (room_idx, created_at);

COMMENT ON TABLE public.chat_message IS '채팅 메시지';

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('msg001', '메신저', NULL, '/chat', 'L', 16, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();


-- ---------------------------------------------------------------------
-- [2026-06-18] db/migrations/20260618_chat_room_member_hidden.sql
-- chat_room_member: 대화방 숨김(소프트 삭제) 컬럼 추가
-- ---------------------------------------------------------------------
ALTER TABLE public.chat_room_member ADD COLUMN IF NOT EXISTS hidden_at TIMESTAMPTZ;
COMMENT ON COLUMN public.chat_room_member.hidden_at IS '대화방을 목록에서 숨긴 시각(소프트 삭제). 이후 새 메시지가 오면 다시 노출.';


-- ---------------------------------------------------------------------
-- [2026-06-18] db/migrations/20260618_msg001_chat_attachment.sql
-- chat_message: 파일 첨부 컬럼 추가, msg_txt NOT NULL 해제
-- ---------------------------------------------------------------------
ALTER TABLE public.chat_message ADD COLUMN IF NOT EXISTS file_name VARCHAR(255), ADD COLUMN IF NOT EXISTS stored_name VARCHAR(255), ADD COLUMN IF NOT EXISTS content_type VARCHAR(127), ADD COLUMN IF NOT EXISTS file_size BIGINT;
ALTER TABLE public.chat_message ALTER COLUMN msg_txt DROP NOT NULL;

COMMENT ON COLUMN public.chat_message.file_name IS '원본 파일명 (첨부 메시지)';
COMMENT ON COLUMN public.chat_message.stored_name IS '디스크 저장 파일명';
COMMENT ON COLUMN public.chat_message.content_type IS 'MIME 타입';
COMMENT ON COLUMN public.chat_message.file_size IS '파일 크기(byte)';


-- ---------------------------------------------------------------------
-- [2026-06-18] db/migrations/20260618_user_mst_admin_yn.sql
-- user_mst: 관리자 플래그 컬럼 추가 + admin 계정 승격
-- ---------------------------------------------------------------------
ALTER TABLE user_mst ADD COLUMN IF NOT EXISTS admin_yn CHAR(1) DEFAULT 'N'::bpchar;

COMMENT ON COLUMN user_mst.admin_yn IS '관리자 여부 (Y: 전 메뉴/권한 허용, 메뉴권한 관리 접근)';

UPDATE user_mst
SET admin_yn = 'Y',
    updated_at = now()
WHERE user_id = 'admin';


-- ---------------------------------------------------------------------
-- [2026-06-19] db/migrations/20260619_chat_message_deleted.sql
-- chat_message: 메시지 삭제(소프트 삭제) 컬럼 추가
-- ---------------------------------------------------------------------
ALTER TABLE public.chat_message ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
COMMENT ON COLUMN public.chat_message.deleted_at IS '메시지를 삭제한 시각(소프트 삭제). NULL 이 아니면 대화에서 노출하지 않는다.';


-- ---------------------------------------------------------------------
-- [2026-07-14] db/migrations/20260714_store_mst_transfer_date.sql
-- store_mst: 양수도 계약일자 컬럼 재확정 (STR001 목록 조회 오류 대응)
-- ---------------------------------------------------------------------
ALTER TABLE public.store_mst ADD COLUMN IF NOT EXISTS transfer_date DATE;

COMMENT ON COLUMN public.store_mst.transfer_date IS '가맹점 양수일';


-- ---------------------------------------------------------------------
-- [2026-07-14] db/migrations/20260714_user_page_filter.sql
-- user_page_filter(사용자별 화면 필터 저장) 테이블 신설
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_page_filter (
    user_idx    INTEGER NOT NULL REFERENCES public.user_mst(user_idx) ON DELETE CASCADE,
    page_code   VARCHAR(50) NOT NULL,
    filter_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_user_page_filter PRIMARY KEY (user_idx, page_code)
);

COMMENT ON TABLE public.user_page_filter IS '사용자별 화면 조회 필터 저장값';
COMMENT ON COLUMN public.user_page_filter.page_code IS '화면 코드 (예: STR001)';


-- ---------------------------------------------------------------------
-- [2026-08-07] db/20260807_user_pwd_reset_yn_and_emp_no.sql
-- user_mst: 비밀번호 강제변경 플래그 + 사번 컬럼 추가
-- ---------------------------------------------------------------------
ALTER TABLE user_mst ADD COLUMN IF NOT EXISTS pwd_reset_yn character(1) DEFAULT 'N';
ALTER TABLE user_mst ADD COLUMN IF NOT EXISTS emp_no varchar(50);

COMMENT ON COLUMN user_mst.pwd_reset_yn IS '초기/재설정 비밀번호 — 다음 로그인 시 변경 강제(Y/N)';
COMMENT ON COLUMN user_mst.emp_no IS '사번(HR 사원번호) — 로그인·CSV 매칭에 쓰는 내부 토큰번호(user_idx)와 별개, 선택 입력';

-- ---------------------------------------------------------------------
-- [2026-08-19] db/migrations/20260819_eap001_menu.sql
-- 전자결재(eap001) 메뉴 마스터 + 전사 권한
-- ---------------------------------------------------------------------
INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('grp_eap', '전자결재', NULL, '/eap', 'G', 40, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('eap001', '전자결재', 'grp_eap', '/eap', 'L', 41, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();

INSERT INTO user_menu_auth (user_idx, menu_cd, can_view, can_create, can_update, can_delete)
SELECT u.user_idx, 'eap001', 'Y', 'Y', 'Y', 'Y'
FROM user_mst u
WHERE NOT EXISTS (
    SELECT 1 FROM user_menu_auth a
    WHERE a.user_idx = u.user_idx AND a.menu_cd = 'eap001'
);

UPDATE user_menu_auth
SET can_view = 'Y',
    can_create = 'Y',
    can_update = 'Y',
    can_delete = 'Y',
    updated_at = now()
WHERE menu_cd = 'eap001';

-- ---------------------------------------------------------------------
-- [2026-08-19] db/migrations/20260819_mst007_form_menu.sql
-- 서식관리(mst007) 메뉴 마스터 + 기존 사용자 권한
-- ---------------------------------------------------------------------
INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('mst007', '서식관리', 'grp_mst', '/eap/forms', 'L', 54, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();

INSERT INTO user_menu_auth (user_idx, menu_cd, can_view, can_create, can_update, can_delete)
SELECT u.user_idx,
       'mst007',
       'Y',
       'Y',
       'Y',
       CASE WHEN COALESCE(u.admin_yn, 'N') = 'Y' THEN 'Y' ELSE 'N' END
FROM user_mst u
WHERE NOT EXISTS (
    SELECT 1 FROM user_menu_auth a
    WHERE a.user_idx = u.user_idx AND a.menu_cd = 'mst007'
);


-- =====================================================================
-- 끝. 총 001_schema.sql 이후 23개 변경 파일 반영
--   신설 테이블: active_att, store_doc, property_doc, usage_log,
--                activity_plan, team_view_permission, activity_plan_store,
--                bbs_folder, bbs_post, bbs_doc, store_nfc_tag,
--                chat_room, chat_room_member, chat_message, user_page_filter
--   주요 컬럼 추가/변경: dept_mst, code_mst, sale_zone_mst, property_mst,
--                         store_mst, user_mst
-- =====================================================================
