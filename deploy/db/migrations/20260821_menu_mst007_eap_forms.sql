-- 마스터 > 서식관리(mst007) 메뉴 등록 + 기존 사용자 권한 행 보강.
--
-- 배경
--   전자결재 서식을 만드는 화면(/eap/forms)이 새로 생겼고, 백엔드는 이 화면의
--   모든 API 를 menu_cd = 'mst007' 권한으로 막는다(EapController).
--   menu_mst 에 행이 없으면 사이드바에 아예 안 뜨고, user_menu_auth 에 행이
--   없으면 가드가 fail-closed 라서 관리자 외에는 전부 403 이 된다.
--   "가드(코드)와 권한(데이터)은 한 쌍" — 코드만 올리면 안 된다.
--
-- 안전성
--   메뉴 1건 upsert + 없는 권한 행만 INSERT. 기존 권한을 축소하지 않는다.
--
-- 실행
--   psql -h localhost -p 5433 -U postgres -d yj_db_test -f 20260821_menu_mst007_eap_forms.sql

BEGIN;

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('mst007', '서식관리', 'grp_mst', '/eap/forms', 'L', 57, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm        = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path     = EXCLUDED.route_path,
    menu_type      = EXCLUDED.menu_type,
    sort_order     = EXCLUDED.sort_order,
    use_yn         = EXCLUDED.use_yn,
    updated_at     = now();

-- 전 사용자에게 mst007 권한 행을 만들어 둔다.
--   조회는 'Y'  → 다른 마스터 메뉴와 동일하게 사이드바에 보인다.
--   쓰기는 'N'  → 서식 생성·수정·삭제는 관리자(admin_yn='Y')만. 필요한 사람은
--                 메뉴권한 관리(mst003) 화면에서 개별로 열어 주면 된다.
INSERT INTO user_menu_auth (user_idx, menu_cd, can_view, can_create, can_update, can_delete)
SELECT u.user_idx, 'mst007', 'Y', 'N', 'N', 'N'
FROM user_mst u
WHERE NOT EXISTS (SELECT 1
                  FROM user_menu_auth a
                  WHERE a.user_idx = u.user_idx
                    AND a.menu_cd = 'mst007');

COMMIT;

-- 롤백이 필요하면:
--   DELETE FROM user_menu_auth WHERE menu_cd = 'mst007';
--   UPDATE menu_mst SET use_yn = 'N' WHERE menu_cd = 'mst007';
