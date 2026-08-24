-- 메일(mal001) — Resend 송수신 이력. 메타·본문·참여자·첨부·상태이벤트·웹훅원장.
--
-- 배경
--   ERP 가 Resend 로 메일을 직접 주고받고 그 이력을 ERP DB 에 남긴다.
--   Resend 수신 웹훅에는 본문·헤더·첨부 실체가 오지 않고 메타데이터만 온다
--   (Resend 공식 문서 명시). 본문은 Received Emails API, 첨부는 Attachments API 를
--   따로 호출해 채워야 한다. 그래서 "메타 먼저 저장하고 본문·첨부는 나중에 채우는"
--   2 단계 흐름을 스키마가 표현할 수 있어야 한다 → mail_mst.body_status,
--   mail_att.fetched_at 이 그 상태값이다.
--
--   또 Resend 웹훅은 at-least-once 라서 같은 이벤트가 여러 번 온다. 중복 저장을
--   막는 축이 두 개다.
--     1) mail_webhook_log.svix_id  PRIMARY KEY  — 웹훅 원장 단계에서 차단
--     2) mail_mst.resend_email_id  UNIQUE       — 메일 본체 단계에서 차단
--   두 겹인 이유: 재동기화 배치(Resend 30 일 보관 창을 훑는 일 1 회 잡)와 웹훅이
--   같은 메일을 동시에 집어넣을 수 있는데, 이건 svix_id 로는 못 막는다.
--
-- 안전성
--   전부 CREATE ... IF NOT EXISTS / ON CONFLICT 라서 이미 만들어져 있는 서버에서
--   다시 돌려도 아무 것도 지우거나 덮어쓰지 않는다. 기존 31 개 테이블은 건드리지
--   않는다. erp_approval_mappings 참조는 ON DELETE SET NULL 이라 결재 문서를 지워도
--   메일 이력은 남는다.
--
-- 사전 조건
--   CREATE EXTENSION pg_trgm 은 슈퍼유저 권한이 필요하다(postgres 계정으로 실행할 것).
--   pg_trgm 1.6 은 이 서버에서 사용 가능함을 확인했다(pg_available_extensions).
--
-- 실행
--   psql -h localhost -p 5433 -U postgres -d yeokjeon_on -f 20260824_mal001_mail_history.sql
--   (개발계 먼저 시험할 것:  -d yeokjeon_on_dev )
--   (한글 주석이 깨져 트랜잭션이 죽으면 먼저:  $env:PGCLIENTENCODING="UTF8" )

BEGIN;

-- 제목·본문 부분일치 검색용. 한국어는 형태소 사전이 없어 tsvector 를 못 쓴다
-- (이 서버 pg_ts_config 29 개에 한국어 없음). trigram 부분일치가 현실적인 선택.
CREATE EXTENSION IF NOT EXISTS pg_trgm;


