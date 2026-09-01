-- 게시판 댓글

CREATE TABLE IF NOT EXISTS public.bbs_comment (
    comment_idx  SERIAL PRIMARY KEY,
    post_idx     INTEGER      NOT NULL REFERENCES public.bbs_post (post_idx),
    body_txt     TEXT         NOT NULL,
    created_by   VARCHAR(50)  NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    deleted_yn   BOOLEAN      NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_bbs_comment_post_created
    ON public.bbs_comment (post_idx, created_at)
    WHERE deleted_yn = false;

COMMENT ON TABLE public.bbs_comment IS '게시판 댓글';
COMMENT ON COLUMN public.bbs_comment.body_txt IS '댓글 본문';
