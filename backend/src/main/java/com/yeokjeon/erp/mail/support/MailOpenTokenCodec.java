package com.yeokjeon.erp.mail.support;

import lombok.extern.slf4j.Slf4j;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;

/**
 * 수신확인 추적픽셀 토큰 인코더/디코더 (mal001-G).
 *
 * <p><b>왜 mail_idx 를 그대로 URL 에 쓰지 않는가.</b> 추적픽셀 주소는 수신자에게 그대로
 * 전달되고, 메일 헤더·프록시·회사 메일게이트웨이 로그에 남는다. {@code /mail/open/123.gif}
 * 라면 누구든 숫자만 바꿔가며 남의 메일 열람수를 조작할 수 있고, 우리 발송량까지
 * 밖에서 셀 수 있다(연번이라 최대 mail_idx 가 곧 총 발송건수다).
 *
 * <p><b>왜 DB 에 랜덤 토큰을 저장하지 않는가.</b> 그 방법이면 mail_mst 에 토큰 컬럼과
 * 유니크 인덱스가 하나 더 필요한데, 토큰은 mail_idx 하나에서 결정적으로 유도할 수 있어
 * 저장할 정보가 사실상 없다. 그래서 <b>어디에도 저장하지 않는 상태 없는(stateless) HMAC</b>
 * 방식을 쓴다 — 서버 비밀키를 아는 쪽만 유효 토큰을 만들 수 있고, 스키마 변경이 없다.
 *
 * <p>토큰 구조는 고정 길이 18바이트를 base64url(패딩 없음)로 감싼 24글자다.
 * <pre>
 *   [0..7]   mail_idx (big-endian long)
 *   [8..17]  HMAC-SHA256(secret, 앞 8바이트) 의 앞 10바이트
 * </pre>
 * 구분자(.)를 쓰지 않는 이유는 경로가 {@code /mail/open/{token}.gif} 라서다 —
 * 토큰 안에 점이 섞이면 확장자 경계가 어디인지 애매해진다.
 *
 * <p>서명을 10바이트(80비트)로 자른 것은 의도된 절충이다. 이 토큰이 지키는 것은
 * "열람수 위조 방지"뿐이고 인증 수단이 아니다. 80비트면 무차별 대입이 현실적으로
 * 불가능하면서 URL 도 짧게 유지된다.
 */
@Slf4j
public final class MailOpenTokenCodec {

    /** mail_idx(long) 바이트 수. */
    private static final int PAYLOAD_BYTES = 8;

    /** 잘라 쓰는 서명 길이. 80비트면 위조 방어에 충분하고 URL 이 짧게 유지된다. */
    private static final int SIGNATURE_BYTES = 10;

    private static final int TOKEN_BYTES = PAYLOAD_BYTES + SIGNATURE_BYTES;

    /** base64url 로 감싼 뒤의 글자 수. 길이가 다르면 디코딩을 시도조차 하지 않는다. */
    private static final int TOKEN_CHARS = 24;

    private static final String HMAC_ALGORITHM = "HmacSHA256";

    private static final Base64.Encoder ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder DECODER = Base64.getUrlDecoder();

    private MailOpenTokenCodec() {}

    /**
     * mail_idx → 토큰.
     *
     * @param secret 서버 비밀키. 비어 있으면 토큰을 만들 수 없다(호출부가 픽셀을 생략해야 한다).
     */
    public static String encode(long mailIdx, String secret) {
        byte[] payload = ByteBuffer.allocate(PAYLOAD_BYTES).putLong(mailIdx).array();
        byte[] signature = sign(payload, secret);

        byte[] token = new byte[TOKEN_BYTES];
        System.arraycopy(payload, 0, token, 0, PAYLOAD_BYTES);
        System.arraycopy(signature, 0, token, PAYLOAD_BYTES, SIGNATURE_BYTES);
        return ENCODER.encodeToString(token);
    }

    /**
     * 토큰 → mail_idx. 서명이 맞지 않으면 {@code null}.
     *
     * <p>예외를 던지지 않고 null 을 돌려주는 이유: 이 값을 쓰는 곳은 인증 없이 열려 있는
     * 픽셀 엔드포인트 하나뿐이고, 거기서는 <b>어떤 실패든 똑같이 1x1 GIF 를 돌려줘야</b>
     * 한다. 오류 응답을 구분해 주면 그 차이가 토큰 유효성 판별기(oracle)가 된다.
     */
    public static Long decode(String token, String secret) {
        if (token == null || token.length() != TOKEN_CHARS) {
            return null;
        }
        byte[] raw;
        try {
            raw = DECODER.decode(token);
        } catch (IllegalArgumentException e) {
            // base64url 이 아닌 값. 흔한 스캐너 트래픽이라 로그를 남기지 않는다.
            return null;
        }
        if (raw.length != TOKEN_BYTES) {
            return null;
        }

        byte[] payload = new byte[PAYLOAD_BYTES];
        System.arraycopy(raw, 0, payload, 0, PAYLOAD_BYTES);
        byte[] presented = new byte[SIGNATURE_BYTES];
        System.arraycopy(raw, PAYLOAD_BYTES, presented, 0, SIGNATURE_BYTES);

        byte[] expected = sign(payload, secret);
        // MessageDigest.isEqual 은 상수 시간 비교다. Arrays.equals 는 첫 불일치에서
        // 빠져나와 응답 시간으로 서명을 한 바이트씩 맞춰 볼 여지를 준다.
        if (!MessageDigest.isEqual(expected, presented)) {
            return null;
        }
        long mailIdx = ByteBuffer.wrap(payload).getLong();
        return mailIdx > 0 ? mailIdx : null;
    }

    /** HMAC-SHA256 앞 {@link #SIGNATURE_BYTES} 바이트. */
    private static byte[] sign(byte[] payload, String secret) {
        if (secret == null || secret.isBlank()) {
            // 빈 키로 HMAC 을 만들면 누구나 같은 값을 재현할 수 있어 서명의 의미가 사라진다.
            throw new IllegalStateException("추적픽셀 서명 키가 설정되지 않았습니다.");
        }
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM));
            byte[] full = mac.doFinal(payload);
            byte[] truncated = new byte[SIGNATURE_BYTES];
            System.arraycopy(full, 0, truncated, 0, SIGNATURE_BYTES);
            return truncated;
        } catch (java.security.GeneralSecurityException e) {
            // HmacSHA256 은 JDK 표준이라 실제로 도달하지 않는다.
            throw new IllegalStateException("추적픽셀 토큰 서명에 실패했습니다.", e);
        }
    }
}
