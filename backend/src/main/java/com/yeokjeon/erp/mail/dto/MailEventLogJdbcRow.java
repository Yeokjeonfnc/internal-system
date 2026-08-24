package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * mail_event_log 한 행(배달 상태 이벤트).
 *
 * <p>{@code mailIdx} 가 NULL 일 수 있다. Resend 웹훅은 순서를 보장하지 않아서
 * 메일 본체보다 이벤트가 먼저 도착하는 경우가 실제로 생기기 때문이다. 그런 고아
 * 이벤트는 나중에 {@code relinkOrphans} 가 resend_email_id 로 다시 붙인다.
 *
 * <p>{@code detail} 은 jsonb 지만 String 으로 받는다 — bounce.subType, click.ipAddress
 * 처럼 Resend 가 camelCase 로 주는 값이 섞여 있어 원문 보존이 목적이다.
 */
public record MailEventLogJdbcRow(
        Long eventIdx,
        Long mailIdx,
        String resendEmailId,
        String eventType,
        String recipient,
        OffsetDateTime occurredAt,
        String detail,
        String svixId,
        OffsetDateTime createdAt) {
}
