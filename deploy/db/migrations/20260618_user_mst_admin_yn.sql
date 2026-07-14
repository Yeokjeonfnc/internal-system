-- user_mst 관리자 플래그 — 모든 메뉴/권한 허용 + 메뉴권한 관리 전용

ALTER TABLE user_mst
    ADD COLUMN IF NOT EXISTS admin_yn CHAR(1) DEFAULT 'N'::bpchar;

COMMENT ON COLUMN user_mst.admin_yn IS '관리자 여부 (Y: 전 메뉴/권한 허용, 메뉴권한 관리 접근)';

-- 기존 admin 계정을 관리자(Y)로 승격
UPDATE user_mst
SET admin_yn = 'Y',
    updated_at = now()
WHERE user_id = 'admin';
