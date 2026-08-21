-- 자체 전자결재 결재라인 (결재자/합의자/참조자/열람자)

CREATE TABLE IF NOT EXISTS public.eap_doc_line (
    line_id      BIGSERIAL PRIMARY KEY,
    mapping_id   BIGINT NOT NULL REFERENCES public.erp_approval_mappings(id) ON DELETE CASCADE,
    role_cd      VARCHAR(16) NOT NULL,
    sort_order   INT NOT NULL DEFAULT 0,
    user_id      VARCHAR(64) NOT NULL,
    user_nm      VARCHAR(100),
    title_nm     VARCHAR(64),
    line_status  VARCHAR(16) NOT NULL DEFAULT 'WAIT',
    acted_at     TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_eap_doc_line_mapping
    ON public.eap_doc_line(mapping_id, role_cd, sort_order);

CREATE INDEX IF NOT EXISTS idx_eap_doc_line_user
    ON public.eap_doc_line(user_id, line_status);

COMMENT ON TABLE public.eap_doc_line IS '전자결재 문서 결재라인 (결재/합의/참조/열람)';
COMMENT ON COLUMN public.eap_doc_line.line_id IS '결재라인 PK';
COMMENT ON COLUMN public.eap_doc_line.mapping_id IS 'erp_approval_mappings.id';
COMMENT ON COLUMN public.eap_doc_line.role_cd IS '역할 (APPROVER=결재자, AGREE=합의자, CC=참조자, VIEWER=열람자)';
COMMENT ON COLUMN public.eap_doc_line.sort_order IS '역할 내 순서 (결재자는 앞선 순번이 먼저 결재)';
COMMENT ON COLUMN public.eap_doc_line.user_id IS '지정 사원 user_mst.user_id';
COMMENT ON COLUMN public.eap_doc_line.user_nm IS '지정 사원 이름(표시용)';
COMMENT ON COLUMN public.eap_doc_line.title_nm IS '지정 사원 직급/직책(표시용)';
COMMENT ON COLUMN public.eap_doc_line.line_status IS '라인 상태 (WAIT=대기, DONE=완료, REJECT=반려)';
COMMENT ON COLUMN public.eap_doc_line.acted_at IS '결재/반려 처리 시각';
COMMENT ON COLUMN public.eap_doc_line.created_at IS '라인 등록일시';
