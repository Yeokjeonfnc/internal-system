-- 메신저(msg001) — 메시지 삭제(소프트 삭제)
-- 발신자가 자신의 메시지를 삭제하면 deleted_at 을 남기고 목록에서 제외한다.

ALTER TABLE public.chat_message
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

COMMENT ON COLUMN public.chat_message.deleted_at IS
    '메시지를 삭제한 시각(소프트 삭제). NULL 이 아니면 대화에서 노출하지 않는다.';
