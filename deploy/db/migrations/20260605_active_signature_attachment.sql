-- 활동관리 전자서명·첨부파일

ALTER TABLE public.active_mst
    ADD COLUMN IF NOT EXISTS signature_stored_name character varying(255);

COMMENT ON COLUMN public.active_mst.signature_stored_name IS '전자서명 PNG 디스크 저장 파일명(UUID 기반)';

CREATE SEQUENCE IF NOT EXISTS public.active_att_act_att_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE IF NOT EXISTS public.active_att (
    act_att_idx integer NOT NULL DEFAULT nextval('public.active_att_act_att_idx_seq'::regclass),
    act_idx integer NOT NULL,
    file_name character varying(255) NOT NULL,
    stored_name character varying(255) NOT NULL,
    file_size bigint NOT NULL DEFAULT 0,
    content_type character varying(127),
    attached_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by character varying(50),
    deleted_yn boolean NOT NULL DEFAULT false,
    CONSTRAINT active_att_pkey PRIMARY KEY (act_att_idx)
);

ALTER SEQUENCE public.active_att_act_att_idx_seq
    OWNED BY public.active_att.act_att_idx;

CREATE INDEX IF NOT EXISTS idx_active_att_act_idx
    ON public.active_att (act_idx)
    WHERE deleted_yn = false;

COMMENT ON TABLE public.active_att IS '활동관리 첨부파일 메타';
COMMENT ON COLUMN public.active_att.stored_name IS '디스크 저장 파일명(UUID 기반)';
