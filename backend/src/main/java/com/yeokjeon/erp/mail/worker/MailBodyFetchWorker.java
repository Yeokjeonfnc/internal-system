package com.yeokjeon.erp.mail.worker;

import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.service.MailReceiveService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 수신 메일의 본문을 채우는 워커.
 *
 * <p><b>왜 별도 워커가 필요한가</b> — Resend 수신 웹훅 페이로드에는 본문도 헤더도 첨부도
 * 없다(공식 문서 명시). 메타데이터만 오고 본문은 Received Emails API 를 따로 호출해야
 * 받는다. 그래서 웹훅은 {@code body_status='PENDING'} 으로 껍데기만 만들어 두고,
 * 실제 본문 수집은 여기서 비동기로 처리한다.
 *
 * <p>웹훅 응답 안에서 본문 API 를 호출하지 않는 이유는, Resend 가 응답을 기다리다
 * 타임아웃하면 같은 이벤트를 계속 재전송하기 때문이다(at-least-once).
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "resend.sync", name = "enabled", havingValue = "true")
public class MailBodyFetchWorker {

    private final MailReceiveService mailReceiveService;
    private final ResendProperties properties;

    /**
     * 발송(10초)보다 주기를 길게 잡았다. 본문은 몇십 초 늦게 보여도 업무에 지장이 없지만
     * 발송 지연은 사용자가 바로 체감하기 때문이다.
     */
    @Scheduled(
            initialDelay = 30_000,
            fixedDelayString = "${resend.sync.body-interval-ms:30000}")
    public void fetch() {
        if (!properties.isApiKeyConfigured()) {
            return;
        }
        try {
            int filled = mailReceiveService.fetchPendingBodies(properties.getSync().getBatchSize());
            if (filled > 0) {
                log.info("메일 본문 수집 워커: {}건 수집", filled);
            }
        } catch (Exception e) {
            log.error("메일 본문 수집 워커 실패", e);
        }
    }
}
