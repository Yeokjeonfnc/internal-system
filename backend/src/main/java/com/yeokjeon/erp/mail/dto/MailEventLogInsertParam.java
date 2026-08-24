package com.yeokjeon.erp.mail.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

/**
 * mail_event_log INSERT 파라미터.
 *
 * <p>{@code detailJson} 은 이미 직렬화된 JSON 문자열이다. XML 에서
 * {@code CAST(#{detailJson} AS jsonb)} 로 넣는다 — 자바에서 Map 으로 들고 있다가
 * MyBatis 타입핸들러를 새로 만드는 것보다, 웹훅 원문 조각을 그대로 문자열로
 * 넘기는 편이 "원문 보존"이라는 목적에 정확히 맞는다.
 *
 * <p>{@code svixId} 가 null 이면(재동기화 배치가 만든 이벤트) UNIQUE 제약이
 * 걸리지 않는다 — NULL 끼리는 서로 중복으로 보지 않기 때문이다. 웹훅으로 들어온
 * 이벤트는 반드시 svixId 를 채워야 중복 적재가 막힌다.
 */
@Getter
@Setter
public class MailEventLogInsertParam {

    /** INSERT 후 MyBatis 가 채워 주는 생성키. 중복(ON CONFLICT DO NOTHING)이면 null 로 남는다 */
    private Long eventIdx;

    private Long mailIdx;
    private String resendEmailId;
    private String eventType;
    private String recipient;
    private OffsetDateTime occurredAt;
    private String detailJson;
    private String svixId;
}
