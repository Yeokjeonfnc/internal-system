-- 자체 전자결재 서식: 다우 잔여 컬럼 제거, COMMENT 정리

ALTER TABLE public.eap_form_config
    DROP COLUMN IF EXISTS integration_type,
    DROP COLUMN IF EXISTS erp_source_menu,
    DROP COLUMN IF EXISTS html_template_key,
    DROP COLUMN IF EXISTS use_email,
    DROP COLUMN IF EXISTS use_board,
    DROP COLUMN IF EXISTS content_delta;

COMMENT ON TABLE public.eap_form_config IS '전자결재 서식 마스터';
COMMENT ON COLUMN public.eap_form_config.form_code IS '서식 문서번호 (연도-일련번호, 예: 2026-0001, 등록 시 자동 채번)';
COMMENT ON COLUMN public.eap_form_config.form_name IS '서식명';
COMMENT ON COLUMN public.eap_form_config.enabled IS '기안 시 선택 가능 여부';
COMMENT ON COLUMN public.eap_form_config.sort_order IS '목록 정렬 순서';
COMMENT ON COLUMN public.eap_form_config.created_at IS '등록일시';
COMMENT ON COLUMN public.eap_form_config.updated_at IS '수정일시';
COMMENT ON COLUMN public.eap_form_config.category IS '문서분류 (기타문서/기획문서/대외문서/보고문서/업무협조/영업팀문서)';
COMMENT ON COLUMN public.eap_form_config.content_html IS '서식 본문 HTML';
COMMENT ON COLUMN public.eap_form_config.created_by IS '등록자 아이디';
COMMENT ON COLUMN public.eap_form_config.created_by_nm IS '등록자 이름';
