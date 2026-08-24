package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * 배달 상태 이벤트 한 건(발송 메일 타임라인).
 *
 * <p>{@code detail} 은 jsonb 원문 문자열을 그대로 내보낸다. bounce 사유처럼
 * Resend 가 예고 없이 필드를 늘리는 영역이라, 우리가 구조를 고정해 버리면
 * 새 필드가 조용히 사라진다. 화면은 필요한 키만 골라 읽는다.
 */
public record MailEventDto(
        long eventIdx,
        String eventType,
        String recipient,
        OffsetDateTime occurredAt,
        String detail) {

    public static MailEventDto fromRow(MailEventLogJdbcRow row) {
        return new MailEventDto(
                row.eventIdx() == null ? 0L : row.eventIdx(),
                row.eventType() == null ? "" : row.eventType(),
                row.recipient() == null ? "" : row.recipient(),
                MailListItemDto.toSeoul(row.occurredAt()),
                row.detail() == null ? "" : row.detail());
    }
}
