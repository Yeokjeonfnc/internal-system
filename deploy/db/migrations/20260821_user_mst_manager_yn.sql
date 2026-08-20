-- 부서관리(mst002) '부서장' — 근거 컬럼이 실 DB 에 없어 전 부서에서 '-' 로 고정돼 있었다.
--
-- MstService.loadManagerNames() 는 user_mst 에서 manager_yn / leader_yn /
-- dept_manager_yn / responsible_yn 중 하나를 information_schema 로 찾고, 하나도 없으면
-- 빈 Map 을 돌려준다(예외도 로그도 남지 않는다). 그래서 화면에는 "부서장이 아직
-- 지정되지 않은 것"처럼 보이지만 실제로는 무슨 값을 넣어도 채워질 수 없는 상태였다.
-- 첫 번째 후보인 manager_yn 을 만들어 그 조회 경로를 살린다.
--
-- 컬럼이 없어도 백엔드는 위 폴백으로 그대로 동작하므로 적용 전후 모두 안전하다.

ALTER TABLE user_mst
    ADD COLUMN IF NOT EXISTS manager_yn CHAR(1) DEFAULT 'N'::bpchar;

COMMENT ON COLUMN user_mst.manager_yn IS '부서장 여부 (Y: 소속 부서의 부서장) — mst002 부서장 표시 근거';

-- 값을 지정하는 화면 경로는 아직 없다(사원 상세에 입력란이 없다).
-- 당장 필요한 부서장은 아래 형태로 직접 지정한다.
-- UPDATE user_mst SET manager_yn = 'Y', updated_at = now() WHERE user_id = '<로그인ID>';
