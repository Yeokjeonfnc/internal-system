-- 가맹점 문서(첨부파일) 메타 — 실제 바이너리는 서버 디스크(storage)에 저장.

CREATE SEQUENCE IF NOT EXISTS public.store_doc_store_doc_idx_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE IF NOT EXISTS public.store_doc (
    store_doc_idx integer NOT NULL DEFAULT nextval('public.store_doc_store_doc_idx_seq'::regclass),
    store_idx integer NOT NULL,
    file_name character varying(255) NOT NULL,
    stored_name character varying(255) NOT NULL,
    file_size bigint NOT NULL DEFAULT 0,
    content_type character varying(127),
    attachment_base_date date,
    attached_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by character varying(50),
    deleted_yn boolean NOT NULL DEFAULT false,
    CONSTRAINT store_doc_pkey PRIMARY KEY (store_doc_idx)
);

ALTER SEQUENCE public.store_doc_store_doc_idx_seq
    OWNED BY public.store_doc.store_doc_idx;

CREATE INDEX IF NOT EXISTS idx_store_doc_store_idx
    ON public.store_doc (store_idx)
    WHERE deleted_yn = false;

COMMENT ON TABLE public.store_doc IS '가맹점 첨부 문서 메타';
COMMENT ON COLUMN public.store_doc.stored_name IS '디스크 저장 파일명(UUID 기반)';
COMMENT ON COLUMN public.store_doc.attachment_base_date IS '첨부 기준일';