-- 1) 스레드 ---------------------------------------------------------------------
--    메일을 대화 단위로 묶는 상위 그룹. 트리가 아니라 평면 그룹이다.
CREATE TABLE IF NOT EXISTS public.mail_thread_mst (
    thread_idx    BIGSERIAL    PRIMARY KEY,
    subject_norm  VARCHAR(500) NOT NULL DEFAULT '',
    first_mail_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    last_mail_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    mail_cnt      INTEGER      NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 스레드 목록 화면(최근 대화순)
CREATE INDEX IF NOT EXISTS idx_mail_thread_mst_last
    ON public.mail_thread_mst (last_mail_at DESC);
-- 제목 기반 스레드 폴백 매칭(References 가 아예 없는 메일 구제)
CREATE INDEX IF NOT EXISTS idx_mail_thread_mst_subj
    ON public.mail_thread_mst (subject_norm, last_mail_at DESC);

COMMENT ON TABLE  public.mail_thread_mst              IS '메일 스레드(대화 묶음)';
COMMENT ON COLUMN public.mail_thread_mst.subject_norm IS 'Re:/Fwd:/답장: 제거·공백압축·소문자화한 제목. 제목 폴백 매칭 기준';
COMMENT ON COLUMN public.mail_thread_mst.mail_cnt     IS '스레드에 속한 삭제되지 않은 메일 수(캐시)';


-- 2) 메일 본체(메타) ------------------------------------------------------------
--    목록 화면은 이 테이블만 읽는다. 본문은 mail_body 로 분리했다.
CREATE TABLE IF NOT EXISTS public.mail_mst (
    mail_idx        BIGSERIAL    PRIMARY KEY,
    thread_idx      BIGINT       NOT NULL REFERENCES public.mail_thread_mst (thread_idx),
    direction       VARCHAR(10)  NOT NULL,
    resend_email_id VARCHAR(100),
    rfc_message_id  VARCHAR(512),
    in_reply_to     VARCHAR(512),
    refs_txt        TEXT,
    subject         VARCHAR(500),
    subject_norm    VARCHAR(500),
    from_email      VARCHAR(320) NOT NULL,
    from_nm         VARCHAR(255),
    to_summary      VARCHAR(500),
    snippet         VARCHAR(500),
    att_cnt         SMALLINT     NOT NULL DEFAULT 0,
    body_status     VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    body_try_cnt    SMALLINT     NOT NULL DEFAULT 0,
    body_tried_at   TIMESTAMPTZ,
    body_err        VARCHAR(500),
    send_status     VARCHAR(20),
    send_try_cnt    SMALLINT     NOT NULL DEFAULT 0,
    send_tried_at   TIMESTAMPTZ,
    send_err        VARCHAR(500),
    last_status     VARCHAR(20),
    last_status_at  TIMESTAMPTZ,
    read_yn         CHAR(1)      NOT NULL DEFAULT 'N',
    spam_yn         CHAR(1)      NOT NULL DEFAULT 'N',
    user_id         VARCHAR(50),
    partner_idx     INTEGER,
    mapping_id      BIGINT       REFERENCES public.erp_approval_mappings (id) ON DELETE SET NULL,
    mail_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    deleted_yn      BOOLEAN      NOT NULL DEFAULT false,
    CONSTRAINT uq_mail_mst_resend_email_id UNIQUE (resend_email_id),
    CONSTRAINT ck_mail_mst_direction   CHECK (direction IN ('IN', 'OUT')),
    CONSTRAINT ck_mail_mst_body_status CHECK (body_status IN ('PENDING', 'DONE', 'FAILED')),
    CONSTRAINT ck_mail_mst_send_status CHECK (send_status IS NULL
                                              OR send_status IN ('DRAFT', 'QUEUED', 'SENT', 'FAILED')),
    CONSTRAINT ck_mail_mst_read_yn     CHECK (read_yn IN ('Y', 'N')),
    CONSTRAINT ck_mail_mst_spam_yn     CHECK (spam_yn IN ('Y', 'N'))
);

-- 스레드 상세(대화 펼치기)
CREATE INDEX IF NOT EXISTS idx_mail_mst_thread
    ON public.mail_mst (thread_idx, mail_at);
-- 전체 메일 목록(최신순)
CREATE INDEX IF NOT EXISTS idx_mail_mst_mail_at
    ON public.mail_mst (mail_at DESC)
    WHERE deleted_yn = false;
-- 내 메일함 / 담당자별 목록, 안 읽음 카운트
CREATE INDEX IF NOT EXISTS idx_mail_mst_user
    ON public.mail_mst (user_id, mail_at DESC)
    WHERE deleted_yn = false;
-- 스레드 연결 정방향: 새 메일의 References/In-Reply-To 로 기존 메일 찾기
CREATE INDEX IF NOT EXISTS idx_mail_mst_rfc_message_id
    ON public.mail_mst (rfc_message_id);
