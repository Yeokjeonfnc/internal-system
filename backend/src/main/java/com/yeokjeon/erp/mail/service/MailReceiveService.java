package com.yeokjeon.erp.mail.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.mail.client.ResendApiException;
import com.yeokjeon.erp.mail.client.ResendClient;
import com.yeokjeon.erp.mail.config.MailImmediateExecutor;
import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.dto.MailAddrDtlJdbcRow;
import com.yeokjeon.erp.mail.dto.MailAttInsertParam;
import com.yeokjeon.erp.mail.dto.MailDetailDto;
import com.yeokjeon.erp.mail.dto.MailMstInsertParam;
import com.yeokjeon.erp.mail.dto.MailMstJdbcRow;
import com.yeokjeon.erp.mail.dto.resend.ResendAttachmentMetaDto;
import com.yeokjeon.erp.mail.dto.resend.ResendReceivedEmailDto;
import com.yeokjeon.erp.mail.dto.resend.ResendWebhookDataDto;
import com.yeokjeon.erp.mail.dto.resend.ResendWebhookEventDto;
import com.yeokjeon.erp.mail.mapper.MailAddrMapper;
import com.yeokjeon.erp.mail.mapper.MailAttMapper;
import com.yeokjeon.erp.mail.mapper.MailBodyMapper;
import com.yeokjeon.erp.mail.mapper.MailMstMapper;
import com.yeokjeon.erp.mail.support.MailAddressParser;
import com.yeokjeon.erp.mail.support.MailHtmlToText;
import com.yeokjeon.erp.mail.support.MailMessageIdUtil;
import com.yeokjeon.erp.mail.support.MailSearchTextBuilder;
import com.yeokjeon.erp.mail.support.MailSubjectNormalizer;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.util.StringUtils;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 메일 수신 — 웹훅 적재(1단계) + 본문 수집(2단계).
 *
 * <p>왜 2단계인가: Resend 수신 웹훅 페이로드에는 본문·헤더·첨부 실체가 오지 않고
 * 메타데이터만 온다(공식 문서 명시). 본문은 Received Emails API 를 따로 불러야 채워진다.
 * 그런데 웹훅 응답이 늦으면 Resend 가 재전송을 시작하므로, 웹훅 처리 안에서 외부 API 를
 * 부르면 안 된다. 그래서 웹훅은 메타만 넣고 즉시 끝내고({@code body_status='PENDING'}),
 * 본문은 워커가 나중에 채운다.
 *
 * <p>트랜잭션 원칙: 외부 HTTP 호출은 절대 트랜잭션 안에서 하지 않는다. Resend 응답이
 * 15초 걸리면 그동안 DB 커넥션과 행 잠금을 붙잡고 있게 된다. 그래서 워커용 메서드는
 * 트랜잭션 없이 돌고, 건별 DB 반영만 {@link TransactionTemplate} 로 짧게 감싼다.
 * (같은 빈 안에서 {@code @Transactional} 메서드를 직접 부르면 프록시를 타지 않아
 * 애초에 무효라 프로그래매틱 트랜잭션이 유일한 선택이기도 하다.)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailReceiveService {

    /** 발신 주소를 못 읽었을 때 채울 값. {@code from_email} 이 NOT NULL 이라 비울 수 없다. */
    private static final String UNKNOWN_SENDER = "unknown@unknown.invalid";
    /** 워커 한 번에 처리할 최대 건수. rate limit(10 req/s)을 한 번에 소진하지 않게 막는다. */
    private static final int MAX_BATCH = 200;

    private static final int SUBJECT_MAX = 500;
    private static final int EMAIL_MAX = 320;
    private static final int NAME_MAX = 255;
    private static final int SUMMARY_MAX = 500;
    private static final int ERR_MAX = 500;
    private static final int RESEND_ID_MAX = 100;
    private static final int FILE_NAME_MAX = 255;
    private static final int CONTENT_TYPE_MAX = 127;
    private static final int CONTENT_ID_MAX = 255;

    private final MailMstMapper mailMstMapper;
    private final MailBodyMapper mailBodyMapper;
    private final MailAddrMapper mailAddrMapper;
    private final MailAttMapper mailAttMapper;
    private final MailThreadService mailThreadService;
    private final MailQueryService mailQueryService;
    private final MailAutoProcessService mailAutoProcessService;
    private final MailNotifyService mailNotifyService;
    private final ResendClient resendClient;
    private final ResendProperties properties;
    private final MailImmediateExecutor immediateExecutor;
    private final ObjectMapper objectMapper;
    private final PlatformTransactionManager transactionManager;

    private TransactionTemplate txTemplate;

    @PostConstruct
    void initTxTemplate() {
        this.txTemplate = new TransactionTemplate(transactionManager);
    }

    /**
     * {@code email.received} 웹훅 처리 — 메타 저장 + 자동분류 규칙 적용. 외부 호출 없음.
     *
     * <p>멱등: 같은 {@code resend_email_id} 가 이미 있으면 그 {@code mail_idx} 를 그대로 돌려준다.
     * 웹훅은 at-least-once 라 같은 메일이 여러 번 들어오는 것이 정상 동작이다. 이때
     * <b>규칙은 다시 적용하지 않는다</b> — 사용자가 손으로 옮겨 둔 메일함을 재전달 웹훅이
     * 원래대로 되돌려 놓으면 "고쳐도 자꾸 돌아가는" 상태가 된다.
     *
     * <p><b>{@code @Transactional} 대신 {@link TransactionTemplate} 을 쓰는 이유.</b>
     * 규칙 적용이 실패해도 메일 저장은 남아야 한다(분류를 못 했을 뿐 메일은 받아야 한다).
     * 그런데 같은 트랜잭션 안에서 {@code @Transactional} 인 하위 서비스가 예외를 던지면
     * 스프링이 그 트랜잭션을 rollback-only 로 표시해 버려, 예외를 잡아도 커밋 시점에
     * {@code UnexpectedRollbackException} 이 나고 <b>메일 자체가 사라진다</b>
     * ({@code MailWebhookService} 가 원장을 세 트랜잭션으로 나눈 것과 같은 함정).
     * 그래서 저장을 먼저 커밋하고, 규칙은 그 바깥에서 별도 트랜잭션으로 돌린다.
     *
     * <p><b>이 메서드를 트랜잭션 안에서 부르지 말 것.</b> 상위 트랜잭션이 있으면
     * txTemplate 이 거기에 합류해(PROPAGATION_REQUIRED) 저장이 아직 커밋되지 않은 상태로
     * 규칙 적용이 시작되고, 위의 분리가 통째로 무효가 된다. 현재 유일한 호출부인
     * {@code MailWebhookService.process} 는 의도적으로 트랜잭션이 없다.
     */
    public long ingestReceived(ResendWebhookEventDto event) {
        IngestOutcome outcome = txTemplate.execute(status -> saveReceived(event));
        if (outcome == null) {
            throw new IllegalStateException("수신 메일 저장에 실패했습니다.");
        }
        if (outcome.created()) {
            try {
                mailAutoProcessService.applyRules(outcome.mailIdx());
            } catch (RuntimeException e) {
                // try/catch 가 반드시 여기(프록시 바깥)에 있어야 한다. MailAutoProcessService
                // 안에서 잡으면 이미 rollback-only 로 표시된 트랜잭션을 커밋하려다 터진다.
                log.warn("자동분류 규칙 적용 실패 — 메일 저장은 그대로 둔다 mailIdx={}",
                        outcome.mailIdx(), e);
            }
            /*
             * ERP 알림 (mal001-N).
             *
             * created 일 때만 부르는 것이 중복 알림 방지의 1겹이다. 웹훅 재전달·원장
             * 재처리는 outcome.created()=false 로 돌아오므로 여기 자체가 안 돈다
             * (2겹은 MailNotifyService 의 NOT EXISTS 다).
             *
             * 규칙 적용과 같은 이유로 try/catch 가 프록시 바깥에 있어야 하고, 실패해도
             * 메일 저장은 그대로 둔다 — 알림 하나 때문에 메일을 못 받으면 안 된다.
             */
            try {
                mailNotifyService.notifyReceived(outcome.mailIdx());
            } catch (RuntimeException e) {
                log.warn("수신 메일 알림 생성 실패 — 메일 저장은 그대로 둔다 mailIdx={}",
                        outcome.mailIdx(), e);
            }
            /*
             * 저장 직후 즉시 본문 수집 (mal001-M).
             *
             * 사용자 원문: "본문수집중이 너무 딜레이가 긴데, 최대한 빠르게 수집되도록 해줘".
             * 지금까지는 웹훅이 PENDING 껍데기만 만들고 워커 주기를 기다렸다 — 그 사이
             * 목록에는 제목만 있고 본문은 "수집중"으로 보인다.
             *
             * <b>웹훅 응답을 막지 않는다.</b> 실행기에 제출만 하고 곧바로 돌아가므로
             * 컨트롤러는 평소처럼 즉시 200 을 반환한다(늦으면 Resend 가 재전송한다).
             * 이 경로에는 열린 트랜잭션이 없어(MailWebhookService 는 의도적으로 무트랜잭션)
             * runAfterCommit 은 곧바로 제출로 이어진다. 그래도 runAfterCommit 을 쓰는 이유는
             * 나중에 이 메서드를 트랜잭션 안에서 부르는 호출부가 생겨도 깨지지 않게 하기 위해서다.
             */
            final long mailIdx = outcome.mailIdx();
            immediateExecutor.runAfterCommit("body-" + mailIdx, () -> fetchBodyNow(mailIdx));
        }
        return outcome.mailIdx();
    }

    /**
     * 저장 결과.
     *
     * @param created false 면 이미 있던 메일(중복 웹훅)이라 규칙을 적용하지 않는다
     */
    private record IngestOutcome(long mailIdx, boolean created) {
    }

    /** 메타 저장 본체. 한 트랜잭션 안에서 mail_mst + 참여자 + 첨부 메타가 함께 들어간다. */
    private IngestOutcome saveReceived(ResendWebhookEventDto event) {
        ResendWebhookDataDto data = event == null ? null : event.data();
        if (data == null) {
            throw new IllegalArgumentException("수신 웹훅 본문이 비어 있습니다.");
        }
        String resendEmailId = clip(trimToNull(data.emailId()), RESEND_ID_MAX);
        if (resendEmailId == null) {
            throw new IllegalArgumentException("수신 웹훅에 email_id 가 없습니다.");
        }

        Long existing = mailMstMapper.selectIdxByResendEmailId(resendEmailId);
        if (existing != null) {
            log.debug("이미 저장된 수신 메일 — 재적재 생략 mailIdx={}", existing);
            return new IngestOutcome(existing, false);
        }

        MailAddressParser.Address from = MailAddressParser.parseOne(data.from());
        List<MailAddressParser.Address> to = MailAddressParser.parseAll(data.to());
        List<MailAddressParser.Address> cc = MailAddressParser.parseAll(data.cc());
        List<MailAddressParser.Address> bcc = MailAddressParser.parseAll(data.bcc());

        String subject = MailSubjectNormalizer.clipSubject(data.subject());
        String subjectNorm = MailSubjectNormalizer.normalize(data.subject());
        // 웹훅 페이로드에는 In-Reply-To/References 가 없다. 이 시점에 쓸 수 있는 단서는
        // 내 Message-ID(역방향 매칭)와 제목뿐이다. 정방향 연결은 본문 수집 단계에서
        // References 를 확보한 뒤에야 가능하다.
        String rfcMessageId = MailMessageIdUtil.strip(data.messageId());
        OffsetDateTime mailAt = firstNonNull(data.createdAt(), event.createdAt(), OffsetDateTime.now());
        long threadIdx = mailThreadService.resolveThreadIdx(subjectNorm, rfcMessageId, null, null, mailAt);

        MailMstInsertParam param = new MailMstInsertParam();
        param.setThreadIdx(threadIdx);
        param.setDirection("IN");
        param.setResendEmailId(resendEmailId);
        param.setRfcMessageId(rfcMessageId);
        param.setSubject(subject);
        param.setSubjectNorm(subjectNorm);
        param.setFromEmail(from == null ? UNKNOWN_SENDER : from.email());
        // 주소 파싱에 실패해도 원문은 남긴다. 나중에 사람이 보고 판단할 수 있어야 한다.
        param.setFromNm(from == null ? clip(data.from(), NAME_MAX) : clip(from.dispNm(), NAME_MAX));
        param.setToSummary(MailAddressParser.summarize(to, SUMMARY_MAX));
        param.setSnippet("");
        param.setAttCnt(data.attachments() == null ? 0 : data.attachments().size());
        param.setBodyStatus("PENDING");
        param.setReadYn("N");
        param.setMailAt(mailAt);
        // 수신 메일은 담당자가 아직 없다. 화면에서 배정하면 mail_mst.user_id 가 채워진다.
        mailMstMapper.insert(param);

        Long mailIdx = param.getMailIdx();
        if (mailIdx == null) {
            throw new IllegalStateException("수신 메일 저장에 실패했습니다.");
        }

        List<MailAddrDtlJdbcRow> addresses = new ArrayList<>();
        appendAddresses(addresses, mailIdx, "FROM", from == null ? List.of() : List.of(from));
        appendAddresses(addresses, mailIdx, "TO", to);
        appendAddresses(addresses, mailIdx, "CC", cc);
        appendAddresses(addresses, mailIdx, "BCC", bcc);
        if (!addresses.isEmpty()) {
            mailAddrMapper.insertBatch(mailIdx, addresses);
        }

        insertAttachmentMetas(mailIdx, data.attachments());
        mailMstMapper.updateAttCnt(mailIdx);
        mailThreadService.touch(threadIdx);

        log.info("수신 메일 저장 mailIdx={} threadIdx={} attCnt={}",
                mailIdx, threadIdx, data.attachments() == null ? 0 : data.attachments().size());
        return new IngestOutcome(mailIdx, true);
    }

    /**
     * {@code body_status='PENDING'} 인 메일의 본문을 채운다(워커 전용, 트랜잭션 없음).
     *
     * @return 성공 건수
     */
    public int fetchPendingBodies(int limit) {
        if (!resendClient.isEnabled()) {
            log.warn("Resend API 키가 없어 메일 본문 수집을 건너뜁니다(RESEND_API_KEY 미설정).");
            return 0;
        }
        ResendProperties.Sync sync = properties.getSync();
        List<MailMstJdbcRow> rows = mailMstMapper.selectBodyPending(
                clampBatch(limit), sync.getMaxTryCnt(), sync.getBackoffMinutes());
        int success = 0;
        for (MailMstJdbcRow row : rows) {
            try {
                /*
                 * 선점에 실패하면 건너뛴다 (mal001-M).
                 *
                 * 수신 저장 직후의 즉시 트리거가 같은 행을 먼저 집을 수 있게 되면서
                 * select 만으로는 소유권이 정해지지 않는다. select 는 후보 고르기이고,
                 * 소유권은 claimBodyPending 의 조건부 UPDATE 가 준다.
                 */
                if (!claimBody(row.mailIdx())) {
                    log.debug("이미 다른 경로가 선점한 본문 수집 건 — 건너뛴다 mailIdx={}", row.mailIdx());
                    continue;
                }
                if (collectClaimed(row)) {
                    success++;
                }
            } catch (RuntimeException e) {
                // 한 건이 터져도 나머지는 계속 처리한다. 배치가 통째로 멈추면
                // 뒤에 쌓인 메일이 영원히 PENDING 으로 남는다.
                log.warn("메일 본문 수집 실패 mailIdx={}", row.mailIdx(), e);
            }
        }
        if (!rows.isEmpty()) {
            log.info("메일 본문 수집 {}/{}건 완료", success, rows.size());
        }
        return success;
    }

    /**
     * 저장 직후 즉시 본문 수집 (mal001-M). 전용 실행기 스레드에서만 부른다.
     *
     * <p><b>최적화이지 유일한 경로가 아니다.</b> 선점에 실패하거나 조건이 안 맞으면
     * 조용히 돌아간다 — 행은 PENDING 그대로라 {@code MailBodyFetchWorker} 가 안전망으로
     * 다시 집는다. 그래서 예외를 던지지 않는다.
     */
    public void fetchBodyNow(long mailIdx) {
        if (!resendClient.isEnabled()) {
            return;
        }
        if (!claimBody(mailIdx)) {
            log.debug("즉시 본문 수집 선점 실패 — 워커에 맡긴다 mailIdx={}", mailIdx);
            return;
        }
        MailMstJdbcRow row = mailMstMapper.selectByIdx(mailIdx);
        if (row == null || Boolean.TRUE.equals(row.deletedYn())) {
            return;
        }
        boolean filled = collectClaimed(row);
        log.info("즉시 본문 수집 시도 mailIdx={} 성공={}", mailIdx, filled);
    }

    /** 선점 시도. 성공(1건 갱신)해야 이 스레드가 그 메일의 본문을 받을 자격을 갖는다. */
    private boolean claimBody(Long mailIdx) {
        ResendProperties.Sync sync = properties.getSync();
        return mailMstMapper.claimBodyPending(mailIdx, sync.getMaxTryCnt(), sync.getBackoffMinutes()) > 0;
    }

    /** 단건 본문 재수집(화면의 수동 트리거). 트랜잭션 없음. */
    public MailDetailDto fetchBody(long mailIdx) {
        MailMstJdbcRow row = mailMstMapper.selectByIdx(mailIdx);
        if (row == null || Boolean.TRUE.equals(row.deletedYn())) {
            throw new ResourceNotFoundException("메일", "mailIdx", mailIdx);
        }
        if (!"IN".equals(row.direction())) {
            throw new IllegalStateException("수신 메일만 본문을 다시 받을 수 있습니다.");
        }
        if (!resendClient.isEnabled()) {
            // 예외로 앱을 흔들지 않고, 왜 안 되는지만 분명히 알린다.
            throw new IllegalStateException(
                    "Resend API 키가 설정되지 않아 본문을 받을 수 없습니다. 관리자에게 문의해 주세요.");
        }
        collectBody(row);
        return mailQueryService.findDetail(mailIdx);
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    /**
     * 한 건의 본문을 받아 저장한다.
     *
     * <p>순서가 중요하다. 먼저 시도 횟수를 올려 두어야(=커밋해야) 중간에 프로세스가 죽어도
     * 같은 메일을 무한히 재시도하지 않는다.
     */
    private boolean collectBody(MailMstJdbcRow row) {
        final long mailIdx = row.mailIdx();
        txTemplate.executeWithoutResult(status -> mailMstMapper.markBodyTried(mailIdx));
        return collectClaimed(row);
    }

    /**
     * 선점이 끝난 뒤의 실제 본문 수집 (mal001-M).
     *
     * <p>{@code claimBodyPending} 이 이미 {@code body_try_cnt}/{@code body_tried_at} 을
     * 올려 커밋했으므로 여기서 {@link MailMstMapper#markBodyTried} 를 다시 부르면 시도
     * 횟수가 두 배로 소모돼 maxTryCnt 에 절반 만에 도달한다. 그래서 시도 기록은
     * 호출부(선점)가 맡고 이 메서드는 수집과 결과 반영만 한다.
     *
     * <p>{@code row} 는 선점 이전 값이라 {@code bodyTryCnt} 가 1 낮다. 아래 재시도
     * 판정의 {@code +1} 이 그 보정이다(기존 markBodyTried 경로와 동일).
     */
    private boolean collectClaimed(MailMstJdbcRow row) {
        final long mailIdx = row.mailIdx();
        final String resendEmailId = row.resendEmailId();

        final int maxTryCnt = properties.getSync().getMaxTryCnt();

        if (!StringUtils.hasText(resendEmailId)) {
            // 부를 키 자체가 없다. 몇 번을 다시 시도해도 같으므로 즉시 확정한다.
            txTemplate.executeWithoutResult(status -> mailMstMapper.updateBodyFailed(
                    mailIdx, "resend_email_id 가 없어 본문을 받을 수 없습니다.", maxTryCnt, true));
            return false;
        }

        try {
            ResendReceivedEmailDto mail = resendClient.getReceivedEmail(resendEmailId);
            if (mail == null) {
                // 일시적인 응답 이상일 수 있어 시도 횟수가 남았으면 다시 집도록 둔다.
                txTemplate.executeWithoutResult(status -> mailMstMapper.updateBodyFailed(
                        mailIdx, "Resend 가 빈 응답을 반환했습니다.", maxTryCnt, false));
                return false;
            }
            txTemplate.executeWithoutResult(status -> storeBody(row, mail));
            /*
             * 자동전달은 여기서 건다 (mal001-L).
             *
             * 수신 저장 직후가 아닌 이유: 웹훅 페이로드에는 본문이 없다(이 클래스 첫 주석).
             * 그 시점에 전달하면 본문이 빈 메일이 나가고, 받는 사람은 그게 무슨 메일인지
             * 알 수도 없다. 본문이 채워진 지금이 유일하게 온전한 메일을 만들 수 있는 시점이다.
             *
             * 규칙 적용과 마찬가지로 try/catch 가 프록시 바깥(=여기)에 있어야 한다.
             * 전달이 실패해도 본문 수집은 이미 커밋됐고, 그대로 성공으로 남긴다 —
             * 전달 한 번 못 했다고 본문을 다시 받게 만들 이유가 없다.
             */
            try {
                mailAutoProcessService.autoForward(mailIdx);
            } catch (RuntimeException e) {
                log.warn("자동전달 실패 — 본문 수집은 그대로 둔다 mailIdx={}", mailIdx, e);
            }
            return true;
        } catch (ResendApiException e) {
            int tried = row.bodyTryCnt() == null ? 0 : row.bodyTryCnt() + 1;
            if (e.retryable() && tried < maxTryCnt) {
                // PENDING 을 유지한 채 둔다. 백오프가 지나면 다음 배치가 다시 집는다.
                log.warn("메일 본문 수집 일시 실패(재시도 예정) mailIdx={} status={} try={}",
                        mailIdx, e.statusCode(), tried);
                return false;
            }
            // 비재시도성 오류(404 등)는 다시 물어봐도 같으므로 시도 횟수와 무관하게 확정한다.
            txTemplate.executeWithoutResult(status -> mailMstMapper.updateBodyFailed(
                    mailIdx, clip(e.getMessage(), ERR_MAX), maxTryCnt, !e.retryable()));
            return false;
        }
    }

    /** 본문·헤더·참여자·첨부 메타를 한 트랜잭션에 반영한다. */
    private void storeBody(MailMstJdbcRow row, ResendReceivedEmailDto mail) {
        long mailIdx = row.mailIdx();
        int bodyMaxBytes = properties.getBodyMaxBytes();

        String html = mail.html();
        String text = mail.text();
        if (!StringUtils.hasText(text)) {
            // 평문 파트가 없는 HTML 전용 메일. 여기서 한 번만 변환해 두면
            // 이후 목록·검색이 전부 이 값을 재사용한다.
            text = MailHtmlToText.toPlainText(html);
        }
        boolean truncated = MailSearchTextBuilder.exceedsBytes(text, bodyMaxBytes)
                || MailSearchTextBuilder.exceedsBytes(html, bodyMaxBytes);
        if (truncated) {
            // 상한을 넘는 본문은 잘라서라도 저장한다. 통째로 버리면 검색·미리보기가 아예 없어진다.
            // HTML 은 중간에서 잘려 태그가 깨질 수 있어 truncated_yn 으로 표시하고
            // 화면이 "일부만 표시됨"을 알릴 수 있게 한다.
            text = MailSearchTextBuilder.truncateToBytes(text, bodyMaxBytes);
            html = MailSearchTextBuilder.truncateToBytes(html, bodyMaxBytes);
        }

        Map<String, Object> headers = mail.headers();
        String headersRaw = writeJson(headers);

        List<MailAddressParser.Address> from = MailAddressParser.parseLine(mail.from());
        List<MailAddressParser.Address> to = MailAddressParser.parseAll(mail.to());
        List<MailAddressParser.Address> cc = MailAddressParser.parseAll(mail.cc());
        List<MailAddressParser.Address> bcc = MailAddressParser.parseAll(mail.bcc());
        List<MailAddressParser.Address> replyTo = MailAddressParser.parseAll(mail.replyTo());

        Set<String> participants = new LinkedHashSet<>();
        participants.addAll(MailAddressParser.emails(from));
        participants.addAll(MailAddressParser.emails(to));
        participants.addAll(MailAddressParser.emails(cc));
        participants.addAll(MailAddressParser.emails(bcc));

        String searchTxt = MailSearchTextBuilder.build(
                row.subject(), participants, text, properties.getSearchMaxBytes());
        mailBodyMapper.upsert(mailIdx, text, html, headersRaw, searchTxt, truncated);

        // 참여자는 통째로 다시 쓴다. 웹훅 단계에서는 REPLY_TO 를 알 수 없었고,
        // 부분 갱신하면 어떤 행이 남고 어떤 행이 새로 들어가는지 추적이 어려워진다.
        List<MailAddrDtlJdbcRow> addresses = new ArrayList<>();
        appendAddresses(addresses, mailIdx, "FROM", from);
        appendAddresses(addresses, mailIdx, "TO", to);
        appendAddresses(addresses, mailIdx, "CC", cc);
        appendAddresses(addresses, mailIdx, "BCC", bcc);
        appendAddresses(addresses, mailIdx, "REPLY_TO", replyTo);
        if (!addresses.isEmpty()) {
            mailAddrMapper.deleteByMailIdx(mailIdx);
            mailAddrMapper.insertBatch(mailIdx, addresses);
        }

        insertAttachmentMetas(mailIdx, mail.attachments());
        mailMstMapper.updateAttCnt(mailIdx);

        String rfcMessageId = MailMessageIdUtil.strip(firstNonBlank(
                mail.messageId(), headerValue(headers, "message-id"), row.rfcMessageId()));
        String inReplyTo = MailMessageIdUtil.firstMessageId(headerValue(headers, "in-reply-to"));
        String refsTxt = MailMessageIdUtil.joinReferences(
                MailMessageIdUtil.parseReferences(headerValue(headers, "references")));
        String snippet = MailHtmlToText.snippetOf(text, html, properties.getSnippetMaxChars());

        mailMstMapper.updateBodyDone(
                mailIdx, snippet, mailAttMapper.countByMailIdx(mailIdx), rfcMessageId, inReplyTo, refsTxt);
        mailThreadService.touch(row.threadIdx());

        // 주의: 여기서 비로소 References 를 알게 되지만 이미 배정된 thread_idx 를 옮기지는 않는다.
        // MailMstMapper 에 thread_idx 갱신 수단이 없기 때문이며, 제목 폴백이 대부분을 잡아 준다.
        log.debug("메일 본문 저장 mailIdx={} truncated={}", mailIdx, truncated);
    }

    /**
     * 첨부 메타 적재.
     *
     * <p>웹훅 시점에는 {@code size} 가 없으므로 0 으로 넣는다(마이그레이션 설계).
     * 실제 크기는 첨부 수집 워커가 파일을 받은 뒤 채운다. INSERT 는 XML 의
     * {@code ON CONFLICT (mail_idx, resend_att_id) DO NOTHING} 덕분에 여러 번 불러도 안전하다.
     */
    private void insertAttachmentMetas(long mailIdx, List<ResendAttachmentMetaDto> attachments) {
        if (attachments == null || attachments.isEmpty()) {
            return;
        }
        for (ResendAttachmentMetaDto meta : attachments) {
            if (meta == null) {
                continue;
            }
            MailAttInsertParam param = new MailAttInsertParam();
            param.setMailIdx(mailIdx);
            param.setResendAttId(clip(trimToNull(meta.id()), RESEND_ID_MAX));
            param.setFileName(clip(firstNonBlank(meta.filename(), "attachment"), FILE_NAME_MAX));
            param.setStoredName(null);
            param.setFileSize(meta.size() == null ? 0L : meta.size());
            param.setContentType(clip(meta.contentType(), CONTENT_TYPE_MAX));
            param.setContentId(clip(MailMessageIdUtil.strip(meta.contentId()), CONTENT_ID_MAX));
            param.setInlineYn("inline".equalsIgnoreCase(meta.contentDisposition()) ? "Y" : "N");
            // fetched_at 은 실물을 받은 뒤에 채운다. NULL 이 곧 "아직 못 받음" 신호다.
            param.setFetchedAt(null);
            mailAttMapper.insert(param);
        }
    }

    private static void appendAddresses(List<MailAddrDtlJdbcRow> target,
                                        long mailIdx,
                                        String addrType,
                                        List<MailAddressParser.Address> addresses) {
        if (addresses == null || addresses.isEmpty()) {
            return;
        }
        int seq = 0;
        for (MailAddressParser.Address address : addresses) {
            target.add(new MailAddrDtlJdbcRow(
                    mailIdx,
                    addrType,
                    seq++,
                    clip(address.email(), EMAIL_MAX),
                    clip(address.dispNm(), NAME_MAX)));
        }
    }

    /** 헤더 맵은 소문자 키이고 값이 문자열일 수도 배열일 수도 있다. */
    private static String headerValue(Map<String, Object> headers, String key) {
        if (headers == null || headers.isEmpty()) {
            return null;
        }
        Object value = headers.get(key);
        if (value == null) {
            return null;
        }
        if (value instanceof List<?> list) {
            StringBuilder builder = new StringBuilder();
            for (Object item : list) {
                if (item == null) {
                    continue;
                }
                if (builder.length() > 0) {
                    builder.append(' ');
                }
                builder.append(item);
            }
            return builder.length() == 0 ? null : builder.toString();
        }
        return String.valueOf(value);
    }

    private String writeJson(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            // 헤더를 못 남겨도 메일 자체는 저장돼야 한다. 본문 수집 전체를 실패로 만들지 않는다.
            log.warn("메일 헤더 직렬화 실패 — headers_raw 를 비운 채 진행합니다.", e);
            return null;
        }
    }

    private static int clampBatch(int limit) {
        if (limit <= 0) {
            return 1;
        }
        return Math.min(limit, MAX_BATCH);
    }

    private static String clip(String value, int max) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        if (trimmed.isEmpty()) {
            return "";
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

    private static String firstNonBlank(String... values) {
        for (String value : values) {
            if (StringUtils.hasText(value)) {
                return value.trim();
            }
        }
        return null;
    }

    @SafeVarargs
    private static <T> T firstNonNull(T... values) {
        for (T value : values) {
            if (value != null) {
                return value;
            }
        }
        return null;
    }
}
