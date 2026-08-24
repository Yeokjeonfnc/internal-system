package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * mail_webhook_log 한 행(웹훅 수신 원장).
 *
 * <p>{@code svixId} 가 PK 다. Resend 웹훅은 at-least-once 라서 같은 이벤트가 여러 번
 * 오는데, 모든 재시도에서 svix-id 헤더가 동일하다는 것이 유일한 중복 판별 근거다.
 *
 * <p>{@code payload} 는 검증이 끝난 원본 요청 본문이다. 재처리는 이 값만으로 다시
 * 돌 수 있어야 하므로(원장의 존재 이유) 파싱해서 축약해 넣지 않는다.
 */
public record MailWebhookLogJdbcRow(
        String svixId,
        String eventType,
        String resendEmailId,
        String payload,
        OffsetDateTime receivedAt,
        String processStatus,
        Integer tryCnt,
        OffsetDateTime triedAt,
        String errorMsg) {
}
