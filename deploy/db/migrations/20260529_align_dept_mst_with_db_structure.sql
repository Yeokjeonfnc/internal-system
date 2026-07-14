BEGIN;

ALTER TABLE public.dept_mst
    ADD COLUMN IF NOT EXISTS dept_type character varying(50);

ALTER TABLE public.dept_mst
    ADD COLUMN IF NOT EXISTS use_yn character(1) DEFAULT 'Y'::bpchar;

ALTER TABLE public.dept_mst
    ADD COLUMN IF NOT EXISTS create_dt timestamp with time zone DEFAULT CURRENT_TIMESTAMP;

UPDATE public.dept_mst
SET use_yn = 'Y'
WHERE use_yn IS NULL;

COMMENT ON COLUMN public.dept_mst.dept_type IS '부서타입';
COMMENT ON COLUMN public.dept_mst.use_yn IS '사용여부';
COMMENT ON COLUMN public.dept_mst.create_dt IS '생성일시';

COMMIT;
