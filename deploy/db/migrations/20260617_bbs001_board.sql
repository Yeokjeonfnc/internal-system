-- 게시판(bbs001) — 폴더·게시글·첨부

CREATE TABLE IF NOT EXISTS public.bbs_folder (
    folder_idx     SERIAL PRIMARY KEY,
    folder_nm      VARCHAR(100) NOT NULL,
    sort_order     INTEGER      NOT NULL DEFAULT 0,
    use_yn         CHAR(1)      NOT NULL DEFAULT 'Y',
    owner_view_yn  CHAR(1)      NOT NULL DEFAULT 'Y',
    staff_view_yn  CHAR(1)      NOT NULL DEFAULT 'Y',
    created_by     VARCHAR(50),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ck_bbs_folder_use_yn CHECK (use_yn IN ('Y', 'N')),
    CONSTRAINT ck_bbs_folder_owner_view_yn CHECK (owner_view_yn IN ('Y', 'N')),
    CONSTRAINT ck_bbs_folder_staff_view_yn CHECK (staff_view_yn IN ('Y', 'N'))
);

COMMENT ON TABLE public.bbs_folder IS '게시판 폴더';
COMMENT ON COLUMN public.bbs_folder.folder_nm IS '폴더명';

CREATE TABLE IF NOT EXISTS public.bbs_post (
    post_idx     SERIAL PRIMARY KEY,
    folder_idx   INTEGER      NOT NULL REFERENCES public.bbs_folder (folder_idx),
    store_idx    INTEGER REFERENCES public.store_mst (store_idx),
    title        VARCHAR(200) NOT NULL,
    body_txt     TEXT,
    private_yn   CHAR(1)      NOT NULL DEFAULT 'N',
    notice_yn    CHAR(1)      NOT NULL DEFAULT 'N',
    view_cnt     INTEGER      NOT NULL DEFAULT 0,
    created_by   VARCHAR(50),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    deleted_yn   BOOLEAN      NOT NULL DEFAULT false,
    CONSTRAINT ck_bbs_post_private_yn CHECK (private_yn IN ('Y', 'N')),
    CONSTRAINT ck_bbs_post_notice_yn CHECK (notice_yn IN ('Y', 'N'))
);

CREATE INDEX IF NOT EXISTS idx_bbs_post_folder_created
    ON public.bbs_post (folder_idx, created_at DESC)
    WHERE deleted_yn = false;

COMMENT ON TABLE public.bbs_post IS '게시판 글';

CREATE SEQUENCE IF NOT EXISTS public.bbs_doc_bbs_doc_idx_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

CREATE TABLE IF NOT EXISTS public.bbs_doc (
    bbs_doc_idx  INTEGER      NOT NULL DEFAULT nextval('public.bbs_doc_bbs_doc_idx_seq'::regclass),
    post_idx     INTEGER      NOT NULL REFERENCES public.bbs_post (post_idx),
    file_name    VARCHAR(255) NOT NULL,
    stored_name  VARCHAR(255) NOT NULL,
    file_size    BIGINT       NOT NULL DEFAULT 0,
    content_type VARCHAR(127),
    attached_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    modified_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    modified_by  VARCHAR(50),
    deleted_yn   BOOLEAN      NOT NULL DEFAULT false,
    CONSTRAINT bbs_doc_pkey PRIMARY KEY (bbs_doc_idx)
);

ALTER SEQUENCE public.bbs_doc_bbs_doc_idx_seq OWNED BY public.bbs_doc.bbs_doc_idx;

CREATE INDEX IF NOT EXISTS idx_bbs_doc_post_idx
    ON public.bbs_doc (post_idx)
    WHERE deleted_yn = false;

COMMENT ON TABLE public.bbs_doc IS '게시판 첨부파일 메타';

INSERT INTO public.bbs_folder (folder_nm, sort_order, use_yn, owner_view_yn, staff_view_yn, created_by)
SELECT v.folder_nm, v.sort_order, v.use_yn, v.owner_view_yn, v.staff_view_yn, v.created_by
FROM (VALUES ('공지사항', 10, 'Y', 'Y', 'Y', 'system'),
             ('일반', 20, 'Y', 'N', 'Y', 'system'),
             ('가맹점주', 30, 'Y', 'Y', 'N', 'system')) AS v(folder_nm, sort_order, use_yn, owner_view_yn, staff_view_yn, created_by)
WHERE NOT EXISTS (SELECT 1 FROM public.bbs_folder f WHERE f.folder_nm = v.folder_nm);

INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('bbs001', '게시판', NULL, '/board', 'L', 15, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();
