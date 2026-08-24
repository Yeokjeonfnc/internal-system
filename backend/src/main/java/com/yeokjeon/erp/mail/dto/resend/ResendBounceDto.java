package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * email.bounced 상세.
 *
 * <p>{@code subType} 은 Resend 가 camelCase 로 준다 — 다른 필드들이 snake_case 인
 * 것과 달라서 헷갈리기 쉬워 명시적으로 {@code @JsonProperty} 를 붙였다.
 * ({@code type}=Permanent/Transient, {@code subType}=General/Suppressed 등)
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record ResendBounceDto(
        String message,
        @JsonProperty("subType") String subType,
        String type) {
}
