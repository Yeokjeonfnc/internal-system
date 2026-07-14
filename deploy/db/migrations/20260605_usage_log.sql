-- 사용기록(로그인·메뉴 사용) 저장 및 조회용 테이블

CREATE TABLE IF NOT EXISTS public.usage_log (
    log_idx     SERIAL PRIMARY KEY,
    user_id     VARCHAR(50)  NOT NULL,
    user_nm     VARCHAR(100) NOT NULL,
    dept_nm     VARCHAR(100),
    position_nm VARCHAR(100),
    tag_yn      CHAR(1)      DEFAULT 'N',
    use_type    VARCHAR(20)  NOT NULL,
    use_detail  TEXT         NOT NULL,
    menu_cd     VARCHAR(20),
    used_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.usage_log IS 'ERP 사용기록(로그인·메뉴 사용)';
COMMENT ON COLUMN public.usage_log.use_type IS 'LOGIN | MENU';
COMMENT ON COLUMN public.usage_log.tag_yn IS '기록 시점 사용자 tag_yn 스냅샷(공용사용자 탭 필터)';

CREATE INDEX IF NOT EXISTS ix_usage_log_used_at ON public.usage_log (used_at DESC);
CREATE INDEX IF NOT EXISTS ix_usage_log_user_id ON public.usage_log (user_id);
CREATE INDEX IF NOT EXISTS ix_usage_log_use_type ON public.usage_log (use_type);

-- 마스터관리 하위 메뉴
INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('mst005', '사용기록 조회', 'grp_mst', '/master/usage-logs', 'L', 55, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();
