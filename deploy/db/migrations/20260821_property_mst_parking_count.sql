-- 물건(property_mst) 주차가능대수 컬럼 추가.
--
-- 개발관리 > 물건관리 > 상세조건 탭의 "주차가능대수" 입력칸은 예전부터 있었지만
-- 저장할 컬럼이 없어 값이 조용히 버려지고 있었다(입력 → '저장되었습니다' → 다시 열면 빈칸).
-- 가맹점(store_mst.parking_count)에는 이미 같은 컬럼이 있다.
--
-- 추가만 한다(ADD COLUMN IF NOT EXISTS) — 기존 데이터는 건드리지 않는다.
-- 애플리케이션은 이 컬럼이 없어도 정상 동작하도록 방어돼 있으므로(DevService 가
-- information_schema 로 컬럼 존재를 먼저 확인하고, 없으면 주차가능대수만 건너뛴다)
-- 이 마이그레이션은 급하지 않다. 적용 전에는 주차가능대수만 계속 빈칸으로 보인다.
BEGIN;

ALTER TABLE public.property_mst
    ADD COLUMN IF NOT EXISTS parking_count integer;

COMMENT ON COLUMN public.property_mst.parking_count IS '주차가능대수 — 선택 입력';

COMMIT;
