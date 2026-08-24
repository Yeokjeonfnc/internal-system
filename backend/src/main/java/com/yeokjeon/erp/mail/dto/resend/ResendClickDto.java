package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.OffsetDateTime;

/**
 * email.clicked 상세.
 *
 * <p>{@code timestamp} 가 실제 클릭 시각이라, 이 이벤트만은 바깥 created_at 이 아니라
 * 이 값을 occurred_at 으로 쓴다. 클릭은 발송 후 며칠 뒤에도 일어나서 두 값의 차이가
 * 크고, 바깥 값으로 정렬하면 타임라인이 실제 순서와 어긋난다.
 *
 * <p>{@code ipAddress}/{@code userAgent} 도 bounce.subType 과 마찬가지로 camelCase 다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record ResendClickDto(
        @JsonProperty("ipAddress") String ipAddress,
        String link,
        OffsetDateTime timestamp,
        @JsonProperty("userAgent") String userAgent) {
}