-- 스레드 연결 역방향: 나를 부모로 가리키는 기존 메일 찾기(도착 순서 역전 대비)
CREATE INDEX IF NOT EXISTS idx_mail_mst_in_reply_to
    ON public.mail_mst (in_reply_to);
-- 본문 수집 잡 폴링(처리 중인 소수 행만 인덱스에 남는다)
CREATE INDEX IF NOT EXISTS idx_mail_mst_body_pending
    ON public.mail_mst (body_tried_at NULLS FIRST, mail_idx)
    WHERE body_status = 'PENDING';
-- 발송 잡 폴링
CREATE INDEX IF NOT EXISTS idx_mail_mst_send_queue
    ON public.mail_mst (send_tried_at NULLS FIRST, mail_idx)
    WHERE send_status = 'QUEUED';
-- 거래처별 메일 이력("이 거래처와 주고받은 메일 전부")
CREATE INDEX IF NOT EXISTS idx_mail_mst_partner
    ON public.mail_mst (partner_idx, mail_at DESC)
    WHERE partner_idx IS NOT NULL AND deleted_yn = false;
-- 전자결재 문서에 붙은 메일
CREATE INDEX IF NOT EXISTS idx_mail_mst_mapping
    ON public.mail_mst (mapping_id)
    WHERE mapping_id IS NOT NULL;
-- 제목 부분일치 검색(한국어 포함)
CREATE INDEX IF NOT EXISTS idx_mail_mst_subject_trgm
    ON public.mail_mst USING gin (subject gin_trgm_ops);

COMMENT ON TABLE  public.mail_mst                 IS '메일 송수신 이력(메타). 목록 조회는 이 테이블만 읽는다';
COMMENT ON COLUMN public.mail_mst.direction       IS 'IN=수신 / OUT=발신';
COMMENT ON COLUMN public.mail_mst.resend_email_id IS 'Resend 내부 email id(UUID). 웹훅 중복 저장을 막는 UNIQUE 키. 발신은 API 응답 전까지 NULL';
COMMENT ON COLUMN public.mail_mst.rfc_message_id  IS 'RFC5322 Message-ID(꺾쇠 제거 후 저장). 실무에서 중복이 생기므로 UNIQUE 를 걸지 않는다';
COMMENT ON COLUMN public.mail_mst.in_reply_to     IS 'In-Reply-To 헤더의 첫 번째 Message-ID(꺾쇠 제거). 뒤쪽 값은 메일 주소일 수 있어 버린다';
COMMENT ON COLUMN public.mail_mst.refs_txt        IS 'References 헤더 원본(공백 구분). 감사·재스레딩용 보존값이라 인덱스를 걸지 않는다';
COMMENT ON COLUMN public.mail_mst.subject_norm    IS 'Re:/Fwd: 제거·정규화 제목. 스레드 제목 폴백 매칭용';
COMMENT ON COLUMN public.mail_mst.from_email      IS '발신 주소. 목록에 매 행 필요해 의도적으로 비정규화(mail_addr_dtl 에도 FROM 행이 있다)';
COMMENT ON COLUMN public.mail_mst.to_summary      IS '목록 표시용 수신자 요약(예: hong@x.com 외 2명). 참여자는 변하지 않으므로 동기화 부담이 없다';
COMMENT ON COLUMN public.mail_mst.snippet         IS '본문 앞 200~300자 평문. 목록 미리보기용';
COMMENT ON COLUMN public.mail_mst.body_status     IS '본문 수집 상태 PENDING/DONE/FAILED. 웹훅은 메타만 주므로 수신 직후는 PENDING';
COMMENT ON COLUMN public.mail_mst.body_tried_at   IS '본문 수집 마지막 시도 시각(성공 시 완료 시각). 백오프 계산 기준';
COMMENT ON COLUMN public.mail_mst.send_status     IS '발신 전용 DRAFT/QUEUED/SENT/FAILED. 수신 메일은 NULL';
COMMENT ON COLUMN public.mail_mst.last_status     IS 'mail_event_log 에서 파생한 최신 배달 상태 캐시(서열 규칙으로만 갱신)';
COMMENT ON COLUMN public.mail_mst.read_yn         IS 'ERP 화면에서 읽었는지. 발신 메일은 Y 로 생성';
COMMENT ON COLUMN public.mail_mst.spam_yn         IS '스팸 표시. Resend 는 수신 스팸 필터를 제공하지 않으므로 ERP 가 판단한다';
COMMENT ON COLUMN public.mail_mst.user_id         IS '담당 ERP 사용자(user_mst.user_id). 발신은 보낸 사람, 수신은 배정 담당자(초기 NULL)';
COMMENT ON COLUMN public.mail_mst.partner_idx     IS '연관 거래처(partner_mst.partner_idx). 이력 보존을 위해 FK 를 걸지 않는다';
COMMENT ON COLUMN public.mail_mst.mapping_id      IS '연관 전자결재 문서(erp_approval_mappings.id)';
COMMENT ON COLUMN public.mail_mst.mail_at         IS '정렬 기준 시각. 수신은 수신시각, 발신은 발송시각';


