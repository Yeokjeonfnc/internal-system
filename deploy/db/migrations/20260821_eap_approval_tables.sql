-- 전자결재(EAP) 실동작 테이블 — 깃허브에서 가져온 전자결재 구현이 요구하는 스키마.
--
-- 배경
--   전자결재 코드(EapDocumentService / Eap*Mapper.xml)는 아래 세 테이블을 전제로
--   동작하는데, 원격 브랜치에는 이 테이블을 만드는 SQL 이 한 건도 없었다.
--   이 파일 없이 코드만 올리면 전자결재의 모든 화면이 즉시 500 으로 떨어진다.
--   (매퍼 XML 에서 실제 사용하는 컬럼만 그대로 옮겨 적었다.)
--
-- 안전성
--   전부 IF NOT EXISTS / ADD COLUMN IF NOT EXISTS / ON CONFLICT 라서
--   이미 만들어져 있는 서버에서 다시 돌려도 아무 것도 지우거나 덮어쓰지 않는다.
--   기존 메뉴·계정·권한 데이터는 건드리지 않는다.
--
-- 실행
--   psql -h localhost -p 5433 -U postgres -d yj_db_test -f 20260821_eap_approval_tables.sql
--   (한글 주석이 깨져 트랜잭션이 죽으면 먼저:  $env:PGCLIENTENCODING="UTF8" )

BEGIN;

-- 1) 결재 양식(서식관리 화면에서 만드는 문서 서식) -----------------------------
CREATE TABLE IF NOT EXISTS public.eap_form_config (
    form_code     VARCHAR(100) PRIMARY KEY,
    form_name     VARCHAR(200) NOT NULL,
    enabled       BOOLEAN      NOT NULL DEFAULT TRUE,
    sort_order    INTEGER      NOT NULL DEFAULT 0,
    category      VARCHAR(100) NOT NULL DEFAULT '기타문서',
    content_html  TEXT,
    field_schema  TEXT,
    created_by    VARCHAR(50),
    created_by_nm VARCHAR(100),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 이미 있는 서버 대비 — 나중에 늘어난 컬럼 보강.
ALTER TABLE public.eap_form_config ADD COLUMN IF NOT EXISTS category      VARCHAR(100) NOT NULL DEFAULT '기타문서';
ALTER TABLE public.eap_form_config ADD COLUMN IF NOT EXISTS content_html  TEXT;
ALTER TABLE public.eap_form_config ADD COLUMN IF NOT EXISTS field_schema  TEXT;
ALTER TABLE public.eap_form_config ADD COLUMN IF NOT EXISTS created_by    VARCHAR(50);
ALTER TABLE public.eap_form_config ADD COLUMN IF NOT EXISTS created_by_nm VARCHAR(100);

COMMENT ON TABLE public.eap_form_config IS '전자결재 서식(마스터 > 서식관리)';

-- 2) 결재 문서 본체 ------------------------------------------------------------
--    이름이 eap_ 가 아니라 erp_approval_mappings 인 것은 매퍼 XML 에 그렇게
--    적혀 있기 때문이다. 이름을 바꾸면 코드가 못 찾는다.
CREATE TABLE IF NOT EXISTS public.erp_approval_mappings (
    id               BIGSERIAL PRIMARY KEY,
    erp_menu_id      VARCHAR(50),
    erp_source_id    VARCHAR(100),
    daou_document_id VARCHAR(100),
    daou_form_code   VARCHAR(100),
    status           VARCHAR(30),
    draft_user_id    VARCHAR(50),
    title            VARCHAR(500),
    content_html     TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.erp_approval_mappings ADD COLUMN IF NOT EXISTS daou_form_code VARCHAR(100);
ALTER TABLE public.erp_approval_mappings ADD COLUMN IF NOT EXISTS title          VARCHAR(500);
ALTER TABLE public.erp_approval_mappings ADD COLUMN IF NOT EXISTS content_html   TEXT;
ALTER TABLE public.erp_approval_mappings ADD COLUMN IF NOT EXISTS draft_user_id  VARCHAR(50);

CREATE INDEX IF NOT EXISTS idx_erp_approval_mappings_drafter
    ON public.erp_approval_mappings (draft_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_erp_approval_mappings_status
    ON public.erp_approval_mappings (status);

COMMENT ON TABLE public.erp_approval_mappings IS '전자결재 문서(기안 본문·상태)';

-- 3) 결재선(결재자·합의·참조·열람) ---------------------------------------------
CREATE TABLE IF NOT EXISTS public.eap_doc_line (
    line_id     BIGSERIAL PRIMARY KEY,
    mapping_id  BIGINT       NOT NULL
                    REFERENCES public.erp_approval_mappings (id) ON DELETE CASCADE,
    role_cd     VARCHAR(20)  NOT NULL,
    sort_order  INTEGER      NOT NULL DEFAULT 0,
    user_id     VARCHAR(50)  NOT NULL,
    user_nm     VARCHAR(100),
    title_nm    VARCHAR(100),
    line_status VARCHAR(20),
    acted_at    TIMESTAMPTZ,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_eap_doc_line_mapping ON public.eap_doc_line (mapping_id);
CREATE INDEX IF NOT EXISTS idx_eap_doc_line_user    ON public.eap_doc_line (user_id, line_status);

COMMENT ON TABLE public.eap_doc_line IS '전자결재 결재선(APPROVER/AGREE/CC/VIEWER)';

COMMIT;
