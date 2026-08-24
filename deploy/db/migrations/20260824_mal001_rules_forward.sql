-- 메일(mal001) 3차 — 자동분류 규칙 + 자동전달
--
-- 배경
--   다우오피스 사양을 그대로 따른다. 사용자가 이미 그것에 익숙해서, 조건을 더 풍부하게
--   만드는 것보다 "쓰던 대로 되는" 편이 낫다고 판단했다.
--
--   [자동분류 규칙 — mail_rule]
--     조건: 보낸사람 / 수신자(참조 포함) / 메일제목 세 가지뿐이고 <b>AND 로만</b> 묶인다.
--           다우에 OR 이 없다. OR 을 넣으려면 조건을 행으로 쪼개야 하는데(1:N),
--           그러면 "규칙 하나 = 행 하나"라는 단순함이 깨지고 화면도 훨씬 복잡해진다.
--           그래서 조건 3개를 각각 컬럼으로 두고 NULL 이면 "이 조건 무시" 로 읽는다.
--     처리: 메일함 이동 <b>또는</b> 읽음처리 — 규칙당 하나. 다우도 하나만 고르게 한다.
--     순서: sort_order 오름차순으로 훑어 <b>첫 매칭 하나만</b> 적용한다. 여러 규칙이
--           동시에 걸리면 folder_idx 를 두 번 덮어써서 결과가 규칙 순서에 따라 달라지는데,
--           그 동작은 사용자가 예측할 수 없다.
--     시점: 설정 이후 수신분부터. 기존 메일 소급 적용은 하지 않는다(다우와 동일).
--
--   [자동전달 — mail_forward_setting / mail_forward_rule]
--     ① 전체 자동전달(사용자당 1행): 받는 메일 전부를 지정 주소로. 원본을 남길지 지울지 선택.
--     ② 예외 규칙: 특정 발신자 주소·도메인은 다른 주소로(세금계산서·고지서를 회계 담당에게).
--        다우 기본 상한이 10개라 우리도 10개로 맞춘다. 이 상한은 서비스가 강제한다
--        (트리거로 막으면 마이그레이션·일괄 정리 스크립트까지 같이 막혀 운영이 불편해진다).
--
--   [무한 루프 방지 — mail_mst.fwd_src_idx]
--     전달로 만들어진 메일이 다시 전달 규칙을 타면 메일이 무한히 늘어난다. 그래서
--     전달로 생성된 행에 원본 mail_idx 를 남기고, 규칙·전달 엔진은 그 표시가 있는 행을
--     건너뛴다. 표시는 감사 추적("이 메일은 어느 메일의 자동전달인가")도 겸한다.
--     ※ 실효 차단은 코드 쪽에도 한 겹 더 있다(MailAutoProcessService) — 전달 메일이
--       외부를 한 바퀴 돌아 수신으로 되돌아오면 새 행이라 표시가 없기 때문이다.
--       그 경우는 from_email 이 우리 발신 주소인 것으로 걸러 낸다.
--
-- 안전성
--   전부 CREATE ... IF NOT EXISTS / ADD COLUMN IF NOT EXISTS / DO $$ 가드라 여러 번
--   돌려도 안전하다. 기존 테이블은 mail_mst 에 컬럼 하나(NULL 허용)를 더하는 것 외에
--   건드리지 않는다.
--
-- 실행
--   psql -h localhost -p 5433 -U postgres -d yeokjeon_on -f 20260824_mal001_rules_forward.sql
--   (한글 주석이 깨져 트랜잭션이 죽으면 먼저:  $env:PGCLIENTENCODING="UTF8" )

BEGIN;