-- 3) 본문(1:1 분리) -------------------------------------------------------------
--    2KB 안팎의 중형 텍스트를 mail_mst 에 두면 목록 조회까지 같이 느려진다.
--    본문을 읽지 않는 질의(전체의 대부분)가 이 테이블을 아예 건드리지 않게 분리했다.
CREATE TABLE IF NOT EXISTS public.mail_body (
    mail_idx     BIGINT      PRIMARY KEY REFERENCES public.mail_mst (mail_idx) ON DELETE CASCADE,
    body_text    TEXT,
    body_html    TEXT,
    headers_raw  JSONB,
    search_txt   TEXT,
    truncated_yn BOOLEAN     NOT NULL DEFAULT false,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 본문 포함 검색. 한국어 2글자 질의는 trigram 추출이 안 돼 인덱스가 무력해지므로
-- 화면에서 3자 이상을 유도하거나 기간 필터를 함께 강제할 것.
CREATE INDEX IF NOT EXISTS idx_mail_body_search_trgm
    ON public.mail_body USING gin (search_txt gin_trgm_ops);

COMMENT ON TABLE  public.mail_body              IS '메일 본문(1:1). 수신 메일은 웹훅 이후 별도 API 호출로 채운다';
COMMENT ON COLUMN public.mail_body.body_text    IS '평문 본문. html 만 온 경우 수집 시점에 1회 변환해 저장한다';
COMMENT ON COLUMN public.mail_body.headers_raw  IS 'Received Emails API 가 준 헤더 맵 원본(소문자 키). 재수집이 불가능하므로 보존';
COMMENT ON COLUMN public.mail_body.search_txt   IS '제목+참여자+평문본문을 이어붙인 검색 전용 컬럼(최대 100KB 절단)';
COMMENT ON COLUMN public.mail_body.truncated_yn IS '본문이 상한을 넘어 잘렸는지';


-- 4) 참여자 ---------------------------------------------------------------------
--    "이 주소와 주고받은 메일 전부" 가 ERP 메일 기능의 존재 이유라
--    JSONB 가 아니라 정규화 테이블로 둔다(주소 컬럼에 인덱스가 걸린다).
CREATE TABLE IF NOT EXISTS public.mail_addr_dtl (
    mail_idx  BIGINT       NOT NULL REFERENCES public.mail_mst (mail_idx) ON DELETE CASCADE,
    addr_type VARCHAR(10)  NOT NULL,
    seq       SMALLINT     NOT NULL,
    email     VARCHAR(320) NOT NULL,
    disp_nm   VARCHAR(255),
    CONSTRAINT pk_mail_addr_dtl PRIMARY KEY (mail_idx, addr_type, seq),
    CONSTRAINT ck_mail_addr_dtl_type CHECK (addr_type IN ('FROM', 'TO', 'CC', 'BCC', 'REPLY_TO'))
);

