-- 메신저(msg001) — 채팅방·멤버·메시지

CREATE TABLE IF NOT EXISTS public.chat_room (
    room_idx   SERIAL PRIMARY KEY,
    title      VARCHAR(200),
    is_group   BOOLEAN     NOT NULL DEFAULT false,
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.chat_room IS '채팅방 (1:1 / 그룹)';
COMMENT ON COLUMN public.chat_room.is_group IS '그룹방 여부';

CREATE TABLE IF NOT EXISTS public.chat_room_member (
    room_idx     INTEGER     NOT NULL REFERENCES public.chat_room (room_idx) ON DELETE CASCADE,
    user_id      VARCHAR(50) NOT NULL,
    joined_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_read_at TIMESTAMPTZ,
    CONSTRAINT pk_chat_room_member PRIMARY KEY (room_idx, user_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_room_member_user
    ON public.chat_room_member (user_id);

COMMENT ON TABLE public.chat_room_member IS '채팅방 참여자';
COMMENT ON COLUMN public.chat_room_member.last_read_at IS '마지막으로 읽은 시각 (안읽음 수 계산 기준)';

CREATE TABLE IF NOT EXISTS public.chat_message (
    message_idx BIGSERIAL   PRIMARY KEY,
    room_idx    INTEGER     NOT NULL REFERENCES public.chat_room (room_idx) ON DELETE CASCADE,
    sender_id   VARCHAR(50) NOT NULL,
    msg_txt     TEXT        NOT NULL,
    msg_type    VARCHAR(20) NOT NULL DEFAULT 'text',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_message_room_created
    ON public.chat_message (room_idx, created_at);

COMMENT ON TABLE public.chat_message IS '채팅 메시지';

-- 사이드바 메뉴 등록 (전 직원 노출 — 게시판 다음 순서)
INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('msg001', '메신저', NULL, '/chat', 'L', 16, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm = EXCLUDED.menu_nm,
    route_path = EXCLUDED.route_path,
    menu_type = EXCLUDED.menu_type,
    sort_order = EXCLUDED.sort_order,
    use_yn = EXCLUDED.use_yn,
    updated_at = now();