-- ── 1) 자동분류 규칙 ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.mail_rule (
    mail_rule_idx     bigserial    PRIMARY KEY,
    user_id           varchar(50)  NOT NULL,
    rule_nm           varchar(100) NOT NULL,
    sort_order        integer      NOT NULL DEFAULT 0,
    use_yn            char(1)      NOT NULL DEFAULT 'Y',

    -- 조건 3개. op/val 은 <b>같이 있거나 같이 없어야</b> 한다. NULL 쌍이면 "이 조건 무시".
    -- 셋을 다 무시하면 모든 메일에 걸리는 규칙이 되므로 아래 ck_mail_rule_any_cond 로 막는다.
    from_op           varchar(10),
    from_val          varchar(320),
    to_op             varchar(10),
    to_val            varchar(320),
    subj_op           varchar(10),
    subj_val          varchar(500),

    -- 처리는 규칙당 하나. MOVE 면 대상 메일함이 반드시 있어야 하고,
    -- READ 면 대상 메일함이 있으면 안 된다(있으면 화면이 "어디로 옮기지?"를 물을 수 없다).
    action_type       varchar(10)  NOT NULL,
    action_folder_idx bigint       REFERENCES public.mail_folder_mst (mail_folder_idx)
                                   ON DELETE CASCADE,

    created_at        timestamptz  NOT NULL DEFAULT now(),
    updated_at        timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT ck_mail_rule_use_yn  CHECK (use_yn IN ('Y', 'N')),
    CONSTRAINT ck_mail_rule_from    CHECK ((from_op IS NULL AND from_val IS NULL)
                                        OR (from_op IN ('CONTAINS', 'EQUALS', 'STARTS')
                                            AND from_val IS NOT NULL)),
    CONSTRAINT ck_mail_rule_to      CHECK ((to_op IS NULL AND to_val IS NULL)
                                        OR (to_op IN ('CONTAINS', 'EQUALS', 'STARTS')
                                            AND to_val IS NOT NULL)),
    CONSTRAINT ck_mail_rule_subj    CHECK ((subj_op IS NULL AND subj_val IS NULL)
                                        OR (subj_op IN ('CONTAINS', 'EQUALS', 'STARTS')
                                            AND subj_val IS NOT NULL)),
    -- 조건이 하나도 없는 규칙 = 모든 수신 메일이 첫 규칙에서 잡혀 나머지 규칙이 죽는다.
    CONSTRAINT ck_mail_rule_any_cond CHECK (from_val IS NOT NULL
                                         OR to_val IS NOT NULL
                                         OR subj_val IS NOT NULL),
    CONSTRAINT ck_mail_rule_action  CHECK (action_type IN ('MOVE', 'READ')),
    CONSTRAINT ck_mail_rule_action_folder
        CHECK ((action_type = 'MOVE' AND action_folder_idx IS NOT NULL)
            OR (action_type = 'READ' AND action_folder_idx IS NULL))
);

COMMENT ON TABLE  public.mail_rule                   IS '수신 메일 자동분류 규칙(다우오피스 사양). 조건은 AND 만, 처리는 규칙당 하나';
COMMENT ON COLUMN public.mail_rule.user_id           IS '소유자. 규칙은 개인 소유물이라 남이 못 본다(mail_folder_mst 와 같은 관례로 FK 없음)';
COMMENT ON COLUMN public.mail_rule.sort_order        IS '적용 순서. 오름차순으로 훑어 첫 매칭 하나만 적용한다';
COMMENT ON COLUMN public.mail_rule.from_op           IS 'CONTAINS(포함)/EQUALS(일치)/STARTS(시작함). val 과 짝이며 NULL 이면 이 조건 무시';
COMMENT ON COLUMN public.mail_rule.from_val          IS '보낸사람 주소 비교값. 저장·비교 모두 소문자';
COMMENT ON COLUMN public.mail_rule.to_val            IS '수신자 비교값. TO 뿐 아니라 CC(참조)까지 본다 — 다우도 "수신자(참조 포함)" 하나로 묶어 둔다';
COMMENT ON COLUMN public.mail_rule.subj_val          IS '메일제목 비교값. 대소문자 무시';
COMMENT ON COLUMN public.mail_rule.action_type       IS 'MOVE=메일함 이동 / READ=읽음처리. 다우와 같이 규칙당 하나만 고른다';
COMMENT ON COLUMN public.mail_rule.action_folder_idx IS 'MOVE 대상 메일함. 메일함을 지우면 이 규칙도 함께 지운다(ON DELETE CASCADE) — 갈 곳 없는 MOVE 규칙은 의미가 없고, SET NULL 로 두면 위 CHECK 를 위반해 메일함 삭제 자체가 실패한다';

-- 규칙 적용은 수신 1건마다 "내 규칙 전부"를 순서대로 읽는 질의 하나다.
CREATE INDEX IF NOT EXISTS idx_mail_rule_owner
    ON public.mail_rule (user_id, sort_order, mail_rule_idx);


-- ── 2) 자동전달 — 전체 설정(사용자당 1행) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.mail_forward_setting (
    user_id          varchar(50)  PRIMARY KEY,
    use_yn           char(1)      NOT NULL DEFAULT 'N',
    forward_email    varchar(320),
    keep_original_yn char(1)      NOT NULL DEFAULT 'Y',
    created_at       timestamptz  NOT NULL DEFAULT now(),
    updated_at       timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT ck_mail_fwd_set_use   CHECK (use_yn IN ('Y', 'N')),
    CONSTRAINT ck_mail_fwd_set_keep  CHECK (keep_original_yn IN ('Y', 'N')),
    -- 켜 놓고 주소가 비면 "전달 중"으로 보이는데 아무 데도 안 가는 상태가 된다.
    CONSTRAINT ck_mail_fwd_set_addr  CHECK (use_yn = 'N' OR forward_email IS NOT NULL)
);

COMMENT ON TABLE  public.mail_forward_setting                  IS '전체 자동전달 설정(사용자당 1행). 예외 규칙은 mail_forward_rule';
COMMENT ON COLUMN public.mail_forward_setting.forward_email    IS '전달받을 주소. 소문자로 정규화해 저장한다';
COMMENT ON COLUMN public.mail_forward_setting.keep_original_yn IS 'N 이면 전달 후 원본을 휴지통으로 보낸다. **받은메일함이 공용이라 다른 사람 화면에서도 사라진다** — 기본값을 Y 로 두는 이유다';