-- 주소로 메일 찾기(거래처 담당자 메일 이력, 스레드 참여자 교집합 판정)
CREATE INDEX IF NOT EXISTS idx_mail_addr_dtl_email
    ON public.mail_addr_dtl (email, mail_idx);

COMMENT ON TABLE  public.mail_addr_dtl           IS '메일 참여자(발신/수신/참조/숨은참조/회신처)';
COMMENT ON COLUMN public.mail_addr_dtl.addr_type IS 'FROM/TO/CC/BCC/REPLY_TO. BCC 는 발신 메일에만 존재하며 화면 노출을 제한해야 한다';
COMMENT ON COLUMN public.mail_addr_dtl.email     IS '소문자로 정규화해 저장한다';
COMMENT ON COLUMN public.mail_addr_dtl.seq       IS '헤더 내 순서(0부터)';


-- 5) 첨부 메타 ------------------------------------------------------------------
--    바이너리는 DB 에 넣지 않는다. 기존 store_doc / bbs_doc / active_att 와 동일하게
--    디스크(FILE_STORAGE_ROOT) 에 두고 여기에는 메타만 남긴다.
--    경로 규칙: <storageRoot>/mails/<mail_idx>/<stored_name>
CREATE TABLE IF NOT EXISTS public.mail_att (
    mail_att_idx   BIGSERIAL    PRIMARY KEY,
    mail_idx       BIGINT       NOT NULL REFERENCES public.mail_mst (mail_idx) ON DELETE CASCADE,
    resend_att_id  VARCHAR(100),
    file_name      VARCHAR(255) NOT NULL,
    stored_name    VARCHAR(255),
    file_size      BIGINT       NOT NULL DEFAULT 0,
    content_type   VARCHAR(127),
    content_id     VARCHAR(255),
    inline_yn      CHAR(1)      NOT NULL DEFAULT 'N',
    fetched_at     TIMESTAMPTZ,
    fetch_try_cnt  SMALLINT     NOT NULL DEFAULT 0,
    fetch_tried_at TIMESTAMPTZ,
    fetch_err      VARCHAR(500),
    attached_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    modified_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    modified_by    VARCHAR(50),
    deleted_yn     BOOLEAN      NOT NULL DEFAULT false,
    -- 같은 첨부를 두 번 만들지 않는다(웹훅 재전달 / 재동기화 배치 동시 진입 대비).
    -- 부분 UNIQUE 인덱스가 아니라 일반 제약이어야 INSERT ... ON CONFLICT
    -- (mail_idx, resend_att_id) DO NOTHING 이 그대로 먹는다.
    -- 발신 메일 첨부는 resend_att_id 가 NULL 이고, NULL 은 서로 중복으로 보지 않는다.
    CONSTRAINT uq_mail_att_resend    UNIQUE (mail_idx, resend_att_id),
    CONSTRAINT ck_mail_att_inline_yn CHECK (inline_yn IN ('Y', 'N'))
);

-- 메일 상세의 첨부 목록
CREATE INDEX IF NOT EXISTS idx_mail_att_mail_idx
    ON public.mail_att (mail_idx)
    WHERE deleted_yn = false;
-- 첨부 실물 수집 잡 폴링(아직 안 받은 것만)
CREATE INDEX IF NOT EXISTS idx_mail_att_pending
    ON public.mail_att (fetch_tried_at NULLS FIRST, mail_att_idx)
    WHERE fetched_at IS NULL AND deleted_yn = false;

