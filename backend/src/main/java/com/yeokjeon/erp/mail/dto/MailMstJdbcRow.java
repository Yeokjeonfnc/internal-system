package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * mail_mst 한 행을 그대로 담는 조회 전용 레코드.
 *
 * <p>필드 순서를 mail_mst 의 컬럼 순서와 똑같이 맞춰 두었다. XML resultMap 이
 * {@code <constructor><arg>} 순서로 값을 밀어 넣기 때문에, 한 칸만 어긋나도
 * 컴파일은 통과하고 런타임에 엉뚱한 값이 들어간다. 스키마에 컬럼을 추가할 때는
 * 반드시 이 순서와 XML 을 같이 고칠 것.
 *
 * <p>전부 박싱 타입인 이유: smallint/timestamptz 컬럼 상당수가 NULL 허용이라
 * 원시 타입이면 NULL 을 0/false 로 뭉개 버린다. "값이 없음"과 "0"은 다르다.
 */
public record MailMstJdbcRow(
        Long mailIdx,
        Long threadIdx,
        String direction,
        String resendEmailId,
        String rfcMessageId,
        String inReplyTo,
        String refsTxt,
        String subject,
        String subjectNorm,
        String fromEmail,
        String fromNm,
        String toSummary,
        String snippet,
        Integer attCnt,
        String bodyStatus,
        Integer bodyTryCnt,
        OffsetDateTime bodyTriedAt,
        String bodyErr,
        String sendStatus,
        Integer sendTryCnt,
        OffsetDateTime sendTriedAt,
        String sendErr,
        String lastStatus,
        OffsetDateTime lastStatusAt,
        String readYn,
        String spamYn,
        String userId,
        Integer partnerIdx,
        Long mappingId,
        OffsetDateTime mailAt,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        Boolean deletedYn,

        // ── 2차 확장(20260824_mal001_menu_tree_and_features.sql) ──────────────
        // 전부 ALTER TABLE 로 뒤에 붙은 컬럼이라 여기서도 맨 뒤에 이어 붙인다.
        // 중간에 끼워 넣으면 위쪽 필드가 통째로 한 칸씩 밀린다.

        /** 중요표시. 폴더가 아니라 플래그다(다우오피스도 같은 방식). */
        String starYn,
        /** 사용자 정의 메일함. NULL 이면 기본함 규칙으로 분류된다. */
        Long folderIdx,
        /** 예약발송 시각. send_status='SCHEDULED' 와 짝이다. */
        OffsetDateTime scheduledAt,
        /** 수신확인 요청 여부. 'Y' 면 발송 시 본문에 추적픽셀을 심는다. */
        String readReceiptYn,
        /** 수신확인이 처음 걸린 시각. 최초 1회만 기록한다. */
        OffsetDateTime openedAt,
        /** 픽셀 호출 누적 횟수. 이미지 프록시 때문에 실제 열람 횟수와 일치하지 않는다. */
        Integer openCnt,
        /** 중요도 H(높음)/N(보통)/L(낮음). 발송 시 X-Priority 헤더로 나간다. */
        String importance,

        // ── 3차 확장(20260824_mal001_rules_forward.sql) ──────────────────────

        /**
         * 자동전달로 만들어진 메일이면 원본 mail_idx. 사람이 쓴 메일은 NULL.
         *
         * <p>자동분류·자동전달 엔진은 이 값이 있는 행을 건너뛴다. 전달 메일이 다시
         * 전달 규칙을 타면 메일이 무한히 늘어나기 때문이다.
         */
        Long fwdSrcIdx) {
}
