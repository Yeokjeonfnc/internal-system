-- 가맹점 양수일. 기존 store_mst 스키마에는 이 컬럼이 없어 STR001 목록 조회가 실패한다.
ALTER TABLE public.store_mst
    ADD COLUMN IF NOT EXISTS transfer_date DATE;

COMMENT ON COLUMN public.store_mst.transfer_date IS '가맹점 양수일';