COMMENT ON TABLE  public.mail_att               IS '메일 첨부파일 메타. 실체는 디스크 storage/mails/<mail_idx>/';
COMMENT ON COLUMN public.mail_att.resend_att_id IS 'Resend attachment id. 실물 다운로드 URL 은 1시간 만료라 DB 에 저장하지 않는다';
COMMENT ON COLUMN public.mail_att.file_name     IS '원본 파일명(외부 발신자가 보낸 이름. 한글·공백 포함 가능)';
COMMENT ON COLUMN public.mail_att.stored_name   IS '디스크 저장 파일명(UUID_원본명). 실물 미수신 상태에서는 NULL';
COMMENT ON COLUMN public.mail_att.content_id    IS '본문 인라인 이미지의 cid 값';
COMMENT ON COLUMN public.mail_att.fetched_at    IS '실물 다운로드 완료 시각. NULL 이면 메타만 있고 파일이 아직 없다';


-- 6) 배달 상태 이벤트(append-only) ----------------------------------------------
--    delivered 보다 opened 가 먼저 도착하고, 수신자마다 결과가 갈리고,
--    opened/clicked 는 반복 발생한다. 단일 상태 컬럼으로는 표현이 불가능하다.
CREATE TABLE IF NOT EXISTS public.mail_event_log (
    event_idx       BIGSERIAL   PRIMARY KEY,
    mail_idx        BIGINT      REFERENCES public.mail_mst (mail_idx) ON DELETE CASCADE,
    resend_email_id VARCHAR(100),
    event_type      VARCHAR(40) NOT NULL,
    recipient       VARCHAR(320),
    occurred_at     TIMESTAMPTZ NOT NULL,
    detail          JSONB,
    svix_id         VARCHAR(100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- 같은 웹훅이 두 번 와도 이벤트 행이 두 번 생기지 않게. 부분 인덱스가 아닌
    -- 일반 제약이라 ON CONFLICT (svix_id) DO NOTHING 이 그대로 먹는다.
    -- 재동기화 배치가 만든 이벤트는 svix_id 가 NULL 이고 NULL 끼리는 충돌하지 않는다.
    CONSTRAINT uq_mail_event_log_svix UNIQUE (svix_id)
);

-- 메일 상세의 배달 이력 타임라인
CREATE INDEX IF NOT EXISTS idx_mail_event_log_mail
    ON public.mail_event_log (mail_idx, occurred_at DESC);
-- 메일 행보다 이벤트가 먼저 도착한 고아 이벤트 재연결 배치
CREATE INDEX IF NOT EXISTS idx_mail_event_log_orphan
    ON public.mail_event_log (resend_email_id)
    WHERE mail_idx IS NULL;

COMMENT ON TABLE  public.mail_event_log             IS 'Resend 배달 상태 이벤트 원장(append-only)';
COMMENT ON COLUMN public.mail_event_log.event_type  IS 'sent/delivered/delivery_delayed/bounced/complained/opened/clicked/failed 등. Resend 가 이벤트를 추가해도 적재가 죽지 않도록 CHECK 를 걸지 않는다';
COMMENT ON COLUMN public.mail_event_log.occurred_at IS '페이로드의 created_at. 웹훅 도착 순서는 보장되지 않으므로 정렬은 이 값으로 한다';
COMMENT ON COLUMN public.mail_event_log.detail      IS 'bounce/click/failed 상세 원본 JSON(bounce.subType, click.ipAddress 는 camelCase 라 그대로 보관)';
COMMENT ON COLUMN public.mail_event_log.mail_idx    IS '이벤트가 메일 행보다 먼저 올 수 있어 NULL 허용. 이후 resend_email_id 로 재연결한다';


-- 7) 웹훅 원장(멱등성) ----------------------------------------------------------
--    Resend 는 at-least-once 배달이며 중복 제거 키로 svix-id 헤더를 지정한다.
CREATE TABLE IF NOT EXISTS public.mail_webhook_log (
    svix_id         VARCHAR(100) PRIMARY KEY,
    event_type      VARCHAR(40)  NOT NULL,
    resend_email_id VARCHAR(100),
    payload         JSONB        NOT NULL,
    received_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    process_status  VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    try_cnt         SMALLINT     NOT NULL DEFAULT 0,
    tried_at        TIMESTAMPTZ,
    error_msg       TEXT,
    CONSTRAINT ck_mail_webhook_log_status
        CHECK (process_status IN ('PENDING', 'DONE', 'FAILED', 'SKIP'))
);

