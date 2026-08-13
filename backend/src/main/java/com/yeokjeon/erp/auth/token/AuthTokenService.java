package com.yeokjeon.erp.auth.token;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Duration;
import java.util.Base64;

/**
 * 로그인 토큰 발급·검증.
 *
 * <p>외부 라이브러리 없이 JDK 의 HMAC-SHA256 만으로 서명한 무상태(stateless) 토큰을 쓴다.
 * 형식은 {@code base64url(payload).base64url(signature)} 이고 payload 는
 * {@code userId|발급시각|만료시각} 이다. 서버에 세션을 저장하지 않으므로 재시작해도
 * (서명 키만 고정되어 있으면) 로그인 상태가 유지된다.
 *
 * <p>서명 키는 환경변수 {@code AUTH_TOKEN_SECRET} 으로 주입한다. 미설정 시 기동할 때마다
 * 임의 키를 생성하므로 재시작하면 전원 재로그인이 필요하다 — 운영에서는 반드시 설정할 것.
 */
@Slf4j
@Service
public class AuthTokenService {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final Base64.Encoder ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder DECODER = Base64.getUrlDecoder();

    private final String configuredSecret;
    private final Duration validity;
    private byte[] secretKey;

    public AuthTokenService(
            @Value("${auth.token.secret:}") String configuredSecret,
            @Value("${auth.token.validity-hours:12}") long validityHours) {
        this.configuredSecret = configuredSecret;
        this.validity = Duration.ofHours(validityHours);
    }

    /** 서명 키 최소 길이 — 이보다 짧으면 무차별 대입으로 토큰 위조가 가능해진다. */
    private static final int MIN_SECRET_LENGTH = 32;

    @PostConstruct
    void initSecret() {
        if (configuredSecret != null && !configuredSecret.isBlank()) {
            String trimmed = configuredSecret.trim();
            if (trimmed.length() < MIN_SECRET_LENGTH) {
                // 짧은 키를 조용히 받아주면 토큰 위조 위험이 생긴다 — 기동을 막는다.
                throw new IllegalStateException(
                        "AUTH_TOKEN_SECRET 이 너무 짧습니다(" + trimmed.length() + "자). "
                                + MIN_SECRET_LENGTH + "자 이상의 임의 문자열을 사용하세요.");
            }
            secretKey = trimmed.getBytes(StandardCharsets.UTF_8);
            return;
        }
        byte[] generated = new byte[32];
        new SecureRandom().nextBytes(generated);
        secretKey = generated;
        // 주의: 생성된 키를 로그에 남기면 안 된다. 로그를 볼 수 있는 사람이
        // 임의 사용자(admin 포함)의 토큰을 위조할 수 있게 된다.
        log.warn(
                "AUTH_TOKEN_SECRET 미설정 — 기동 시 임의 키를 생성했습니다. "
                        + "재시작하면 모든 사용자가 다시 로그인해야 합니다. "
                        + "운영 환경에서는 config\\backend.env 에 AUTH_TOKEN_SECRET 을 설정하세요.");
    }

    /** 로그인 성공 사용자에게 발급할 토큰. */
    public String issue(String userId) {
        return issue(userId, System.currentTimeMillis());
    }

    /**
     * 발급 시각을 지정해 토큰을 만든다.
     *
     * <p>비밀번호 변경 직후 재발급에 쓴다. 무효화 기준선과 발급이 같은 밀리초에 일어나면
     * 방금 발급한 토큰까지 무효 처리되어 사용자가 튕기므로, 기준선보다 확실히 뒤인
     * 시각을 넘겨 그 경계 문제를 없앤다.
     */
    public String issue(String userId, long issuedAt) {
        long now = issuedAt;
        long expiresAt = now + validity.toMillis();
        String payload = userId + "|" + now + "|" + expiresAt;
        String encodedPayload = ENCODER.encodeToString(payload.getBytes(StandardCharsets.UTF_8));
        return encodedPayload + "." + ENCODER.encodeToString(sign(encodedPayload));
    }

    /** 검증에 성공한 토큰의 내용. */
    public record Verified(String userId, long issuedAt) {}

    /**
     * 토큰을 검증하고 사용자 ID 를 돌려준다. 서명이 틀리거나 만료됐으면 {@code null}.
     */
    public String verify(String token) {
        Verified v = verifyDetailed(token);
        return v == null ? null : v.userId();
    }

    /**
     * 토큰을 검증하고 사용자 ID 와 발급 시각을 함께 돌려준다.
     * 발급 시각은 비밀번호 변경 이후 발급분인지 판정하는 데 쓴다.
     */
    public Verified verifyDetailed(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }
        int dot = token.indexOf('.');
        if (dot <= 0 || dot == token.length() - 1) {
            return null;
        }
        String encodedPayload = token.substring(0, dot);
        String encodedSignature = token.substring(dot + 1);

        byte[] expected = sign(encodedPayload);
        byte[] provided;
        byte[] payloadBytes;
        try {
            provided = DECODER.decode(encodedSignature);
            payloadBytes = DECODER.decode(encodedPayload);
        } catch (IllegalArgumentException e) {
            return null;
        }
        // 타이밍 공격 방지를 위해 상수 시간 비교.
        if (!MessageDigest.isEqual(expected, provided)) {
            return null;
        }

        String payload = new String(payloadBytes, StandardCharsets.UTF_8);
        String[] parts = payload.split("\\|");
        if (parts.length != 3) {
            return null;
        }
        long issuedAt;
        long expiresAt;
        try {
            issuedAt = Long.parseLong(parts[1]);
            expiresAt = Long.parseLong(parts[2]);
        } catch (NumberFormatException e) {
            return null;
        }
        if (System.currentTimeMillis() >= expiresAt) {
            return null;
        }
        String userId = parts[0];
        return userId.isBlank() ? null : new Verified(userId, issuedAt);
    }

    private byte[] sign(String encodedPayload) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(secretKey, HMAC_ALGORITHM));
            return mac.doFinal(encodedPayload.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            // 알고리즘은 JDK 표준이라 실제로는 발생하지 않는다.
            throw new IllegalStateException("토큰 서명 실패", e);
        }
    }
}
