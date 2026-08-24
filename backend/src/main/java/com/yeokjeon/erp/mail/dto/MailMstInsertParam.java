package com.yeokjeon.erp.mail.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

/**
 * mail_mst INSERT 파라미터.
 *
 * <p>조회 행과 달리 record 가 아니라 가변 클래스인 이유는 하나다. MyBatis 의
 * {@code useGeneratedKeys="true" keyProperty="mailIdx"} 가 INSERT 직후 생성된 PK 를
 * 이 객체에 <b>되써 넣어야</b> 하는데, record 는 setter 가 없어 값을 받을 수 없다.
 * 호출부는 insert 후 {@code param.getMailIdx()} 로 새 mail_idx 를 읽는다.
 *
 * <p>NOT NULL 컬럼 중 기본값이 있는 것들(att_cnt, body_status, read_yn, mail_at)은
 * 여기서 null 이어도 XML 이 COALESCE 로 막아 준다 — 호출부마다 기본값을 챙기게
 * 하면 언젠가 한 곳이 빠지고 그때 제약 위반으로 터진다.
 */
@Getter
@Setter
public class MailMstInsertParam {

    /** INSERT 후 MyBatis 가 채워 주는 생성키 */
    private Long mailIdx;

    private Long threadIdx;
    private String direction;
    private String resendEmailId;
    private String rfcMessageId;
    private String inReplyTo;
    private String refsTxt;
    private String subject;
    private String subjectNorm;
    private String fromEmail;
    private String fromNm;
    private String toSummary;
    private String snippet;
    private Integer attCnt;
    private String bodyStatus;
    private String sendStatus;
    private String readYn;
    private String userId;
    private Integer partnerIdx;
    private Long mappingId;
    private OffsetDateTime mailAt;

    // ── 2차 확장 ─────────────────────────────────────────────────────────────
    // 전부 NOT NULL DEFAULT 이거나 NULL 허용이라 여기서 null 이어도 XML 이 막아 준다.

    /** 예약발송 시각. 값이 있으면 sendStatus 도 'SCHEDULED' 여야 짝이 맞는다. */
    private OffsetDateTime scheduledAt;

    /** 수신확인 요청('Y'/'N'). null 이면 XML 이 'N' 으로 채운다. */
    private String readReceiptYn;

    /** 중요도 H/N/L. null 이면 XML 이 'N'(보통)으로 채운다. */
    private String importance;
}
