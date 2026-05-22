BEGIN;

-- Common codes.
INSERT INTO code_mst (grp_cd, code_cd, code_nm, use_yn) VALUES
('10', 'new', 'New contract', 'Y'),
('10', 'transfer', 'Transfer', 'Y'),
('10', 'renewal', 'Renewal', 'Y'),
('10', 'closed', 'Closed', 'Y'),
('20', '1', 'Seoul', 'Y'),
('20', '2', 'Busan', 'Y'),
('20', '3', 'Daegu', 'Y'),
('20', '4', 'Incheon', 'Y'),
('20', '5', 'Gwangju', 'Y'),
('20', '6', 'Daejeon', 'Y'),
('30', 'FR', 'Franchise', 'Y'),
('30', 'DI', 'Direct store', 'Y'),
('40', 'YJ', 'Yeokjeon Beer', 'Y'),
('40', 'TEST', 'Test Brand', 'Y'),
('50', 'EXT', 'Exterior', 'Y'),
('50', 'HALL', 'Hall', 'Y'),
('50', 'KIT', 'Kitchen', 'Y'),
('60', '01', 'Staff', 'Y'),
('60', '02', 'Assistant Manager', 'Y'),
('60', '03', 'Manager', 'Y'),
('60', '04', 'Deputy General Manager', 'Y'),
('60', '05', 'General Manager', 'Y'),
('60', '06', 'CEO', 'Y')
ON CONFLICT (grp_cd, code_cd) DO UPDATE
SET code_nm = EXCLUDED.code_nm,
    use_yn = EXCLUDED.use_yn;

-- Departments.
INSERT INTO dept_mst (dept_idx, dept_nm, upper_dept_idx, dept_level, sort_order) VALUES
(1, 'Head Office', NULL, 1, 10),
(2, 'Operations Division', 1, 2, 20),
(3, 'Development Division', 1, 2, 30),
(4, 'Master Data Team', 1, 2, 40),
(5, 'Test Branch Team', 2, 3, 50)
ON CONFLICT (dept_idx) DO UPDATE
SET dept_nm = EXCLUDED.dept_nm,
    upper_dept_idx = EXCLUDED.upper_dept_idx,
    dept_level = EXCLUDED.dept_level,
    sort_order = EXCLUDED.sort_order;

