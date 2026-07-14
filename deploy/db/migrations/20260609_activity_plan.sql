-- 활동 계획(activity_plan) + 팀 캘린더 열람 권한(team_view_permission) + act004 메뉴

CREATE TABLE IF NOT EXISTS public.activity_plan (
    plan_idx            SERIAL PRIMARY KEY,
    assignee_user_idx   INTEGER      NOT NULL REFERENCES user_mst(user_idx),
    title               VARCHAR(200) NOT NULL,
    plan_start_at       TIMESTAMPTZ  NOT NULL,
    plan_end_at         TIMESTAMPTZ  NOT NULL,
    all_day_yn          CHAR(1)      NOT NULL DEFAULT 'N',
    location_txt        VARCHAR(300),
    online_meeting_yn   CHAR(1)      NOT NULL DEFAULT 'N',
    plan_status         VARCHAR(20)  NOT NULL DEFAULT 'PLANNED',
    memo_txt            TEXT,
    created_by          VARCHAR(50),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ck_activity_plan_all_day_yn CHECK (all_day_yn IN ('Y', 'N')),
    CONSTRAINT ck_activity_plan_online_meeting_yn CHECK (online_meeting_yn IN ('Y', 'N')),
    CONSTRAINT ck_activity_plan_status CHECK (plan_status IN ('PLANNED', 'DONE', 'CANCELLED'))
);

COMMENT ON TABLE public.activity_plan IS '활동 계획(캘린더 일정)';
COMMENT ON COLUMN public.activity_plan.assignee_user_idx IS '담당자 user_mst.user_idx — 캘린더 소유자';

CREATE INDEX IF NOT EXISTS ix_activity_plan_assignee_start
    ON public.activity_plan (assignee_user_idx, plan_start_at);
CREATE INDEX IF NOT EXISTS ix_activity_plan_range
    ON public.activity_plan (plan_start_at, plan_end_at);

-- 팀 단위 열람: viewer 가 target_dept_idx 소속 사원들의 계획을 조회할 수 있음
CREATE TABLE IF NOT EXISTS public.team_view_permission (
    viewer_user_idx INTEGER NOT NULL REFERENCES user_mst(user_idx),
    target_dept_idx INTEGER NOT NULL REFERENCES dept_mst(dept_idx),
    can_view        CHAR(1)   NOT NULL DEFAULT 'Y',
    granted_by      VARCHAR(50),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (viewer_user_idx, target_dept_idx),
    CONSTRAINT ck_team_view_permission_can_view CHECK (can_view IN ('Y', 'N'))
);

COMMENT ON TABLE public.team_view_permission IS '팀 캘린더 열람 권한 — viewer 가 target 부서(팀) 소속 사원 계획 조회';

CREATE INDEX IF NOT EXISTS ix_team_view_permission_viewer
    ON public.team_view_permission (viewer_user_idx);

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('act004', '활동 계획', 'grp_act', '/activities/calendar', 'L', 35, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();
