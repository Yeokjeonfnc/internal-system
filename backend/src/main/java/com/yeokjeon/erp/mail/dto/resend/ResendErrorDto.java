package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Resend 오류 응답 바디(statusCode / message / name 3필드).
 *
 * <p>{@code name} 이 재시도 판단의 근거다({@code rate_limit_exceeded} 등). HTTP 상태만
 * 보고 판단하면 "지금 다시 걸면 되는 오류"와 "몇 번을 걸어도 안 되는 오류"를
 * 구분하지 못해 워커가 같은 요청으로 rate limit 을 계속 두드리게 된다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record ResendErrorDto(
        Integer statusCode,
        String message,
        String name) {
}
