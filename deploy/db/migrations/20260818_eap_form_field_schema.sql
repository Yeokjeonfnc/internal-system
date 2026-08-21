-- 전자결재 서식 필드 스키마 (양식 빌더 메타)

ALTER TABLE public.eap_form_config
    ADD COLUMN IF NOT EXISTS field_schema TEXT;

COMMENT ON COLUMN public.eap_form_config.field_schema IS '양식 빌더 필드 정의 JSON 배열 (id, type, label, required, options 등)';
