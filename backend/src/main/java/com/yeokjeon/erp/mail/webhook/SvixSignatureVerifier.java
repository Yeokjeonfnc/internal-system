package com.yeokjeon.erp.mail.webhook;

import com.yeokjeon.erp.mail.config.ResendProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.Base64;

/**
 * Resend 웹훅의 Svix 서명 검증.
 *
 * <p>이 엔드포인트는 {@code AuthTokenFilter.PUBLIC_PATHS} 에 있어 로그인 토큰이 없다.
 * 즉 <b>이 클래스가 유일한 방어선</b>이다. 통과시키면 아무나 우리 DB 에 메일 이력을
 * 심을 수 있으므로 어떤 이유로도 검증을 우회하게 두지 말 것.
 *
 * <p><b>설정이 없으면 거부한다.</b> "시크릿 미설정 = 검증 생략" 으로 두면 방어선이
 * 설정 누락 하나로 통째로 사라진다. 검증할 수 없는 요청은 통과가 아니라 거부다.
 *
 * <p>Svix 규격(= Resend 가 쓰는 것):
 *
 * <ol>
 *   <li>시크릿은 {@code whsec_} 접두 + Base64. 접두를 떼고 <b>디코드한 바이트</b>가 HMAC 키다.
 *       (문자열을 그대로 키로 쓰면 서명이 영원히 안 맞는다 — 가장 흔한 실수)
 *   <li>서명 대상 문자열은 {@code {svix-id}.{svix-timestamp}.{본문원문}}.
 *       본문은 <b>바이트 그대로</b>여야 하므로 컨트롤러가 DTO 가 아닌 String 으로 받는다.
 *   <li>{@code svix-signature} 헤더는 {@code "v1,<base64> v1a,<base64>"} 처럼 공백으로 구분된
 *       여러 서명이 올 수 있다(키 회전 중). 하나라도 맞으면 통과.
 *   <li>{@code svix-timestamp} 가 허용 오차를 벗어나면 거부 — 가로챈 요청을 나중에 다시
 *       쏘는 재전송 공격을 막는다.
 * </ol>
 *
 * <p><b>로그 금지 사항</b>: 시크릿·서명 헤더 원문·본문 원문은 어떤 레벨로도 찍지 않는다.
 * 서명이 로그에 남으면 그 자체가 재전송 재료가 된다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SvixSignatureVerifier {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final String SECRET_PREFIX = "whsec_";
    private static final String SIGNATURE_VERSION = "v1";

    private final ResendProperties properties;

    /**
     * 웹훅 요청의 서명을 검증한다.
     *
     * <p><b>시크릿이 없으면 거부한다(false).</b> 예전에는 "검증 불가"를 통과로 처리했는데,
     * 배포용 backend.env 4개가 전부 {@code RESEND_WEBHOOK_SECRET=} 빈 값으로 출하되므로
     * 그 기본 상태가 곧 "아무나 우리 DB 에 메일을 심을 수 있는 무인증 쓰기 경로"였다.
     * 설정 누락은 열어 둘 사유가 아니라 막아야 할 사고다 — 웹훅이 안 오는 편이,
     * 위조된 거래처 메일이 받은편지함에 뜨는 것보다 훨씬 낫다.
     *
     * <p>검증을 끄는 유일한 방법은 {@code resend.webhook.verify-signature=false} 를
     * <b>명시적으로</b> 주는 것뿐이다(기본값 true). 로컬에서 Resend 없이 흉내 낼 때만 쓰고
     * 운영 env 에는 절대 넣지 말 것.
     *
     * @param rawBody 파싱하기 전의 본문 원문. 재직렬화한 JSON 을 넣으면 공백·키 순서가 달라져 무조건 실패한다.
     * @return 서명이 유효하거나 명시적으로 검증을 끈 경우 true
     */
    public boolean verify(String svixId, String svixTimestamp, String svixSignature, String rawBody) {
        if (!properties.getWebhook().isVerifySignature()) {
            // 운영에 이 설정이 들어가면 방어선이 0개가 된다. 눈에 띄라고 ERROR 로 남긴다.
            log.error("메일 웹훅 서명 검증이 꺼져 있습니다(resend.webhook.verify-signature=false)."
                    + " 인증 없는 쓰기 경로가 열려 있습니다 — 운영에서는 반드시 켤 것.");
            return true;
        }
        if (!properties.isWebhookConfigured()) {
            // 시크릿 형식이 깨진 경우(아래 decodeSecret)와 같은 판단이다: 검증 불가 = 거부.
            log.error("메일 웹훅 시크릿(RESEND_WEBHOOK_SECRET)이 없어 검증할 수 없으므로 요청을 거부합니다."
                    + " Resend 대시보드의 서명 시크릿을 환경변수로 설정해 주세요.");
            return false;
        }

        if (isBlank(svixId) || isBlank(svixTimestamp) || isBlank(svixSignature) || rawBody == null) {
            log.warn("메일 웹훅 서명 헤더 누락으로 거부합니다.");
            return false;
        }
        if (!isTimestampFresh(svixTimestamp)) {
            return false;
        }

        byte[] key = decodeSecret(properties.getWebhookSecret());
        if (key == null) {
            // 시크릿 형식이 깨졌다면 "검증 불가"이지 "검증 통과"가 아니다. 열어두면 방어선이 사라진다.
            log.error("메일 웹훅 시크릿 형식이 올바르지 않아 검증할 수 없습니다(whsec_ + Base64 여야 함).");
            return false;
        }

        String signedContent = svixId + "." + svixTimestamp + "." + rawBody;
        String expected = hmacBase64(key, signedContent);
        if (expected == null) {
            return false;
        }

        // 헤더에 여러 서명이 실릴 수 있어 하나라도 맞으면 통과시킨다(시크릿 회전 구간 대응).
        for (String token : svixSignature.split(" ")) {
            int comma = token.indexOf(',');
            if (comma <= 0) {
                continue;
            }
            if (!SIGNATURE_VERSION.equals(token.substring(0, comma))) {
                continue;
            }
            String candidate = token.substring(comma + 1);
            // 타이밍 공격 방지 — 앞자리부터 순차 비교하는 equals 대신 상수시간 비교를 쓴다.
            if (MessageDigest.isEqual(
                    candidate.getBytes(StandardCharsets.UTF_8),
                    expected.getBytes(StandardCharsets.UTF_8))) {
                return true;
            }
        }

        log.warn("메일 웹훅 서명 불일치로 거부합니다. svixId={}", svixId);
        return false;
    }

    /**
     * 타임스탬프가 허용 오차 안인지 본다.
     *
     * <p>미래 방향도 같이 막는다 — 서버 시계가 어긋난 공격자가 아주 먼 미래 값을 넣어
     * 서명을 무기한 재사용하는 것을 방지한다.
     */
    private boolean isTimestampFresh(String svixTimestamp) {
        long epochSeconds;
        try {
            epochSeconds = Long.parseLong(svixTimestamp.trim());
        } catch (NumberFormatException e) {
            log.warn("메일 웹훅 타임스탬프 형식 오류로 거부합니다.");
            return false;
        }
        long diff = Math.abs(Instant.now().getEpochSecond() - epochSeconds);
        int tolerance = properties.getWebhook().getToleranceSeconds();
        if (diff > tolerance) {
            log.warn("메일 웹훅 타임스탬프가 허용 오차({}초)를 벗어나 거부합니다. 차이={}초", tolerance, diff);
            return false;
        }
        return true;
    }

    /** {@code whsec_} 접두를 떼고 Base64 디코드. 실패하면 null(시크릿 내용은 로그에 남기지 않는다). */
    private static byte[] decodeSecret(String secret) {
        String raw = secret.startsWith(SECRET_PREFIX) ? secret.substring(SECRET_PREFIX.length()) : secret;
        try {
            return Base64.getDecoder().decode(raw.trim());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static String hmacBase64(byte[] key, String content) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(key, HMAC_ALGORITHM));
            return Base64.getEncoder()
                    .encodeToString(mac.doFinal(content.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            // 예외 메시지에 키가 섞일 여지를 없애려고 메시지만 남기고 스택은 생략한다.
            log.error("메일 웹훅 서명 계산 실패: {}", e.getClass().getSimpleName());
            return null;
        }
    }

    private static boolean isBlank(String v) {
        return v == null || v.isBlank();
    }
}
