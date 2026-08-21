-- 서식관리(mst007) 메뉴 마스터 등록
-- 사이드바 마스터 관리 아래 노출. 메뉴권한 관리(mst003)에서 사람별로 부여한다.

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('mst007', '서식관리', 'grp_mst', '/eap/forms', 'L', 54, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();

-- 기존에 전자결재·활동결재를 쓰던 사람은 서식관리도 열 수 있게 이관한다.
-- 이후 축소는 메뉴권한 관리 화면에서 한다.
INSERT INTO user_menu_auth (user_idx, menu_cd, can_view, can_create, can_update, can_delete)
SELECT u.user_idx,
       'mst007',
       'Y',
       'Y',
       'Y',
       CASE WHEN COALESCE(u.admin_yn, 'N') = 'Y' THEN 'Y' ELSE 'N' END
FROM user_mst u
WHERE NOT EXISTS (
    SELECT 1 FROM user_menu_auth a
    WHERE a.user_idx = u.user_idx AND a.menu_cd = 'mst007'
);
