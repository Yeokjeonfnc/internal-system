-- 전자결재(eap001) 메뉴 마스터 등록 + 전 사원 조회/쓰기 권한
-- 서식관리는 마스터 관리의 mst007 로 따로 부여한다.

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('grp_eap', '전자결재', NULL, '/eap', 'G', 40, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('eap001', '전자결재', 'grp_eap', '/eap', 'L', 41, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();

INSERT INTO user_menu_auth (user_idx, menu_cd, can_view, can_create, can_update, can_delete)
SELECT u.user_idx, 'eap001', 'Y', 'Y', 'Y', 'Y'
FROM user_mst u
WHERE NOT EXISTS (
    SELECT 1 FROM user_menu_auth a
    WHERE a.user_idx = u.user_idx AND a.menu_cd = 'eap001'
);

UPDATE user_menu_auth
SET can_view = 'Y',
    can_create = 'Y',
    can_update = 'Y',
    can_delete = 'Y',
    updated_at = now()
WHERE menu_cd = 'eap001';
