-- store_history 의 store_mst 참조 제약(fk_his_store_idx) 제거.
--
-- store_history 는 가맹점이 삭제된 뒤에도 "누가 언제 무엇을 바꿨고 결국 삭제했는지"를
-- 남겨야 하는 감사 기록이다. 그런데 store_idx FK 가 걸려 있으면 가맹점 행을 지우는
-- 순간 23503 이 나서 삭제가 아예 불가능하다.
--
-- 그래서 지금까지는 애플리케이션이 가맹점을 지울 때마다
--   ALTER TABLE store_history DROP CONSTRAINT IF EXISTS fk_his_store_idx
-- 를 실행해 우회했다. 사용자 조작 한 번이 운영 스키마를 바꾸는 구조였고,
-- 앱 DB 계정이 테이블 소유자가 아니면 삭제 자체가 항상 실패했다.
-- 이 마이그레이션으로 한 번만 정리하고, 애플리케이션에서는 DDL 을 걷어냈다.
-- (StrService.remove 는 제약이 아직 남아 있으면 삭제를 진행하지 않고
--  "관리자에게 문의" 메시지를 돌려준다 — 조용히 실패하지 않게.)
--
-- 이미 떨어져 나간 DB 에서도 안전하게 재실행할 수 있다(IF EXISTS).
BEGIN;

ALTER TABLE store_history
    DROP CONSTRAINT IF EXISTS fk_his_store_idx;

COMMENT ON TABLE store_history IS
    '가맹점 변경 이력(감사 기록) — 삭제된 가맹점의 이력도 남기므로 store_mst FK 를 두지 않는다';

COMMIT;
