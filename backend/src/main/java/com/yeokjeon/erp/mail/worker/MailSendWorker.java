package com.yeokjeon.erp.mail.worker;

import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.service.MailSendService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * QUEUED 상태의 발신 메일을 Resend 로 내보내는 워커.
 *
 * <p>컨트롤러가 직접 발송하지 않고 큐를 두는 이유는 두 가지다 — 요청 스레드가 외부 API
 * 지연에 묶이지 않게 하고, 발송 속도를 사용자 클릭이 아니라 여기서 통제하기 위해서다
 * (Resend rate limit 은 팀 단위 10 req/s).
 *
 * <p>{@code @ConditionalOnProperty} 로 빈 자체가 안 뜨게 한 이유는, 현장(3001)과 운영(3011)
 * 인스턴스가 같은 JAR 로 동시에 돌기 때문이다. 양쪽에서 워커가 돌면 같은 큐를 두 번 집어
 * 중복 발송 위험이 생긴다. 반드시 한 인스턴스에서만 켤 것.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "resend.sync", name = "enabled", havingValue = "true")
public class MailSendWorker {

    private final MailSendService mailSendService;
    private final ResendProperties properties;

    /**
     * {@code fixedRate} 가 아니라 {@code fixedDelay} 를 쓴다. 발송이 느려질 때 실행이 겹쳐
     * 같은 메일을 두 번 집는 일을 막기 위해서다(이전 실행이 끝나야 다음이 잡힌다).
     * 기동 직후는 커넥션 풀·마이그레이션이 안정될 때까지 15초 기다린다.
     */
    @Scheduled(
            initialDelay = 15_000,
            fixedDelayString = "${resend.sync.send-interval-ms:10000}")
    public void dispatch() {
        if (!properties.isApiKeyConfigured()) {
            // 키 없이 돌면 매 주기 실패 로그만 쌓인다. 조용히 건너뛴다(앱은 정상 동작).
            return;
        }
        try {
            int sent = mailSendService.dispatchQueued(properties.getSync().getBatchSize());
            if (sent > 0) {
                log.info("메일 발송 워커: {}건 발송", sent);
            }
        } catch (Exception e) {
            // 여기서 예외가 새어 나가면 스케줄러가 이 작업을 영구히 멈출 수 있다.
            // 한 주기 실패는 다음 주기에 재시도하면 되므로 삼키고 기록만 한다.
            log.error("메일 발송 워커 실패", e);
        }
    }
}
