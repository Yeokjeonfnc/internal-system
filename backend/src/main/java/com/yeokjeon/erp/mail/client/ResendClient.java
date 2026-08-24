package com.yeokjeon.erp.mail.client;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.dto.resend.ResendAttachmentListDto;
import com.yeokjeon.erp.mail.dto.resend.ResendAttachmentMetaDto;
import com.yeokjeon.erp.mail.dto.resend.ResendErrorDto;
import com.yeokjeon.erp.mail.dto.resend.ResendReceivedEmailDto;
import com.yeokjeon.erp.mail.dto.resend.ResendSendRequestDto;
import com.yeokjeon.erp.mail.dto.resend.ResendSendResponseDto;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpRequest;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import org.springframework.util.StringUtils;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

/**
 * Resend HTTP API 어댑터.
 *
 * <p>이 클래스만 Resend 를 안다. 서비스 계층은 여기서 만든 DTO 와
 * {@link ResendApiException} 만 보고 동작하므로, 나중에 다른 메일 게이트웨이로
 * 바꿔도 서비스 코드는 그대로 둘 수 있다.
 *
 * <p>공유 {@code RestClient} 빈을 만들지 않고 생성자에서 직접 만든다
 * ({@code AddressGeocodingService} 선례). 베이스 URL·타임아웃·인증 방식이
 * 이 API 전용이라 다른 곳에서 재사용할 여지가 없고, 공유 빈으로 두면
 * 남이 인터셉터를 끼워 넣어 Authorization 헤더가 엉뚱한 곳으로 새 나갈 수 있다.
 *
 * <p>키가 비어 있어도 빈 생성은 성공한다 — 앱은 정상 기동하고 메일 기능만 죽는다.
 * 호출부는 {@link #isEnabled()} 로 먼저 걸러야 하고, 그냥 부르면
 * "키가 없다"는 분명한 메시지를 담은 {@link ResendApiException} 이 난다.
 */
@Slf4j
@Component
public class ResendClient {

    /** 같은 메일을 두 번 보내지 않기 위한 헤더. Resend 는 24시간 동안 이 키를 기억한다. */
    private static final String HEADER_IDEMPOTENCY_KEY = "Idempotency-Key";
    /** 오류 메시지를 DB(varchar 500)와 로그에 넣기 전에 자를 길이. */
    private static final int ERROR_MESSAGE_MAX = 400;
    /** 첨부 목록 API 한 페이지 최대치. 한 메일에 100개를 넘는 첨부는 실무에서 없다. */
    private static final int ATTACHMENT_PAGE_SIZE = 100;

    private final ResendProperties properties;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;

    public ResendClient(ResendProperties properties, ObjectMapper objectMapper) {
        this.properties = properties;
        this.objectMapper = objectMapper;

        // JDK 기본 HttpURLConnection 기반. 새 의존성 없이 타임아웃만 걸면 충분하다
        // (커넥션 풀이 필요할 만큼 호출량이 많지 않다 — 무료 플랜 상한이 하루 100통).
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        int timeoutMs = Math.max(1, properties.getTimeoutSeconds()) * 1000;
        factory.setConnectTimeout(timeoutMs);
        factory.setReadTimeout(timeoutMs);

        this.restClient = RestClient.builder()
                .baseUrl(properties.getApiBaseUrl())
                .requestFactory(factory)
                // 스프링이 구성한 ObjectMapper 를 그대로 쓴다. 기본 컨버터는 자체 ObjectMapper 를
                // 새로 만들어서 application.yml 의 jackson 설정(Asia/Seoul 등)이 반영되지 않는다.
                .messageConverters(converters -> {
                    converters.removeIf(c -> c instanceof MappingJackson2HttpMessageConverter);
                    converters.add(new MappingJackson2HttpMessageConverter(objectMapper));
                })
                .build();
    }

    /** 키가 설정돼 있어야 true. false 면 호출부가 조용히 건너뛴다(앱은 정상 기동). */
    public boolean isEnabled() {
        return properties.isApiKeyConfigured();
    }

