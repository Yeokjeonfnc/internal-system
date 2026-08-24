package com.yeokjeon.erp.mail.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.dto.MailWebhookLogJdbcRow;
import com.yeokjeon.erp.mail.dto.resend.ResendWebhookEventDto;
import com.yeokjeon.erp.mail.mapper.MailWebhookLogMapper;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Locale;

/**
 * 웹훅 1건의 처리 흐름을 조립한다(서명 검증이 끝난 뒤부터).
 *
 * <p>멱등성의 1차 방어선은 {@code mail_webhook_log.svix_id} PRIMARY KEY 다.
 * Resend 는 at-least-once 배달이고 중복 제거 키로 {@code svix-id} 헤더를 지정한다.
 * 같은 이벤트의 모든 재시도에서 이 값이 동일하므로, 원장 INSERT 가 0건이면
 * 이미 처리한 전달이라는 뜻이고 아무 것도 다시 하지 않는다.
 * (2차 방어선은 {@code mail_mst.resend_email_id} UNIQUE — 재동기화 배치와 웹훅이
 * 같은 메일을 동시에 넣는 경우까지 막는다.)
 *
 * <p><b>왜 이 메서드에 {@code @Transactional} 을 붙이지 않는가.</b>
 * 요구사항이 "처리 중 예외가 나도 원장에 FAILED 로 기록하고 200 을 반환"이다.
 * 그런데 하나의 트랜잭션 안에서 {@code @Transactional} 인 하위 서비스가 예외를 던지면
 * 스프링이 그 트랜잭션을 rollback-only 로 표시해 버려, 예외를 잡아서 FAILED 를 써도
 * 커밋 시점에 {@code UnexpectedRollbackException} 이 나고 원장 자체가 사라진다.
 * 그래서 (1) 원장 INSERT, (2) 이벤트 처리, (3) 상태 표시를 각각 독립된 짧은 트랜잭션으로
 * 나눠 돌린다. 각 단계는 여전히 트랜잭션 안에서 실행된다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailWebhookService {

    /** 수신 메일 이벤트만 별도 경로(메타 적재)를 탄다. */
    private static final String TYPE_RECEIVED = "email.received";
    /** 우리가 다루는 이벤트군. 그 밖(contact.*, domain.* 등)은 SKIP 으로 남긴다. */
    private static final String EMAIL_EVENT_PREFIX = "email.";

    private static final int EVENT_TYPE_MAX = 40;
    private static final int RESEND_ID_MAX = 100;
    private static final int ERROR_MSG_MAX = 1000;
    private static final int MAX_BATCH = 200;

    private final MailWebhookLogMapper mailWebhookLogMapper;
    private final MailReceiveService mailReceiveService;
    private final MailEventService mailEventService;
    private final ResendProperties properties;
    private final ObjectMapper objectMapper;
    private final PlatformTransactionManager transactionManager;

    private TransactionTemplate txTemplate;

    @PostConstruct
    void initTxTemplate() {
        this.txTemplate = new TransactionTemplate(transactionManager);
    }

    /** 처리 결과. 컨트롤러는 어느 값이든 HTTP 200 으로 응답한다. */
    public enum Result {
        PROCESSED, DUPLICATE, SKIPPED, FAILED
    }

    /**
     * 서명 검증이 끝난 웹훅 1건을 처리한다. DB 작업만 하고 외부 호출은 하지 않는다.
     *
     * @param svixId  {@code svix-id} 헤더. 중복 판정의 유일한 기준이라 비어 있으면 거부한다.
     * @param rawBody 검증된 원본 요청 본문. 그대로 원장에 보존해야 재처리가 가능하다.
     */
    public Result handle(String svixId, String rawBody, ResendWebhookEventDto event) {
        String id = trimToNull(svixId);
        if (id == null) {
            // svix-id 없이 받으면 중복 전달을 구분할 방법이 없어 같은 메일이 여러 통 쌓인다.
            throw new IllegalArgumentException("svix-id 헤더가 없어 중복 처리를 막을 수 없습니다.");
        }
        if (event == null || !StringUtils.hasText(event.type())) {
            throw new IllegalArgumentException("웹훅 이벤트 타입이 없습니다.");
        }
        String type = event.type().trim().toLowerCase(Locale.ROOT);
        String resendEmailId = event.data() == null ? null : trimToNull(event.data().emailId());
        // payload 는 jsonb NOT NULL. 본문이 비어 있을 리 없지만 원장이 통째로 실패하지 않게 방어한다.
        String payload = StringUtils.hasText(rawBody) ? rawBody : "{}";

        Integer inserted = txTemplate.execute(status -> mailWebhookLogMapper.insertIfAbsent(
                id, clip(type, EVENT_TYPE_MAX), clip(resendEmailId, RESEND_ID_MAX), payload));
        if (inserted == null || inserted == 0) {
            log.debug("중복 웹훅 전달 무시 type={}", type);
            return Result.DUPLICATE;
        }
        return process(id, type, event);
    }

    /**
     * PENDING/FAILED 로 남은 원장을 재처리한다(워커 전용).
     *
     * <p>웹훅 응답은 언제나 200 이라 Resend 는 재전송하지 않는다. 즉 여기서 다시 돌리지 않으면
     * 그 이벤트는 영영 반영되지 않는다.
     *
     * @return 처리 성공 건수
     */
    public int retryPending(int limit) {
        List<MailWebhookLogJdbcRow> rows = mailWebhookLogMapper.selectPending(
                clampBatch(limit), properties.getSync().getMaxTryCnt());
        int processed = 0;
        for (MailWebhookLogJdbcRow row : rows) {
            try {
                ResendWebhookEventDto event =
                        objectMapper.readValue(row.payload(), ResendWebhookEventDto.class);
                String type = row.eventType() == null
                        ? "" : row.eventType().trim().toLowerCase(Locale.ROOT);
                if (process(row.svixId(), type, event) == Result.PROCESSED) {
                    processed++;
                }
            } catch (Exception e) {
                // 페이로드가 깨져 파싱조차 안 되는 경우. 재시도 횟수를 올려 두면
                // maxTryCnt 를 넘긴 뒤 폴링 대상에서 자연히 빠진다.
                log.warn("웹훅 재처리 실패 type={}", row.eventType(), e);
                markStatus(row.svixId(), "FAILED", clip(rootMessage(e), ERROR_MSG_MAX));
            }
        }
        if (!rows.isEmpty()) {
            log.info("웹훅 재처리 {}/{}건 완료", processed, rows.size());
        }
        return processed;
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    private Result process(String svixId, String type, ResendWebhookEventDto event) {
        try {
            if (TYPE_RECEIVED.equals(type)) {
                // 순서가 중요하다. 메일 행을 먼저 만들어야 이벤트가 mail_idx 에 붙는다.
                // 반대로 하면 고아 이벤트가 되어 relinkOrphans 를 한 바퀴 더 돌아야 한다.
                long mailIdx = mailReceiveService.ingestReceived(event);
                mailEventService.recordEvent(event, svixId);
                markStatus(svixId, "DONE", null);
                log.info("수신 웹훅 처리 완료 mailIdx={}", mailIdx);
                return Result.PROCESSED;
            }
            if (type.startsWith(EMAIL_EVENT_PREFIX)) {
                mailEventService.recordEvent(event, svixId);
                markStatus(svixId, "DONE", null);
                return Result.PROCESSED;
            }
            // 우리가 쓰지 않는 이벤트(contact.*, domain.* 등). 원장에는 남겨 두되
            // 재처리 대상에서는 빼야 하므로 SKIP 으로 확정한다.
            markStatus(svixId, "SKIP", null);
            log.debug("처리 대상이 아닌 웹훅 type={}", type);
            return Result.SKIPPED;
        } catch (RuntimeException e) {
            // 여기서 예외를 삼키는 것이 핵심이다. 컨트롤러까지 올라가면 Resend 가 5xx 로 보고
            // 같은 이벤트를 계속 재전송해 폭주한다. 원장에 사유를 남기고 워커가 다시 돌린다.
            log.warn("웹훅 처리 실패 type={}", type, e);
            markStatus(svixId, "FAILED", clip(rootMessage(e), ERROR_MSG_MAX));
            return Result.FAILED;
        }
    }

    /** 원장 상태는 본 처리와 별개 트랜잭션으로 남긴다(본 처리가 롤백돼도 사유는 남아야 한다). */
    private void markStatus(String svixId, String processStatus, String errorMsg) {
        try {
            txTemplate.executeWithoutResult(status ->
                    mailWebhookLogMapper.markStatus(svixId, processStatus, errorMsg));
        } catch (RuntimeException e) {
            // 상태 기록 실패로 웹훅 응답까지 망가뜨리지 않는다.
            log.warn("웹훅 원장 상태 기록 실패 status={}", processStatus, e);
        }
    }

    private static int clampBatch(int limit) {
        return limit <= 0 ? 1 : Math.min(limit, MAX_BATCH);
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

    private static String rootMessage(Throwable e) {
        Throwable cursor = e;
        while (cursor.getCause() != null && cursor.getCause() != cursor) {
            cursor = cursor.getCause();
        }
        String message = cursor.getMessage();
        return StringUtils.hasText(message) ? message : cursor.getClass().getSimpleName();
    }
}
