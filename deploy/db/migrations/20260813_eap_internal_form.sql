-- 자체 전자결재 서식(본문 HTML/에디터 Delta, 문서분류, 등록자)

ALTER TABLE public.eap_form_config
    ADD COLUMN IF NOT EXISTS category VARCHAR(64) NOT NULL DEFAULT '기타문서';

ALTER TABLE public.eap_form_config
    ADD COLUMN IF NOT EXISTS content_html TEXT;

ALTER TABLE public.eap_form_config
    ADD COLUMN IF NOT EXISTS content_delta TEXT;

ALTER TABLE public.eap_form_config
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(64);

ALTER TABLE public.eap_form_config
    ADD COLUMN IF NOT EXISTS created_by_nm VARCHAR(100);

COMMENT ON COLUMN public.eap_form_config.category IS '문서분류 (기타문서/기획문서/대외문서/보고문서/업무협조/영업팀문서 등)';
COMMENT ON COLUMN public.eap_form_config.content_html IS '서식 본문 HTML (기안 미리보기·상세용)';
COMMENT ON COLUMN public.eap_form_config.content_delta IS '서식 본문 Quill Delta JSON (편집 재로딩용)';
COMMENT ON COLUMN public.eap_form_config.created_by IS '등록자 아이디';
COMMENT ON COLUMN public.eap_form_config.created_by_nm IS '등록자 이름';
