-- 가맹점 NFC 출입 태그 (UID 등록) + usage_log/active_mst 연동

CREATE TABLE IF NOT EXISTS public.store_nfc_tag (
    store_idx       INT          PRIMARY KEY REFERENCES public.store_mst (store_idx),
    tag_uid         VARCHAR(32)  NOT NULL UNIQUE,
    use_yn          CHAR(1)      NOT NULL DEFAULT 'Y',
    registered_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    registered_by   VARCHAR(50)
);

COMMENT ON TABLE public.store_nfc_tag IS '가맹점 출입 NFC 태그 UID (1매장 1태그)';
COMMENT ON COLUMN public.store_nfc_tag.tag_uid IS 'NFC 태그 시리얼(콜론 제거, 대문자 HEX)';

CREATE INDEX IF NOT EXISTS ix_store_nfc_tag_uid ON public.store_nfc_tag (tag_uid);

ALTER TABLE public.usage_log
    ADD COLUMN IF NOT EXISTS store_idx   INT,
    ADD COLUMN IF NOT EXISTS tag_uid     VARCHAR(32),
    ADD COLUMN IF NOT EXISTS tag_lat     NUMERIC(10, 7),
    ADD COLUMN IF NOT EXISTS tag_lng     NUMERIC(10, 7),
    ADD COLUMN IF NOT EXISTS distance_m   INT;

COMMENT ON COLUMN public.usage_log.store_idx IS '출입태그(TAG) 시 가맹점 FK';
COMMENT ON COLUMN public.usage_log.tag_uid IS '출입태그(TAG) 시 NFC UID';
COMMENT ON COLUMN public.usage_log.distance_m IS '출입태그 시 매장 좌표 대비 거리(m)';

CREATE INDEX IF NOT EXISTS ix_usage_log_tag_store
    ON public.usage_log (store_idx, used_at DESC)
    WHERE use_type = 'TAG';

ALTER TABLE public.active_mst
    ADD COLUMN IF NOT EXISTS usage_log_idx INT;

COMMENT ON COLUMN public.active_mst.usage_log_idx IS '활동 상신 시 연결한 출입 태그 usage_log.log_idx';

CREATE INDEX IF NOT EXISTS ix_active_mst_usage_log_idx
    ON public.active_mst (usage_log_idx)
    WHERE usage_log_idx IS NOT NULL;
