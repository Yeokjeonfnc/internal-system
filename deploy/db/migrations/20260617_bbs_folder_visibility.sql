-- 게시판 폴더 — 가맹점주/사원 조회 권한

ALTER TABLE public.bbs_folder
    ADD COLUMN IF NOT EXISTS owner_view_yn CHAR(1) NOT NULL DEFAULT 'Y',
    ADD COLUMN IF NOT EXISTS staff_view_yn CHAR(1) NOT NULL DEFAULT 'Y';

ALTER TABLE public.bbs_folder
    DROP CONSTRAINT IF EXISTS ck_bbs_folder_owner_view_yn;
ALTER TABLE public.bbs_folder
    ADD CONSTRAINT ck_bbs_folder_owner_view_yn CHECK (owner_view_yn IN ('Y', 'N'));

ALTER TABLE public.bbs_folder
    DROP CONSTRAINT IF EXISTS ck_bbs_folder_staff_view_yn;
ALTER TABLE public.bbs_folder
    ADD CONSTRAINT ck_bbs_folder_staff_view_yn CHECK (staff_view_yn IN ('Y', 'N'));

COMMENT ON COLUMN public.bbs_folder.owner_view_yn IS '가맹점주 조회 가능 여부';
COMMENT ON COLUMN public.bbs_folder.staff_view_yn IS '사원(내부) 조회 가능 여부';

UPDATE public.bbs_folder
SET owner_view_yn = 'Y',
    staff_view_yn = 'Y'
WHERE folder_nm = '공지사항';

UPDATE public.bbs_folder
SET owner_view_yn = 'N',
    staff_view_yn = 'Y'
WHERE folder_nm = '일반';

UPDATE public.bbs_folder
SET owner_view_yn = 'Y',
    staff_view_yn = 'N'
WHERE folder_nm = '가맹점주';
