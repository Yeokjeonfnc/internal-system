package com.yeokjeon.erp.mail.client;

/**
 * Resend API 호출 실패.
 *
 * <p>새 예외 계층을 만들지 않고 {@link RuntimeException} 하나로 끝내는 이유는,
 * 이 예외를 잡는 쪽(워커·서비스)이 "다시 시도할 값어치가 있는가"만 알면 되기 때문이다.
 * 그 판단에 필요한 정보는 HTTP 상태코드와 Resend 오류 바디의 {@code name} 뿐이라
 * 그 두 값을 필드로 들고 다닌다.
 *
 * <p>주의: 메시지에 API 키나 서명 헤더를 절대 담지 말 것. 이 예외 메시지는
 * {@code mail_mst.send_err} / {@code mail_mst.body_err} 로 DB 에 남고 화면에도 노출된다.
 */
public class ResendApiException extends RuntimeException {

    private final int statusCode;
    private final String errorName;
    private final int retryAfterSeconds;

    public ResendApiException(int statusCode, String errorName, String message) {
        this(statusCode, errorName, message, 0);
    }

    public ResendApiException(int statusCode, String errorName, String message, int retryAfterSeconds) {
        super(message);
        this.statusCode = statusCode;
        this.errorName = errorName == null ? "" : errorName;
        this.retryAfterSeconds = Math.max(retryAfterSeconds, 0);
    }

    public int statusCode() {
        return statusCode;
    }

    /** Resend 오류 바디의 {@code name}(rate_limit_exceeded, validation_error 등). 없으면 빈 문자열. */
    public String errorName() {
        return errorName;
    }

    /** {@code retry-after} / {@code ratelimit-reset} 헤더에서 읽은 대기 초. 없으면 0. */
    public int retryAfterSeconds() {
        return retryAfterSeconds;
    }

    /**
     * 다시 시도할 가치가 있는 실패인가.
     *
     * <p>429(rate limit — 팀 단위 10 req/s)와 5xx(Resend 쪽 장애)만 재시도한다.
     * 4xx 는 요청 자체가 잘못된 것이라 몇 번을 보내도 같은 결과이므로 즉시 FAILED 로 확정한다.
     * 네트워크 오류·타임아웃은 {@link ResendClient} 가 503 으로 감싸 넣어 여기서 재시도로 분류된다.
     */
    public boolean retryable() {
        return statusCode == 429 || statusCode >= 500;
    }
}
