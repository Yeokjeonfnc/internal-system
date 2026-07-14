-- 가맹점 폐점 여부

ALTER TABLE public.store_mst
    ADD COLUMN IF NOT EXISTS closed_yn CHAR(1) NOT NULL DEFAULT 'N';

COMMENT ON COLUMN public.store_mst.closed_yn IS '폐점 여부 (Y/N). 계약상태 closed 선택 시 Y';

UPDATE public.store_mst
SET closed_yn = 'Y'
WHERE LOWER(TRIM(COALESCE(store_status, ''))) = 'closed';

UPDATE public.code_mst
SET code_nm = '폐점'
WHERE grp_cd = 10
  AND LOWER(TRIM(code_cd)) = 'closed';