    /**
     * POST /emails — 메일 발송.
     *
     * @param idempotencyKey {@code "mail-" + mailIdx}. 워커가 같은 메일을 재시도해도
     *                       Resend 가 24시간 동안 중복 발송을 막아 준다.
     * @return Resend 가 부여한 email id
     */
    public String sendEmail(ResendSendRequestDto request, String idempotencyKey) {
        requireEnabled();
        if (request == null) {
            throw new IllegalArgumentException("발송 요청 본문이 비어 있습니다.");
        }
        ResendSendResponseDto response = call(() -> restClient.post()
                .uri("/emails")
                .header(HttpHeaders.AUTHORIZATION, bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON)
                .headers(headers -> {
                    if (StringUtils.hasText(idempotencyKey)) {
                        headers.set(HEADER_IDEMPOTENCY_KEY, idempotencyKey.trim());
                    }
                })
                .body(request)
                .retrieve()
                .onStatus(HttpStatusCode::isError, this::raise)
                .body(ResendSendResponseDto.class));

        if (response == null || !StringUtils.hasText(response.id())) {
            // id 가 없으면 우리 DB 에 resend_email_id 를 못 남겨 이후 웹훅과 연결이 끊긴다.
            // 성공으로 처리하면 안 된다.
            throw new ResendApiException(502, "empty_response", "Resend 응답에 email id 가 없습니다.");
        }
        return response.id();
    }

    /**
     * PATCH /emails/{id} — 예약 메일의 <b>발송 시각만</b> 변경.
     *
     * <p><b>Resend 는 이 API 로 내용을 바꿀 수 없다.</b> 본문·수신자·제목을 고치려면
     * {@link #cancelScheduled(String)} 로 취소한 뒤 새로 작성해 발송해야 한다.
     * 그래서 화면 흐름도 "예약 수정"이 아니라 "예약 취소 → 다시 작성"이다.
     *
     * <p>이미 발송된(예약 시각이 지난) 메일에 부르면 Resend 가 4xx 를 준다 —
     * 재시도해도 결과가 같으므로 호출부는 그대로 실패로 확정해야 한다.
     *
     * @param scheduledAt ISO-8601 문자열
     */
    public void updateScheduledAt(String resendEmailId, String scheduledAt) {
        requireEnabled();
        String id = requireText(resendEmailId, "resendEmailId");
        String at = requireText(scheduledAt, "scheduledAt");
        call(() -> restClient.patch()
                .uri("/emails/{id}", id)
                .header(HttpHeaders.AUTHORIZATION, bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON)
                .body(Map.of("scheduled_at", at))
                .retrieve()
                .onStatus(HttpStatusCode::isError, this::raise)
                .body(String.class));
    }

    /**
     * POST /emails/{id}/cancel — 예약 발송 취소.
     *
     * <p>아직 나가지 않은 예약 메일만 취소된다. 이미 발송된 메일에 부르면 4xx 가 오는데,
     * 그건 "취소 실패"가 아니라 "취소할 것이 없다"는 뜻이므로 호출부가 사용자에게
     * 그렇게 설명해야 한다.
     *
     * <p>Idempotency-Key 를 붙이지 않는다. 취소는 그 자체로 멱등하고(두 번 취소해도
     * 결과가 같다), 키를 붙이면 24시간 안의 재취소 요청이 캐시된 응답만 받아
     * 실제 상태와 어긋날 수 있다.
     */
    public void cancelScheduled(String resendEmailId) {
        requireEnabled();
        String id = requireText(resendEmailId, "resendEmailId");
        call(() -> restClient.post()
                .uri("/emails/{id}/cancel", id)
                .header(HttpHeaders.AUTHORIZATION, bearer())
                .accept(MediaType.APPLICATION_JSON)
                .retrieve()
                .onStatus(HttpStatusCode::isError, this::raise)
                .body(String.class));
    }

    /**
     * GET /emails/receiving/{id}?html_format=cid — 수신 메일 본문·헤더.
     *
     * <p>{@code html_format=cid} 를 반드시 붙인다. 기본값 {@code data_uri} 로 받으면
     * 인라인 이미지가 base64 로 html 안에 통째로 박혀 본문이 수 MB 로 부풀고,
     * {@code mail_att.content_id}/{@code inline_yn} 로 첨부를 따로 관리하는 설계와도 어긋난다.
     */
    public ResendReceivedEmailDto getReceivedEmail(String resendEmailId) {
        requireEnabled();
        String id = requireText(resendEmailId, "resendEmailId");
        return call(() -> restClient.get()
                .uri(builder -> builder
                        .path("/emails/receiving/{id}")
                        .queryParam("html_format", "cid")
                        .build(id))
                .header(HttpHeaders.AUTHORIZATION, bearer())
                .accept(MediaType.APPLICATION_JSON)
                .retrieve()
                .onStatus(HttpStatusCode::isError, this::raise)
                .body(ResendReceivedEmailDto.class));
    }

