-- user_mst 재직 여부 — 퇴사처리(소프트)용
ALTER TABLE user_mst
    ADD COLUMN IF NOT EXISTS work_yn CHAR(1) DEFAULT 'Y'::bpchar;

ALTER TABLE user_mst
    ADD COLUMN IF NOT EXISTS leave_dt DATE;

UPDATE user_mst
SET work_yn = 'Y'
WHERE work_yn IS NULL;

COMMENT ON COLUMN user_mst.work_yn IS '재직 여부 (Y: 재직, N: 퇴사)';
COMMENT ON COLUMN user_mst.leave_dt IS '퇴사일';
