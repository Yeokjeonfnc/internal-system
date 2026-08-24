package com.yeokjeon.erp.mail.worker;

import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.service.MailEventService;
import com.yeokjeon.erp.mail.service.MailWebhookService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 메일 정합성 보정 워커 — 웹훅 원장 재처리와 미아 이벤트 연결.
 *
 * <p>고치는 문제는 두 가지다.
 *
 * <ol>
 *   <li><b>미처리 원장</b> — 컨트롤러는 처리에 실패해도 Resend 에는 200 을 준다(4xx 를 주면
 *       재시도가 폭주해 정상 이벤트까지 밀린다). 대신 {@code mail_webhook_log} 에
 *       PENDING/FAILED 로 남겨 두고 여기서 다시 처리한다.
 *   <li><b>미아 이벤트</b> — Resend 는 발송 응답보다 delivered/bounced 웹훅을 먼저 보낼 때가
 *       있다. 그러면 {@code resend_email_id} 에 대응하는 {@code mail_mst} 행이 아직 없어
 *       이벤트가 {@code mail_idx=NULL} 로 쌓인다. 나중에 본체가 생기면 여기서 이어 붙인다.
 * </ol>
 *
 * <p>다른 워커와 달리 외부 API 를 쓰지 않아 <b>API 키가 없어도 돌아야 한다</b> — 키 없이도
 * 웹훅 수신은 가능하고(서명만 맞으면 된다), 그 이력 정리는 계속 필요하기 때문이다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "resend.sync", name = "enabled", havingValue = "true")
public class MailMaintenanceWorker {

    private final MailWebhookService mailWebhookService;
    private final MailEventService mailEventService;
    private final ResendProperties properties;

    /**
     * 주기가 5분으로 가장 길다. 보정 작업이라 실시간성이 필요 없고, 매 분 돌면 다른 워커의
     * 스케줄러 슬롯만 잡아먹는다.
     */
    @Scheduled(
            initialDelay = 120_000,
            fixedDelayString = "${resend.sync.maintenance-interval-ms:300000}")
    public void maintain() {
        int batchSize = properties.getSync().getBatchSize();

        // 두 작업을 각각 try 로 감싼다 — 앞이 실패해도 뒤는 돌아야 한다.
        try {
            int retried = mailWebhookService.retryPending(batchSize);
            if (retried > 0) {
                log.info("메일 유지보수 워커: 웹훅 원장 {}건 재처리", retried);
            }
        } catch (Exception e) {
            log.error("메일 웹훅 원장 재처리 실패", e);
        }

        try {
            int relinked = mailEventService.relinkOrphans(batchSize);
            if (relinked > 0) {
                log.info("메일 유지보수 워커: 미아 이벤트 {}건 연결", relinked);
            }
        } catch (Exception e) {
            log.error("메일 미아 이벤트 연결 실패", e);
        }
    }
}