-- ── 3) 자동전달 — 예외 규칙 ─────────────────────────────────────────────────
--    "이 발신자만은 다른 주소로" 를 표현한다. 전체 자동전달이 꺼져 있어도 독립적으로
--    동작한다 — 세금계산서만 회계 담당에게 보내고 나머지는 전달하지 않는 쓰임이 실제로 많다.
CREATE TABLE IF NOT EXISTS public.mail_forward_rule (
    mail_fwd_rule_idx bigserial    PRIMARY KEY,
    user_id           varchar(50)  NOT NULL,
    match_type        varchar(10)  NOT NULL,
    match_val         varchar(320) NOT NULL,
    forward_email     varchar(320) NOT NULL,
    use_yn            char(1)      NOT NULL DEFAULT 'Y',
    sort_order        integer      NOT NULL DEFAULT 0,
    created_at        timestamptz  NOT NULL DEFAULT now(),
    updated_at        timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT ck_mail_fwd_rule_type CHECK (match_type IN ('EMAIL', 'DOMAIN')),
    CONSTRAINT ck_mail_fwd_rule_use  CHECK (use_yn IN ('Y', 'N')),
    -- 같은 발신자를 두 번 등록하면 어느 주소로 갈지 순서에 좌우된다. 애초에 막는다.
    CONSTRAINT uq_mail_fwd_rule_match UNIQUE (user_id, match_type, match_val)
);

COMMENT ON TABLE  public.mail_forward_rule                IS '자동전달 예외 규칙(발신자별 다른 전달 주소). 사용자당 최대 10개 — 다우오피스 기본 상한을 따르며 서비스가 강제한다';
COMMENT ON COLUMN public.mail_forward_rule.match_type     IS 'EMAIL=주소 완전일치 / DOMAIN=도메인 일치(@ 없이 저장, 하위 도메인 포함)';
COMMENT ON COLUMN public.mail_forward_rule.match_val      IS '비교값. 소문자로 정규화해 저장한다';
COMMENT ON COLUMN public.mail_forward_rule.forward_email  IS '이 발신자의 메일을 보낼 주소';
COMMENT ON COLUMN public.mail_forward_rule.sort_order     IS '먼저 걸린 규칙 하나만 적용된다(EMAIL 이 DOMAIN 보다 구체적이라 서비스가 EMAIL 을 먼저 본다)';

CREATE INDEX IF NOT EXISTS idx_mail_fwd_rule_owner
    ON public.mail_forward_rule (user_id, sort_order, mail_fwd_rule_idx);


-- ── 4) mail_mst 확장 — 전달 표시 ────────────────────────────────────────────
ALTER TABLE public.mail_mst
    ADD COLUMN IF NOT EXISTS fwd_src_idx bigint;

COMMENT ON COLUMN public.mail_mst.fwd_src_idx IS '자동전달로 만들어진 메일이면 원본 mail_idx. NULL 이면 사람이 쓴 메일. 규칙·전달 엔진은 이 값이 있는 행을 건너뛴다(무한 전달 방지)';

-- 원본을 완전삭제(purge)해도 전달 이력은 남아야 하므로 CASCADE 가 아니라 SET NULL 이다.
-- CASCADE 면 원본을 지우는 순간 전달로 나간 메일의 발송 이력까지 통째로 사라진다.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_mail_mst_fwd_src') THEN
        ALTER TABLE public.mail_mst
            ADD CONSTRAINT fk_mail_mst_fwd_src
            FOREIGN KEY (fwd_src_idx) REFERENCES public.mail_mst (mail_idx)
            ON DELETE SET NULL;
    END IF;
END $$;

-- "이 메일을 이미 전달했는가" 를 본문 수집 때마다 확인한다(수동 재수집으로 두 번 나가는 것 방지).
-- 전달 메일은 전체의 극소수라 부분 인덱스로 둔다.
CREATE INDEX IF NOT EXISTS idx_mail_mst_fwd_src
    ON public.mail_mst (fwd_src_idx)
    WHERE fwd_src_idx IS NOT NULL;

COMMIT;

-- 되돌리려면:
--   ALTER TABLE public.mail_mst DROP CONSTRAINT IF EXISTS fk_mail_mst_fwd_src;
--   DROP INDEX IF EXISTS public.idx_mail_mst_fwd_src;
--   ALTER TABLE public.mail_mst DROP COLUMN IF EXISTS fwd_src_idx;
--   DROP TABLE IF EXISTS public.mail_forward_rule;
--   DROP TABLE IF EXISTS public.mail_forward_setting;
--   DROP TABLE IF EXISTS public.mail_rule;
