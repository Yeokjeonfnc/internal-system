-- 비밀번호 BCrypt 전환 + 전체 초기화
--
-- 배경: user_mst.user_password 가 평문으로 저장되고 로그인도 SQL 동등비교였다.
--       DB 가 유출되면 전 직원 비밀번호가 그대로 노출되는 구조라 BCrypt 해시로 전환한다.
--
-- 이 스크립트는 되돌릴 수 없다(기존 평문 비밀번호는 사라진다).
-- 반드시 실행 전에 backup-db.ps1 로 백업할 것.
--
-- 실행 후 전 직원 초기 비밀번호:  yeokjeon1234!
-- 최초 로그인 시 앱이 비밀번호 변경 화면을 강제한다(pwd_reset_yn = 'Y').

BEGIN;

-- 1) 최초 로그인 시 비밀번호 변경 강제 플래그
ALTER TABLE user_mst
    ADD COLUMN IF NOT EXISTS pwd_reset_yn CHAR(1) DEFAULT 'N'::bpchar;

COMMENT ON COLUMN user_mst.pwd_reset_yn IS '초기화된 비밀번호 여부 (Y: 최초 로그인 시 변경 강제)';

-- 2) 전 계정 비밀번호를 초기값의 BCrypt 해시로 재설정
--    해시 원문: yeokjeon1234!  (BCrypt cost 10)
UPDATE user_mst
SET user_password = '$2a$10$H.UsG9YqGuq6b5Nsu.tyG.Y/U0zC/DgJYxZkSNAvzTTGDWmnCoxwy',
    pwd_reset_yn  = 'Y',
    updated_at    = now();

COMMIT;

-- 확인용 — 전부 해시($2a$...)로 바뀌었고 pwd_reset_yn = 'Y' 인지
-- SELECT user_id, left(user_password, 7) AS pw_prefix, pwd_reset_yn FROM user_mst ORDER BY user_id;
