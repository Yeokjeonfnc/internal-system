-- 초기 비밀번호 강제변경 표시(pwd_reset_yn) + 사번(emp_no) 컬럼 추가.
--
-- 둘 다 추가만 한다(ALTER TABLE ADD COLUMN IF NOT EXISTS) — 기존 데이터는
-- 건드리지 않는다. 애플리케이션은 이 두 컬럼이 없어도 정상 동작하도록
-- 방어 코드가 이미 들어가 있으므로, 이 마이그레이션은 급하지 않다:
--   - pwd_reset_yn 이 없으면: 비밀번호 초기화/자동생성 자체는 되지만
--     "다음 로그인 시 반드시 변경" 강제는 걸리지 않는다.
--   - emp_no 가 없으면: 사원 상세 화면의 "사번" 입력이 저장 시 오류 메시지를
--     보여줄 뿐, 다른 기능(로그인/CSV 업로드 등)에는 영향이 없다.
BEGIN;

ALTER TABLE user_mst
    ADD COLUMN IF NOT EXISTS pwd_reset_yn character(1) DEFAULT 'N';

ALTER TABLE user_mst
    ADD COLUMN IF NOT EXISTS emp_no varchar(50);

COMMENT ON COLUMN user_mst.pwd_reset_yn IS '초기/재설정 비밀번호 — 다음 로그인 시 변경 강제(Y/N)';
COMMENT ON COLUMN user_mst.emp_no IS '사번(HR 사원번호) — 로그인·CSV 매칭에 쓰는 내부 토큰번호(user_idx)와 별개, 선택 입력';

COMMIT;
