package com.yeokjeon.erp.mail.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Resend 메일 연동 설정(mal001).
 *
 * <p>{@code DaouOfficeProperties} 와 같은 방식 — 키는 저장소에 두지 않고 환경변수로
 * 주입하며, 기본값은 전부 빈 문자열이다. <b>키가 없어도 앱은 정상 기동해야 한다.</b>
 * 현장 서버는 메일 없이도 가맹점·활동·게시판이 돌아야 하기 때문에, 키 미설정은
 * 예외가 아니라 "메일 기능만 비활성"으로 처리한다({@link #isApiKeyConfigured()} 을
 * 호출부가 먼저 확인하고 조용히 건너뛴다).
 */
@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "resend")
public class ResendProperties {

    private String apiBaseUrl = "https://api.resend.com";
    private String apiKey = "";
    private String webhookSecret = "";
    private String fromEmail = "";
    private String fromName = "역전에프앤씨";

    /**
     * 요청 본문의 {@code fromEmail} 로 허용할 주소 목록(콤마 구분).
     *
     * <p>비워 두면 {@link #fromEmail} 하나만 허용한다 — 이게 기본이자 안전한 상태다.
     * 부서별 발신 주소가 필요할 때만 명시적으로 늘린다.
     *
     * <p><b>왜 목록이 필요한가.</b> Resend 는 "검증된 도메인인가"만 본다. 즉 자사 도메인
     * 안의 임의 로컬파트(ceo@, finance@ …)는 전부 통과한다. 클라이언트가 보낸 주소를
     * 그대로 쓰면 mal001 생성 권한만 있는 사원이 회사 DKIM 서명이 붙은 대표이사 명의
     * 메일을 외부로 보낼 수 있다. 그래서 서버가 가진 목록으로만 대조한다.
     */
    private List<String> allowedFromEmails = new ArrayList<>();

    private int timeoutSeconds = 15;

    /** 본문 저장 상한. 이 크기를 넘으면 잘라 저장하고 {@code truncated_yn='Y'} 로 표시한다. */
    private int bodyMaxBytes = 1_048_576;

    /** 검색용 평문 상한. 본문 전체를 색인하면 tsvector 가 비대해져 INSERT 가 느려진다. */
    private int searchMaxBytes = 102_400;

    private int snippetMaxChars = 300;
    private long attachmentMaxBytes = 26_214_400L;

    /**
     * 수신확인 추적픽셀 URL 의 앞부분(예: {@code https://erp.example.com/api}).
     *
     * <p>비워 두면 픽셀을 아예 심지 않는다 — 잘못된 주소로 심으면 수신자 본문에
     * 깨진 이미지만 남고 수신확인은 영영 안 잡힌다. "조용히 안 되는" 상태를 만들지 않으려고
     * 설정이 없으면 기능 자체를 끈다.
     *
     * <p>반드시 <b>외부에서 접근 가능한</b> 주소여야 한다. localhost 를 넣으면 수신자
     * 메일 클라이언트가 자기 자신을 호출하게 된다.
     *
     * <p>application.yml 에 키가 없어도 환경변수 {@code RESEND_TRACKING_BASE_URL} 로
     * 바인딩된다(스프링 완화 바인딩).
     */
    private String trackingBaseUrl = "";

    /**
     * 추적픽셀 토큰 서명 키.
     *
     * <p>직접 지정하지 않으면 {@link #webhookSecret} → {@link #apiKey} 순으로 대신 쓴다
     * ({@link #resolveTrackingSecret()}). 별도 환경변수를 하나 더 늘리지 않고도 동작하게
     * 하려는 절충인데, <b>키가 바뀌면 이미 발송된 메일의 픽셀 토큰이 전부 무효가 된다</b>.
     * 그래서 운영에서는 {@code RESEND_TRACKING_SECRET} 을 명시적으로 고정해 두는 편이 낫다.
     */
    private String trackingSecret = "";

    private final Sync sync = new Sync();
    private final Webhook webhook = new Webhook();

    /** 키가 있어야 Resend 를 호출한다. 없으면 송수신 기능만 비활성. */
    public boolean isApiKeyConfigured() {
        return apiKey != null && !apiKey.isBlank();
    }

