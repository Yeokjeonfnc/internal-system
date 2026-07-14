-- user_mst 가맹점 연결 + 가맹주관리 메뉴

ALTER TABLE user_mst
    ADD COLUMN IF NOT EXISTS store_idx INTEGER;

COMMENT ON COLUMN user_mst.store_idx IS '소속 가맹점 (가맹점주 계정)';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_mst_store_idx'
    ) THEN
        ALTER TABLE user_mst
            ADD CONSTRAINT fk_user_mst_store_idx
                FOREIGN KEY (store_idx) REFERENCES store_mst (store_idx);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_user_mst_store_idx ON user_mst (store_idx);

ALTER TABLE user_mst
    ADD COLUMN IF NOT EXISTS owner_yn CHAR(1) DEFAULT 'N'::bpchar;

COMMENT ON COLUMN user_mst.owner_yn IS '가맹점주 여부 (Y: 가맹점주·게시판만 접근, N: 일반)';

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('mst006', '가맹주관리', 'grp_mst', '/master/owner-users', 'L', 56, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();