    /**
     * GET /emails/receiving/{emailId}/attachments — 첨부 메타 목록(단일 페이지).
     *
     * <p>페이지네이션을 따라가지 않는다. 100개를 넘는 첨부가 달린 메일은 실무에 없고,
     * 있더라도 앞 100개만 받는 편이 배치가 무한 루프에 빠지는 것보다 안전하다.
     */
    public List<ResendAttachmentMetaDto> listAttachments(String resendEmailId) {
        requireEnabled();
        String id = requireText(resendEmailId, "resendEmailId");
        ResendAttachmentListDto list = call(() -> restClient.get()
                .uri(builder -> builder
                        .path("/emails/receiving/{id}/attachments")
                        .queryParam("limit", ATTACHMENT_PAGE_SIZE)
                        .build(id))
                .header(HttpHeaders.AUTHORIZATION, bearer())
                .accept(MediaType.APPLICATION_JSON)
                .retrieve()
                .onStatus(HttpStatusCode::isError, this::raise)
                .body(ResendAttachmentListDto.class));
        if (list == null || list.data() == null) {
            return List.of();
        }
        return list.data();
    }

    /**
     * GET /emails/receiving/{emailId}/attachments/{attachmentId} — 단건 첨부 메타.
     *
     * <p>응답의 {@code download_url} 은 1시간 만료 서명 URL 이라 DB 에 저장하지 않고
     * 받자마자 {@link #downloadAttachment(String)} 로 실물을 내려받아야 한다.
     */
    public ResendAttachmentMetaDto getAttachment(String resendEmailId, String attachmentId) {
        requireEnabled();
        String emailId = requireText(resendEmailId, "resendEmailId");
        String attId = requireText(attachmentId, "attachmentId");
        return call(() -> restClient.get()
                .uri(builder -> builder
                        .path("/emails/receiving/{emailId}/attachments/{attId}")
                        .build(emailId, attId))
                .header(HttpHeaders.AUTHORIZATION, bearer())
                .accept(MediaType.APPLICATION_JSON)
                .retrieve()
                .onStatus(HttpStatusCode::isError, this::raise)
                .body(ResendAttachmentMetaDto.class));
    }

