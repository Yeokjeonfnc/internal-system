package com.yeokjeon.erp.mail.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yeokjeon.erp.mail.dto.MailEventLogInsertParam;
import com.yeokjeon.erp.mail.dto.resend.ResendWebhookDataDto;
import com.yeokjeon.erp.mail.dto.resend.ResendWebhookEventDto;
import com.yeokjeon.erp.mail.mapper.MailEventLogMapper;
import com.yeokjeon.erp.mail.mapper.MailMstMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * 배달 상태 이벤트 적재 + 상태 캐시 갱신.
 *
 * <p>이벤트를 append-only 로 쌓고 {@code mail_mst.last_status} 는 파생 캐시로만 두는 이유는
 * 마이그레이션 주석 그대로다 — delivered 보다 opened 가 먼저 도착하고, 수신자마다 결과가
 * 갈리고, opened/clicked 는 반복 발생한다. 단일 상태 컬럼으로는 표현할 수 없다.
 *
 * <p>그래서 캐시 갱신에 <b>서열</b>을 둔다. 늦게 도착한 {@code sent} 가 이미 기록된
 * {@code delivered} 를 덮어써 "보내는 중"으로 되돌리면 화면이 거짓말을 하게 된다.
 * 실패 계열(bounced/complained/failed/suppressed)만 서열 90 으로 항상 덮어쓴다 —
 * 사용자가 반드시 알아야 하는 상태이기 때문이다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailEventService {

    /** Resend 이벤트 타입 접두. 원장(mail_webhook_log)은 원문을 보존하고 여기서만 뗀다. */
    private static final String EVENT_PREFIX = "email.";

    /**
     * {@code last_status} 갱신 서열. 여기 없는 이벤트는 0 이라 기존 상태를 덮어쓰지 않는다
     * (Resend 가 새 이벤트를 추가해도 화면 상태가 뒤죽박죽되지 않는다).
     */
    private static final Map<String, Integer> STATUS_RANK = Map.ofEntries(
            Map.entry("scheduled", 10),
            Map.entry("sent", 20),
            Map.entry("delivery_delayed", 30),
            Map.entry("delivered", 40),
            Map.entry("opened", 50),
            Map.entry("clicked", 60),
            Map.entry("bounced", 90),
            Map.entry("complained", 90),
            Map.entry("failed", 90),
            Map.entry("suppressed", 90));

    private static final int EVENT_TYPE_MAX = 40;
    private static final int RECIPIENT_MAX = 320;
    private static final int RESEND_ID_MAX = 100;
    private static final int ERR_MAX = 500;

    private final MailEventLogMapper mailEventLogMapper;
    private final MailMstMapper mailMstMapper;
    private final ObjectMapper objectMapper;

    /**
     * 이벤트 1건 적재 + 상태 반영.
     *
     * @return 새로 적재됐으면 true, 같은 {@code svix_id} 가 이미 있어 무시했으면 false
     */
    @Transactional
    public boolean recordEvent(ResendWebhookEventDto event, String svixId) {
        if (event == null || !StringUtils.hasText(event.type())) {
            throw new IllegalArgumentException("웹훅 이벤트 타입이 없습니다.");
        }
        ResendWebhookDataDto data = event.data();
        String eventType = stripPrefix(event.type());
        String resendEmailId = clip(trimToNull(data == null ? null : data.emailId()), RESEND_ID_MAX);

        // 이벤트가 메일 행보다 먼저 도착할 수 있다(발송 응답 커밋 전에 sent 웹훅이 오는 경우).
        // 그때는 mail_idx 를 비워 두고 나중에 relinkOrphans 가 이어 붙인다.
        Long mailIdx = resendEmailId == null ? null : mailMstMapper.selectIdxByResendEmailId(resendEmailId);

        MailEventLogInsertParam param = new MailEventLogInsertParam();
        param.setMailIdx(mailIdx);
        param.setResendEmailId(resendEmailId);
        param.setEventType(clip(eventType, EVENT_TYPE_MAX));
        param.setRecipient(clip(firstRecipient(data), RECIPIENT_MAX));
        param.setOccurredAt(resolveOccurredAt(event, data));
        param.setDetailJson(buildDetailJson(data));
        param.setSvixId(trimToNull(svixId));

        int inserted = mailEventLogMapper.insert(param);
        if (inserted == 0) {
            // ON CONFLICT (svix_id) DO NOTHING — 같은 웹훅이 두 번 온 것이므로 상태도 건드리지 않는다.
            log.debug("중복 이벤트 무시 type={}", eventType);
            return false;
        }

        if (mailIdx != null) {
            applyStatus(mailIdx, eventType, param.getOccurredAt(), resendEmailId, data);
        }
        return true;
    }

    /**
     * 메일 행보다 먼저 도착해 {@code mail_idx} 가 비어 있는 이벤트를 이어 붙인다.
     *
     * @return 연결된 건수
     */
    @Transactional
    public int relinkOrphans(int limit) {
        int batch = limit <= 0 ? 100 : Math.min(limit, 1000);
        int relinked = mailEventLogMapper.relinkOrphans(batch);
        if (relinked > 0) {
            log.info("고아 메일 이벤트 {}건 재연결", relinked);
        }
        return relinked;
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    /**
     * 상태 캐시 갱신.
     *
     * <p>{@code received} 는 last_status 에 쓰지 않는다 — 수신 메일에는 "배달 상태"라는
     * 개념이 없고, 발송 메일의 상태 표시와 같은 칸을 쓰면 화면이 혼란스러워진다.
     */
    private void applyStatus(long mailIdx, String eventType, OffsetDateTime occurredAt,
                             String resendEmailId, ResendWebhookDataDto data) {
        if ("received".equals(eventType)) {
            return;
        }
        int rank = STATUS_RANK.getOrDefault(eventType, 0);
        if (rank > 0) {
            mailMstMapper.updateLastStatus(mailIdx, eventType, occurredAt, rank);
        }

        switch (eventType) {
            case "sent" -> // 실제로 나간 시각이 확정된 순간. 목록 정렬 기준(mail_at)을 이때 맞춘다.
                    mailMstMapper.updateSendSent(mailIdx, clip(resendEmailId, RESEND_ID_MAX), occurredAt);
            case "delivered" ->
                // 이미 SENT 지만 sent 웹훅을 놓쳤을 수 있다. mail_at 은 null 로 넘겨 건드리지 않는다
                // (배달 완료 시각으로 정렬이 흔들리면 보낸 순서가 뒤바뀐다).
                    mailMstMapper.updateSendSent(mailIdx, clip(resendEmailId, RESEND_ID_MAX), null);
            case "bounced", "failed" ->
                // 확정 실패다. updateSendFailed 를 부르면 안 된다 — 이 시점의 행은 send_status='SENT',
                // send_try_cnt=1 이라 그쪽의 임계값 분기가 상태를 QUEUED 로 되돌리고, 백오프가 지나면
                // 워커가 '반송된 주소로 재발송'한다. 바운스는 시도 횟수와 무관하게 FAILED 로 굳힌다.
                    mailMstMapper.markSendBounced(mailIdx, clip(failureReason(eventType, data), ERR_MAX));
            default -> {
                // delivery_delayed / opened / clicked / complained 등은 last_status 만 남긴다.
                // send_status 를 바꾸면 "발송 성공"이라는 사실이 지워진다.
            }
        }
    }

    /**
     * 이벤트 발생 시각.
     *
     * <p>기본은 페이로드 <b>바깥</b>의 {@code created_at} 이다(웹훅 도착 순서는 보장되지 않으므로
     * 정렬은 이 값으로 한다 — 마이그레이션 주석). 다만 {@code email.clicked} 는 클릭 시각이
     * {@code data.click.timestamp} 에 따로 오고 그쪽이 실제 행동 시각이라 우선한다.
     */
    private static OffsetDateTime resolveOccurredAt(ResendWebhookEventDto event, ResendWebhookDataDto data) {
        if (data != null && data.click() != null && data.click().timestamp() != null) {
            return data.click().timestamp();
        }
        if (event.createdAt() != null) {
            return event.createdAt();
        }
        if (data != null && data.createdAt() != null) {
            return data.createdAt();
        }
        // occurred_at 은 NOT NULL 이다. 시각을 못 얻어도 이벤트는 남겨야 하므로 수신 시각으로 채운다.
        return OffsetDateTime.now();
    }

    /**
     * {@code detail} jsonb 에 남길 상세.
     *
     * <p>원문 전체를 넣지 않는 이유: 같은 원문이 {@code mail_webhook_log.payload} 에 이미
     * 통째로 보존돼 있다. 여기에는 화면 타임라인이 실제로 읽는 조각만 넣어 중복을 줄인다.
     */
    private String buildDetailJson(ResendWebhookDataDto data) {
        if (data == null) {
            return null;
        }
        Map<String, Object> detail = new LinkedHashMap<>();
        if (data.bounce() != null) {
            detail.put("bounce", data.bounce());
        }
        if (data.click() != null) {
            detail.put("click", data.click());
        }
        if (data.failed() != null) {
            detail.put("failed", data.failed());
        }
        if (data.to() != null && !data.to().isEmpty()) {
            detail.put("to", data.to());
        }
        if (StringUtils.hasText(data.subject())) {
            detail.put("subject", data.subject());
        }
        if (detail.isEmpty()) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(detail);
        } catch (JsonProcessingException e) {
            // 상세를 못 남겨도 이벤트 자체는 기록돼야 한다.
            log.warn("메일 이벤트 상세 직렬화 실패 — detail 을 비운 채 진행합니다.", e);
            return null;
        }
    }

    private static String failureReason(String eventType, ResendWebhookDataDto data) {
        if (data != null) {
            if (data.failed() != null && StringUtils.hasText(data.failed().reason())) {
                return data.failed().reason();
            }
            if (data.bounce() != null && StringUtils.hasText(data.bounce().message())) {
                return data.bounce().message();
            }
        }
        return "bounced".equals(eventType) ? "수신 서버가 메일을 반송했습니다." : "메일 발송에 실패했습니다.";
    }

    private static String firstRecipient(ResendWebhookDataDto data) {
        if (data == null) {
            return null;
        }
        List<String> to = data.to();
        if (to == null || to.isEmpty()) {
            return null;
        }
        for (String value : to) {
            if (StringUtils.hasText(value)) {
                return value.trim();
            }
        }
        return null;
    }

    private static String stripPrefix(String type) {
        String value = type.trim().toLowerCase(Locale.ROOT);
        return value.startsWith(EVENT_PREFIX) ? value.substring(EVENT_PREFIX.length()) : value;
    }

    private static String clip(String value, int max) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        return trimmed.length() <= max ? trimmed : trimmed.substring(0, max);
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
