package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.OffsetDateTime;

/**
 * Resend 웹훅 요청 본문 최상위.
 *
 * <p>{@code createdAt} 은 페이로드 <b>바깥쪽</b> created_at 이고, 이것이 이벤트가
 * 실제로 일어난 시각이다(mail_event_log.occurred_at 의 기준). data 안에도 created_at
 * 이 또 있는데 그쪽은 메일 생성 시각이라 의미가 다르다. 둘을 헷갈리면 타임라인
 * 정렬이 뒤집힌다.
 *
 * <p>{@code type} 은 {@code email.received} 처럼 접두가 붙은 원문 그대로 받는다.
 * 웹훅 원장(mail_webhook_log)에는 이 원문을, 이벤트 로그에는 접두를 뗀 값을 넣는다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record ResendWebhookEventDto(
        String type,
        @JsonProperty("created_at") OffsetDateTime createdAt,
        ResendWebhookDataDto data) {
}
