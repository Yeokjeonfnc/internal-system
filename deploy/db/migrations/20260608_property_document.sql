-- 물건 첨부파일(사진·문서) 메타 — 바이너리는 서버 디스크(storage/properties/{propIdx}/)에 저장.

CREATE SEQUENCE IF NOT EXISTS public.property_doc_property_doc_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE IF NOT EXISTS public.property_doc (
    property_doc_idx integer NOT NULL DEFAULT nextval('public.property_doc_property_doc_idx_seq'::regclass),
    prop_idx integer NOT NULL,
    file_name character varying(255) NOT NULL,
    stored_name character varying(255) NOT NULL,
    file_size bigint NOT NULL DEFAULT 0,
    content_type character varying(127),
    attachment_base_date date,
    attached_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by character varying(50),
    deleted_yn boolean NOT NULL DEFAULT false,
    CONSTRAINT property_doc_pkey PRIMARY KEY (property_doc_idx)
);

ALTER SEQUENCE public.property_doc_property_doc_idx_seq
    OWNED BY public.property_doc.property_doc_idx;

CREATE INDEX IF NOT EXISTS idx_property_doc_prop_idx
    ON public.property_doc (prop_idx)
    WHERE deleted_yn = false;

COMMENT ON TABLE public.property_doc IS '물건 첨부 문서(사진) 메타';
COMMENT ON COLUMN public.property_doc.stored_name IS '디스크 저장 파일명(UUID 기반)';
