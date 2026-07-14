-- 활동 계획(월간) — 날짜별 가맹점 계획. 시간 단위 activity_plan 은 사용하지 않음.

CREATE TABLE IF NOT EXISTS public.activity_plan_store (
    plan_store_idx    SERIAL PRIMARY KEY,
    assignee_user_idx INTEGER      NOT NULL REFERENCES user_mst(user_idx),
    plan_date         DATE         NOT NULL,
    store_idx         INTEGER      NOT NULL REFERENCES store_mst(store_idx),
    sort_order        INTEGER      NOT NULL DEFAULT 0,
    created_by        VARCHAR(50),
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uq_activity_plan_store_day UNIQUE (assignee_user_idx, plan_date, store_idx)
);

COMMENT ON TABLE public.activity_plan_store IS '활동 계획 — 담당자·날짜별 방문 예정 가맹점';
COMMENT ON COLUMN public.activity_plan_store.plan_date IS '계획 일자(벽시계, 시간 없음)';

CREATE INDEX IF NOT EXISTS ix_activity_plan_store_assignee_date
    ON public.activity_plan_store (assignee_user_idx, plan_date);

CREATE INDEX IF NOT EXISTS ix_activity_plan_store_date
    ON public.activity_plan_store (plan_date);