    /** 웹훅 서명 시크릿 설정 여부. 없으면 서명 검증을 할 수 없어 웹훅을 거부한다. */
    public boolean isWebhookConfigured() {
        return webhookSecret != null && !webhookSecret.isBlank();
    }

    /**
     * 추적픽셀 토큰에 쓸 서명 키를 정한다.
     *
     * <p>전용 키 → 웹훅 시크릿 → API 키 순서. 셋 다 없으면 빈 문자열이고,
     * 그때는 {@link #isTrackingConfigured()} 가 false 라 픽셀을 심지 않는다.
     */
    public String resolveTrackingSecret() {
        if (trackingSecret != null && !trackingSecret.isBlank()) {
            return trackingSecret.trim();
        }
        if (webhookSecret != null && !webhookSecret.isBlank()) {
            return webhookSecret.trim();
        }
        return apiKey == null ? "" : apiKey.trim();
    }

    /**
     * 수신확인 기능을 쓸 수 있는 상태인가.
     *
     * <p>주소와 키가 <b>둘 다</b> 있어야 한다. 하나만 있으면 토큰은 만들어지는데 호출될 수
     * 없거나(주소 없음), 주소는 있는데 토큰 검증이 불가능한(키 없음) 반쪽 상태가 된다.
     */
    public boolean isTrackingConfigured() {
        return trackingBaseUrl != null && !trackingBaseUrl.isBlank()
                && !resolveTrackingSecret().isEmpty();
    }

    /**
     * 추적픽셀 URL 을 만든다. 끝의 슬래시 유무에 상관없이 같은 결과가 나오게 정규화한다
     * — {@code .../api} 와 {@code .../api/} 가 서로 다른 URL 이 되면 토큰은 같은데
     * 본문만 달라져 디버깅이 어려워진다.
     */
    public String buildTrackingPixelUrl(String token) {
        String base = trackingBaseUrl == null ? "" : trackingBaseUrl.trim();
        while (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
        return base + "/mail/open/" + token + ".gif";
    }

    /**
     * 발신 주소로 써도 되는 주소인지 본다(대소문자 무시).
     *
     * <p>기준은 {@link #fromEmail} + {@link #allowedFromEmails} 다. 클라이언트가 보낸 값을
     * 이 목록과 대조하지 않으면 임의 발신자 사칭이 열린다.
     */
    public boolean isFromEmailAllowed(String email) {
        if (email == null || email.isBlank()) {
            return false;
        }
        String target = email.trim();
        if (fromEmail != null && fromEmail.trim().equalsIgnoreCase(target)) {
            return true;
        }
        if (allowedFromEmails == null) {
            return false;
        }
        for (String allowed : allowedFromEmails) {
            if (allowed != null && allowed.trim().equalsIgnoreCase(target)) {
                return true;
            }
        }
        return false;
    }

    @Getter
    @Setter
    public static class Sync {

        /**
         * 스케줄 워커 활성화 여부.
         *
         * <p>현장(3001)·운영(3011) 인스턴스가 같은 코드로 동시에 뜨면 워커가 두 배로 돌아
         * Resend rate limit(팀 단위 10 req/s)을 갉아먹고, 같은 메일 본문을 두 번 받아간다.
         * 그래서 기본은 꺼 두고 <b>한 인스턴스에서만</b> {@code RESEND_SYNC_ENABLED=true} 로 켠다.
         */
        private boolean enabled = false;

        private long bodyIntervalMs = 2_000;
        private long sendIntervalMs = 1_500;
        private long attachmentIntervalMs = 4_000;
        private long maintenanceIntervalMs = 300_000;
        private int batchSize = 20;
        private int maxTryCnt = 5;
        private int backoffMinutes = 5;
    }

    @Getter
    @Setter
    public static class Webhook {

        /** Svix 규격의 재전송 공격 방지 허용 오차(±5분). */
        private int toleranceSeconds = 300;

        /**
         * 서명 검증 사용 여부.
         *
         * <p>웹훅 경로는 {@code AuthTokenFilter.PUBLIC_PATHS} 라 로그인 토큰이 없다.
         * 서명이 <b>유일한</b> 방어선이므로 운영에서는 절대 false 로 두지 말 것.
         */
        private boolean verifySignature = true;
    }
}
