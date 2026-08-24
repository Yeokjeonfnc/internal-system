package com.yeokjeon.erp.mail.worker;

import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.service.MailAttachmentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 수신 메일 첨부의 실물 파일을 내려받는 워커.
 *
 * <p>웹훅에는 첨부 메타데이터만 오고 실제 바이트는 없다. 게다가 첨부 다운로드 URL 은
 * 서명이 붙어 1시간 뒤 만료되므로, 사용자가 클릭한 시점에 받아오면 이미 늦은 경우가
 * 생긴다. 그래서 수신 직후 미리 디스크로 내려 두고 다운로드는 로컬 파일로 응답한다.
 *
 * <p>주기가 가장 긴 이유는 첨부가 본문보다 무겁고(수 MB) 급하지 않기 때문이다.
 * 본문·발송 워커와 스케줄러 스레드를 공유하므로, 여기서 오래 물고 있으면 그쪽이 밀린다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "resend.sync", name = "enabled", havingValue = "true")
public class MailAttachmentFetchWorker {

    private final MailAttachmentService mailAttachmentService;
    private final ResendProperties properties;

    @Scheduled(
            initialDelay = 45_000,
            fixedDelayString = "${resend.sync.attachment-interval-ms:60000}")
    public void fetch() {
        if (!properties.isApiKeyConfigured()) {
            return;
        }
        try {
            int fetched =
                    mailAttachmentService.fetchPendingAttachments(properties.getSync().getBatchSize());
            if (fetched > 0) {
                log.info("메일 첨부 수집 워커: {}건 수집", fetched);
            }
        } catch (Exception e) {
            log.error("메일 첨부 수집 워커 실패", e);
        }
    }
}