-- Menus.
INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn) VALUES
('dsh001', 'Dashboard', NULL, '/', 'L', 10, 'Y'),
('str001', 'Store Management', NULL, '/stores', 'L', 20, 'Y'),
('grp_dev', 'Development Management', NULL, NULL, 'G', 30, 'Y'),
('dev001', 'Founder Management', 'grp_dev', '/founders', 'L', 31, 'Y'),
('dev002', 'Property Management', 'grp_dev', '/properties', 'L', 32, 'Y'),
('dev003', 'Sales Area Management', 'grp_dev', '/sales-areas', 'L', 33, 'Y'),
('grp_act', 'Activity Management', NULL, NULL, 'G', 40, 'Y'),
('act001', 'Activity Status', 'grp_act', '/activities/group/status', 'L', 41, 'Y'),
('act002', 'Activity Management', 'grp_act', '/activities/group/manage', 'L', 42, 'Y'),
('act003', 'Activity Approval', 'grp_act', '/activities/approval/all', 'L', 43, 'Y'),
('grp_mst', 'Master Management', NULL, NULL, 'G', 50, 'Y'),
('mst001', 'User Management', 'grp_mst', '/master/users', 'L', 51, 'Y'),
('mst002', 'Department Management', 'grp_mst', '/master/departments', 'L', 52, 'Y'),
('mst003', 'Menu Permission Management', 'grp_mst', '/master/menu-permissions', 'L', 53, 'Y'),
('mst004', 'Checklist Management', 'grp_mst', '/master/checklists', 'L', 54, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();

-- Test users. admin is treated as a super admin by application.yml.
INSERT INTO user_mst (
    user_idx, user_name, user_id, user_password, dept_idx, user_phone,
    user_email, sv_yn, position_cd, tag_yn, join_dt
) VALUES
(1, 'System Admin', 'admin', 'admin123', 4, '010-0000-0001', 'admin@example.test', 'Y', '06', 'Y', '2024-01-01'),
(2, 'Test Admin', 'admim', 'admin123', 4, '010-0000-0002', 'admim@example.test', 'Y', '05', 'Y', '2024-01-01'),
(3, 'Test Supervisor', 'svtest', 'admin123', 2, '010-0000-0003', 'svtest@example.test', 'Y', '03', 'Y', '2024-02-01'),
(4, 'Test Manager', 'mgrtest', 'admin123', 3, '010-0000-0004', 'mgrtest@example.test', 'N', '03', 'N', '2024-03-01')
ON CONFLICT (user_idx) DO UPDATE
SET user_name = EXCLUDED.user_name,
    user_id = EXCLUDED.user_id,
    user_password = EXCLUDED.user_password,
    dept_idx = EXCLUDED.dept_idx,
    user_phone = EXCLUDED.user_phone,
    user_email = EXCLUDED.user_email,
    sv_yn = EXCLUDED.sv_yn,
    position_cd = EXCLUDED.position_cd,
    tag_yn = EXCLUDED.tag_yn,
    join_dt = EXCLUDED.join_dt,
    updated_at = CURRENT_TIMESTAMP;

-- Grant admim full menu permissions for local testing.
INSERT INTO user_menu_auth (user_idx, menu_cd, can_view, can_create, can_update, can_delete)
SELECT 2, menu_cd, 'Y', 'Y', 'Y', 'Y'
FROM menu_mst
ON CONFLICT (user_idx, menu_cd) DO UPDATE
SET can_view = EXCLUDED.can_view,
    can_create = EXCLUDED.can_create,
    can_update = EXCLUDED.can_update,
    can_delete = EXCLUDED.can_delete,
    updated_at = now();

-- Development sample data.
INSERT INTO partner_mst (
    partner_idx, partner_nm, partner_status, partner_tel, partner_email,
    gender, partner_birth, p_zip_cd, p_address, p_address_detail, p_region
) VALUES
(1, 'Test Founder A', 'PROSPECT', '010-1111-1111', 'founder-a@example.test', 'M', '1985-04-12', '06164', 'Seoul Gangnam-gu Teheran-ro 1', '2F', '1'),
(2, 'Test Founder B', 'PROSPECT', '010-2222-2222', 'founder-b@example.test', 'F', '1990-07-08', '48058', 'Busan Haeundae-gu Centum 1-ro 1', '101', '2')
ON CONFLICT (partner_idx) DO UPDATE
SET partner_nm = EXCLUDED.partner_nm,
    partner_status = EXCLUDED.partner_status,
    partner_tel = EXCLUDED.partner_tel,
    partner_email = EXCLUDED.partner_email,
    gender = EXCLUDED.gender,
    partner_birth = EXCLUDED.partner_birth,
    p_zip_cd = EXCLUDED.p_zip_cd,
    p_address = EXCLUDED.p_address,
    p_address_detail = EXCLUDED.p_address_detail,
    p_region = EXCLUDED.p_region,
    update_dt = CURRENT_TIMESTAMP;

INSERT INTO property_mst (
    prop_idx, prop_nm, zip_cd, address, address_detail, region, prop_status,
    prop_type, floor, cont_area, real_area, rent_deposit, monthly_rent,
    premium_fee, maint_fee, prop_notes, survey_dt, latitude, longitude, surveyor
) VALUES
(1, 'Gangnam Test Property', '06164', 'Seoul Gangnam-gu Teheran-ro 10', '1F', '1', 'CONTRACTED', 'LEASE', 1, 115.50, 88.20, 80000000, 5200000, 10000000, 500000, 'Seeded test property', '2026-05-01', 37.4980950, 127.0276100, 'Test Supervisor'),
(2, 'Haeundae Test Property', '48058', 'Busan Haeundae-gu Centum 1-ro 20', 'B1', '2', 'PENDING', 'LEASE', -1, 98.00, 72.40, 60000000, 4100000, 8000000, 420000, 'Seeded test property', '2026-05-02', 35.1699500, 129.1302200, 'Test Supervisor'),
(3, 'Daegu Test Property', '41911', 'Daegu Jung-gu Dongseong-ro 15', '3F', '3', 'PENDING', 'LEASE', 3, 105.00, 79.50, 55000000, 3600000, 7000000, 390000, 'Seeded test property', '2026-05-03', 35.8693200, 128.5946900, 'Test Supervisor')
ON CONFLICT (prop_idx) DO UPDATE
SET prop_nm = EXCLUDED.prop_nm,
    zip_cd = EXCLUDED.zip_cd,
    address = EXCLUDED.address,
    address_detail = EXCLUDED.address_detail,
    region = EXCLUDED.region,
    prop_status = EXCLUDED.prop_status,
    prop_type = EXCLUDED.prop_type,
    floor = EXCLUDED.floor,
    cont_area = EXCLUDED.cont_area,
    real_area = EXCLUDED.real_area,
    rent_deposit = EXCLUDED.rent_deposit,
    monthly_rent = EXCLUDED.monthly_rent,
    premium_fee = EXCLUDED.premium_fee,
    maint_fee = EXCLUDED.maint_fee,
    prop_notes = EXCLUDED.prop_notes,
    survey_dt = EXCLUDED.survey_dt,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    surveyor = EXCLUDED.surveyor,
    update_dt = CURRENT_TIMESTAMP;

INSERT INTO sale_zone_mst (zone_idx, zone_nm, brand_cd) VALUES
(1, 'Seoul Central Zone', 'YJ'),
(2, 'Busan East Zone', 'YJ'),
(3, 'Daegu Strategic Zone', 'YJ')
ON CONFLICT (zone_idx) DO UPDATE
SET zone_nm = EXCLUDED.zone_nm,
    brand_cd = EXCLUDED.brand_cd,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO store_mst (
    store_idx, store_cd, store_nm, owner_nm, region_cd, store_tel, address,
    latitude, longitude, store_status, cont_end_dt, auto_renewal_yn, store_type,
    adress_detail, zip_cd, brand_cd, cont_start_dt, business_number, fr_fee,
    edu_fee, insu_deposit, cont_deposit, cont_manager, edu_manager, sv_id,
    first_cont_dt, cont_area, real_area, floor, parking_count, premium_fee,
    monthly_rent, rent_deposit, notes, prop_idx, partner_idx, zone_idx
) VALUES
(1, 'TST-001', 'Gangnam Test Store', 'Owner A', '1', '02-1111-1111', 'Seoul Gangnam-gu Teheran-ro 10', 37.4980950, 127.0276100, 'new', '2028-05-31', true, 'FR', '1F', '06164', 'YJ', '2026-05-20', '111-11-11111', 5000000, 2000000, 1000000, 10000000, 'mgrtest', 'mgrtest', 'svtest', '2026-05-20', 115.50, 88.20, 1, 2, 10000000, 5200000, 80000000, 'Seeded test store', 1, 1, 1),
(2, 'TST-002', 'Haeundae Test Store', 'Owner B', '2', '051-222-2222', 'Busan Haeundae-gu Centum 1-ro 20', 35.1699500, 129.1302200, 'renewal', '2029-04-30', true, 'FR', 'B1', '48058', 'YJ', '2025-04-01', '222-22-22222', 5000000, 2000000, 1000000, 10000000, 'mgrtest', 'mgrtest', 'svtest', '2025-04-01', 98.00, 72.40, -1, 0, 8000000, 4100000, 60000000, 'Seeded test store', 2, 2, 2),
(3, 'TST-003', 'Daegu Direct Test Store', 'Head Office', '3', '053-333-3333', 'Daegu Jung-gu Dongseong-ro 15', 35.8693200, 128.5946900, 'new', '2028-12-31', false, 'DI', '3F', '41911', 'YJ', '2026-01-15', '333-33-33333', 0, 0, 0, 0, 'mgrtest', 'mgrtest', 'svtest', '2026-01-15', 105.00, 79.50, 3, 1, 7000000, 3600000, 55000000, 'Seeded direct store', 3, NULL, NULL)
ON CONFLICT (store_idx) DO UPDATE
SET store_cd = EXCLUDED.store_cd,
    store_nm = EXCLUDED.store_nm,
    owner_nm = EXCLUDED.owner_nm,
    region_cd = EXCLUDED.region_cd,
    store_tel = EXCLUDED.store_tel,
    address = EXCLUDED.address,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    store_status = EXCLUDED.store_status,
    cont_end_dt = EXCLUDED.cont_end_dt,
    auto_renewal_yn = EXCLUDED.auto_renewal_yn,
    store_type = EXCLUDED.store_type,
    adress_detail = EXCLUDED.adress_detail,
    zip_cd = EXCLUDED.zip_cd,
    brand_cd = EXCLUDED.brand_cd,
    cont_start_dt = EXCLUDED.cont_start_dt,
    business_number = EXCLUDED.business_number,
    fr_fee = EXCLUDED.fr_fee,
    edu_fee = EXCLUDED.edu_fee,
    insu_deposit = EXCLUDED.insu_deposit,
    cont_deposit = EXCLUDED.cont_deposit,
    cont_manager = EXCLUDED.cont_manager,
    edu_manager = EXCLUDED.edu_manager,
    sv_id = EXCLUDED.sv_id,
    first_cont_dt = EXCLUDED.first_cont_dt,
    cont_area = EXCLUDED.cont_area,
    real_area = EXCLUDED.real_area,
    floor = EXCLUDED.floor,
    parking_count = EXCLUDED.parking_count,
    premium_fee = EXCLUDED.premium_fee,
    monthly_rent = EXCLUDED.monthly_rent,
    rent_deposit = EXCLUDED.rent_deposit,
    notes = EXCLUDED.notes,
    prop_idx = EXCLUDED.prop_idx,
    partner_idx = EXCLUDED.partner_idx,
    zone_idx = EXCLUDED.zone_idx,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO chk_mst (chk_idx, chk_type, chk_content, base_score, brand_cd) VALUES
(1, 'EXT', 'Signage and exterior condition', 10, 'YJ'),
(2, 'HALL', 'Hall cleanliness', 10, 'YJ'),
(3, 'KIT', 'Kitchen hygiene', 10, 'YJ')
ON CONFLICT (chk_idx) DO UPDATE
SET chk_type = EXCLUDED.chk_type,
    chk_content = EXCLUDED.chk_content,
    base_score = EXCLUDED.base_score,
    brand_cd = EXCLUDED.brand_cd;

INSERT INTO active_mst (act_idx, store_idx, act_type, act_dt, act_notes, sv_id, appr_status, chk_yn, memo_txt) VALUES
(1, 1, 'VISIT', '2026-05-20', 'Seeded visit activity', 'svtest', 'PENDING', 'Y', 'Follow-up required'),
(2, 2, 'CALL', '2026-05-19', 'Seeded call activity', 'svtest', 'APPROVED', 'N', 'No issue')
ON CONFLICT (act_idx) DO UPDATE
SET store_idx = EXCLUDED.store_idx,
    act_type = EXCLUDED.act_type,
    act_dt = EXCLUDED.act_dt,
    act_notes = EXCLUDED.act_notes,
    sv_id = EXCLUDED.sv_id,
    appr_status = EXCLUDED.appr_status,
    chk_yn = EXCLUDED.chk_yn,
    memo_txt = EXCLUDED.memo_txt;

INSERT INTO notif_mst (notif_idx, user_id, msg_txt, notif_typ, read_yn, appr_yn, act_idx) VALUES
(1, 'admin', 'Seeded approval notification', 'APPROVAL', 'N', 'Y', 1),
(2, 'admim', 'Seeded store follow-up notification', 'STORE', 'N', 'N', 2)
ON CONFLICT (notif_idx) DO UPDATE
SET user_id = EXCLUDED.user_id,
    msg_txt = EXCLUDED.msg_txt,
    notif_typ = EXCLUDED.notif_typ,
    read_yn = EXCLUDED.read_yn,
    appr_yn = EXCLUDED.appr_yn,
    act_idx = EXCLUDED.act_idx;

ALTER SEQUENCE IF EXISTS public.store_mst_store_idx_seq OWNED BY public.store_mst.store_idx;
SELECT setval('public.store_mst_store_idx_seq', COALESCE((SELECT MAX(store_idx) FROM store_mst), 1), true);
SELECT setval(pg_get_serial_sequence('dept_mst', 'dept_idx'), COALESCE((SELECT MAX(dept_idx) FROM dept_mst), 1), true);
SELECT setval(pg_get_serial_sequence('user_mst', 'user_idx'), COALESCE((SELECT MAX(user_idx) FROM user_mst), 1), true);
SELECT setval(pg_get_serial_sequence('partner_mst', 'partner_idx'), COALESCE((SELECT MAX(partner_idx) FROM partner_mst), 1), true);
SELECT setval(pg_get_serial_sequence('property_mst', 'prop_idx'), COALESCE((SELECT MAX(prop_idx) FROM property_mst), 1), true);
SELECT setval(pg_get_serial_sequence('sale_zone_mst', 'zone_idx'), COALESCE((SELECT MAX(zone_idx) FROM sale_zone_mst), 1), true);
SELECT setval(pg_get_serial_sequence('chk_mst', 'chk_idx'), COALESCE((SELECT MAX(chk_idx) FROM chk_mst), 1), true);
SELECT setval(pg_get_serial_sequence('active_mst', 'act_idx'), COALESCE((SELECT MAX(act_idx) FROM active_mst), 1), true);
SELECT setval(pg_get_serial_sequence('notif_mst', 'notif_idx'), COALESCE((SELECT MAX(notif_idx) FROM notif_mst), 1), true);

COMMIT;
