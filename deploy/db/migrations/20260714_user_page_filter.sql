-- 사용자별 페이지 필터. 같은 사용자의 같은 화면에는 항상 한 행만 유지한다.
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
