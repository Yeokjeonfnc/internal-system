-- 메신저(msg001) — 대화방 숨김(소프트 삭제) 지원
-- 사용자가 대화방을 "삭제"하면 hidden_at 을 기록해 본인 목록에서만 숨긴다.
-- 이후 새 메시지가 오면(created_at > hidden_at) 목록에 다시 나타난다(복구 가능).

ALTER TABLE public.chat_room_member
    ADD COLUMN IF NOT EXISTS hidden_at TIMESTAMPTZ;

COMMENT ON COLUMN public.chat_room_member.hidden_at IS
    '대화방을 목록에서 숨긴 시각(소프트 삭제). 이후 새 메시지가 오면 다시 노출.';
