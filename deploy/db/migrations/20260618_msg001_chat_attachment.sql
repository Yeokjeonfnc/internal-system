-- 메신저(msg001) — 메시지 첨부(이미지/파일) 지원
-- chat_message 에 첨부 메타 컬럼 추가. 텍스트 메시지는 모두 NULL.

ALTER TABLE public.chat_message
    ADD COLUMN IF NOT EXISTS file_name    VARCHAR(255),
    ADD COLUMN IF NOT EXISTS stored_name  VARCHAR(255),
    ADD COLUMN IF NOT EXISTS content_type VARCHAR(127),
    ADD COLUMN IF NOT EXISTS file_size    BIGINT;

-- 첨부 메시지는 본문 텍스트가 비어 있을 수 있으므로 NOT NULL 제약을 푼다.
ALTER TABLE public.chat_message
    ALTER COLUMN msg_txt DROP NOT NULL;

COMMENT ON COLUMN public.chat_message.file_name IS '원본 파일명 (첨부 메시지)';
COMMENT ON COLUMN public.chat_message.stored_name IS '디스크 저장 파일명';
COMMENT ON COLUMN public.chat_message.content_type IS 'MIME 타입';
COMMENT ON COLUMN public.chat_message.file_size IS '파일 크기(byte)';
