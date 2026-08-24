-- 메일(mal001) — send_status 에 'SCHEDULED' 허용
--
-- 배경
--   20260824_mal001_menu_tree_and_features.sql 에서 예약발송을 넣으면서
--   scheduled_at 컬럼과 send_status='SCHEDULED' 부분 인덱스까지는 만들었는데,
--   정작 send_status 의 CHECK 제약을 넓히는 걸 빠뜨렸다.
--
--   그래서 예약발송이 **100% 실패한다**:
--     ERROR: new row for relation "mail_mst" violates check constraint "ck_mail_mst_send_status"
--
--   인덱스가 참조하는 값을 제약이 거부하고 있었으니, 애초에 서로 모순된 상태였다.
--   컬럼·인덱스만 보고 "예약 준비 완료"로 판단한 것이 실수였다.
--
-- 실행
--   psql -h localhost -p 5433 -U postgres -d yeokjeon_on -f 20260824_mal001_scheduled_status_fix.sql

BEGIN;

ALTER TABLE public.mail_mst DROP CONSTRAINT IF EXISTS ck_mail_mst_send_status;

-- SCHEDULED = Resend 에 예약 접수까지 끝난 상태.
-- 접수 전(우리가 큐에 넣기만 한 단계)은 QUEUED 로 두고, Resend 가 email id 를
-- 돌려준 뒤에야 SCHEDULED 로 올린다. 그래야 "예약됐다고 표시됐는데 실제로는
-- 안 나가는 메일"이 생기지 않는다.
ALTER TABLE public.mail_mst ADD CONSTRAINT ck_mail_mst_send_status
    CHECK (send_status IS NULL
           OR send_status IN ('DRAFT', 'QUEUED', 'SCHEDULED', 'SENT', 'FAILED'));

COMMIT;

-- 되돌리려면:
--   ALTER TABLE public.mail_mst DROP CONSTRAINT IF EXISTS ck_mail_mst_send_status;
--   ALTER TABLE public.mail_mst ADD CONSTRAINT ck_mail_mst_send_status
--       CHECK (send_status IS NULL OR send_status IN ('DRAFT','QUEUED','SENT','FAILED'));
--   (단, 이미 SCHEDULED 인 행이 있으면 실패한다)