    /**
     * 서명된 {@code download_url} 에서 첨부 실물을 받는다.
     *
     * <p>Authorization 헤더를 절대 붙이지 않는다. 이 URL 은 Resend API 도메인이 아니라
     * 오브젝트 스토리지 도메인을 가리키고 서명이 이미 URL 안에 들어 있다. 헤더를 붙이면
     * 우리 API 키를 제3자 호스트로 보내는 꼴이 된다.
     */
    public byte[] downloadAttachment(String downloadUrl) {
        String url = requireText(downloadUrl, "downloadUrl");
        byte[] body = call(() -> restClient.get()
                // 절대 URL 이므로 baseUrl 이 끼어들지 않도록 URI 로 직접 넘긴다.
                .uri(URI.create(url))
                .retrieve()
                .onStatus(HttpStatusCode::isError, this::raise)
                .body(byte[].class));
        if (body == null) {
            return new byte[0];
        }
        // Content-Length 를 신뢰할 수 없는 서명 URL 이 있어 받은 뒤에 크기를 확인한다.
        if (body.length > properties.getAttachmentMaxBytes()) {
            throw new ResendApiException(413, "attachment_too_large",
                    "첨부 파일이 허용 크기를 초과했습니다: " + body.length + " bytes");
        }
        return body;
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    private String bearer() {
        return "Bearer " + properties.getApiKey().trim();
    }

    private void requireEnabled() {
        if (!isEnabled()) {
            // 예외를 던지되 "무엇이 없어서 안 되는지"를 그대로 알려 준다. 호출부(워커·서비스)는
            // 이 메시지를 그대로 화면·로그에 옮기고 앱을 죽이지 않는다.
            throw new ResendApiException(412, "api_key_missing",
                    "Resend API 키가 설정되지 않아 메일 기능을 사용할 수 없습니다. "
                            + "환경변수 RESEND_API_KEY 를 설정한 뒤 백엔드를 재시작해 주세요.");
        }
    }

    private static String requireText(String value, String field) {
        if (!StringUtils.hasText(value)) {
            throw new IllegalArgumentException("필수 값이 비어 있습니다: " + field);
        }
        return value.trim();
    }

    /**
     * 네트워크 계열 예외를 {@link ResendApiException} 으로 통일한다.
     *
     * <p>호출부가 {@code RestClientException} 과 {@code ResendApiException} 두 가지를
     * 따로 다루면 재시도 판정이 두 군데로 갈라진다. 여기서 한 종류로 좁혀 둔다.
     */
    private <T> T call(Supplier<T> action) {
        try {
            return action.get();
        } catch (ResendApiException e) {
            throw e;
        } catch (ResourceAccessException e) {
            // 커넥션 실패·타임아웃. 상대 장애와 성격이 같으므로 재시도 대상(5xx)으로 올린다.
            throw new ResendApiException(503, "network_error",
                    "Resend 연결에 실패했습니다: " + clip(rootMessage(e)));
        } catch (RestClientException e) {
            // 응답 역직렬화 실패 등. 재시도해도 같은 결과일 가능성이 높아 4xx 성격으로 본다.
            throw new ResendApiException(502, "response_error",
                    "Resend 응답을 처리하지 못했습니다: " + clip(rootMessage(e)));
        }
    }

    /** 오류 응답을 {@link ResendApiException} 으로 바꾼다. 응답 본문에는 우리 키가 담기지 않는다. */
    private void raise(HttpRequest request, ClientHttpResponse response) throws IOException {
        int status = response.getStatusCode().value();
        String name = "";
        String message = "";

        byte[] raw = StreamUtils.copyToByteArray(response.getBody());
        if (raw.length > 0) {
            try {
                ResendErrorDto error = objectMapper.readValue(raw, ResendErrorDto.class);
                if (error != null) {
                    name = error.name() == null ? "" : error.name();
                    message = error.message() == null ? "" : error.message();
                }
            } catch (Exception ignored) {
                // JSON 이 아닌 오류 페이지(프록시·게이트웨이)도 온다. 원문 앞부분만 남긴다.
                message = new String(raw, StandardCharsets.UTF_8);
            }
        }
        if (!StringUtils.hasText(message)) {
            message = "Resend 요청이 실패했습니다(HTTP " + status + ").";
        }

        int retryAfter = parseRetryAfter(response.getHeaders());
        // 요청 URL·헤더는 남기지 않는다(경로에 email id 가 있고 헤더에 키가 있다).
        log.warn("Resend API 오류 status={} name={} retryAfter={}s", status, name, retryAfter);
        throw new ResendApiException(status, name, clip(message), retryAfter);
    }

    private static int parseRetryAfter(HttpHeaders headers) {
        if (headers == null) {
            return 0;
        }
        int seconds = parseInt(headers.getFirst("retry-after"));
        if (seconds > 0) {
            return seconds;
        }
        // Resend 는 rate limit 응답에 ratelimit-reset(남은 초)을 함께 준다.
        return parseInt(headers.getFirst("ratelimit-reset"));
    }

    private static int parseInt(String value) {
        if (!StringUtils.hasText(value)) {
            return 0;
        }
        try {
            return Math.max(Integer.parseInt(value.trim()), 0);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private static String rootMessage(Throwable e) {
        Throwable cursor = e;
        while (cursor.getCause() != null && cursor.getCause() != cursor) {
            cursor = cursor.getCause();
        }
        String message = cursor.getMessage();
        return StringUtils.hasText(message) ? message : cursor.getClass().getSimpleName();
    }

    private static String clip(String value) {
        if (value == null) {
            return "";
        }
        String trimmed = value.trim().replaceAll("\\s+", " ");
        return trimmed.length() <= ERROR_MESSAGE_MAX
                ? trimmed
                : trimmed.substring(0, ERROR_MESSAGE_MAX) + "…";
    }
}