-- 처리 대기 큐 폴링
CREATE INDEX IF NOT EXISTS idx_mail_webhook_log_pending
    ON public.mail_webhook_log (tried_at NULLS FIRST, received_at)
    WHERE process_status = 'PENDING';
-- 운영 화면(최근 웹훅 수신 현황), 보존기간 정리 배치
CREATE INDEX IF NOT EXISTS idx_mail_webhook_log_received
    ON public.mail_webhook_log (received_at DESC);

COMMENT ON TABLE  public.mail_webhook_log                IS 'Resend 웹훅 수신 원장. svix_id PK 가 중복 전달을 막는 1차 방어선';
COMMENT ON COLUMN public.mail_webhook_log.svix_id        IS 'svix-id 헤더. 같은 이벤트의 모든 재시도에서 동일하다';
COMMENT ON COLUMN public.mail_webhook_log.payload        IS '검증된 원본 요청 본문. 재처리 시 이 값만으로 다시 돌 수 있어야 한다';
COMMENT ON COLUMN public.mail_webhook_log.process_status IS 'PENDING/DONE/FAILED/SKIP. SKIP 은 우리가 다루지 않는 이벤트 타입';
COMMENT ON COLUMN public.mail_webhook_log.tried_at       IS '마지막 처리 시도 시각(성공 시 완료 시각). 백오프 계산 기준';


-- 8) 메뉴 등록 + 권한 백필 -------------------------------------------------------
--    가드(코드)와 권한(데이터)은 한 쌍이다. menu_mst 에 행이 없으면 사이드바에
--    안 뜨고, user_menu_auth 에 행이 없으면 fail-closed 가드 때문에 관리자 외
--    전원 403 이 된다.
INSERT INTO menu_mst (menu_cd, menu_nm, parent_menu_cd, route_path, menu_type, sort_order, use_yn)
VALUES ('mal001', '메일', NULL, '/mail', 'L', 17, 'Y')
ON CONFLICT (menu_cd) DO UPDATE
SET menu_nm        = EXCLUDED.menu_nm,
    parent_menu_cd = EXCLUDED.parent_menu_cd,
    route_path     = EXCLUDED.route_path,
    menu_type      = EXCLUDED.menu_type,
    sort_order     = EXCLUDED.sort_order,
    use_yn         = EXCLUDED.use_yn,
    updated_at     = now();

-- 조회만 'Y'. 발송·삭제는 관리자 또는 mst003(메뉴권한 관리) 화면에서 개별 부여.
INSERT INTO user_menu_auth (user_idx, menu_cd, can_view, can_create, can_update, can_delete)
SELECT u.user_idx, 'mal001', 'Y', 'N', 'N', 'N'
FROM user_mst u
WHERE NOT EXISTS (SELECT 1
                  FROM user_menu_auth a
                  WHERE a.user_idx = u.user_idx
                    AND a.menu_cd = 'mal001');

COMMIT;

-- 롤백이 필요하면:
--   DROP TABLE IF EXISTS public.mail_webhook_log;
--   DROP TABLE IF EXISTS public.mail_event_log;
--   DROP TABLE IF EXISTS public.mail_att;
--   DROP TABLE IF EXISTS public.mail_addr_dtl;
--   DROP TABLE IF EXISTS public.mail_body;
--   DROP TABLE IF EXISTS public.mail_mst;
--   DROP TABLE IF EXISTS public.mail_thread_mst;
--   DELETE FROM user_menu_auth WHERE menu_cd = 'mal001';
--   UPDATE menu_mst SET use_yn = 'N' WHERE menu_cd = 'mal001';
--   (pg_trgm 은 다른 기능이 쓸 수 있으므로 남겨 둔다)
