package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.mail.client.ResendApiException;
import com.yeokjeon.erp.mail.client.ResendClient;
import com.yeokjeon.erp.mail.config.MailImmediateExecutor;
import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.dto.MailAddrDtlJdbcRow;
import com.yeokjeon.erp.mail.dto.MailBodyJdbcRow;
import com.yeokjeon.erp.mail.dto.MailMstInsertParam;
import com.yeokjeon.erp.mail.dto.MailMstJdbcRow;
import com.yeokjeon.erp.mail.dto.MailSendRequestDto;
import com.yeokjeon.erp.mail.dto.MailSendResultDto;
import com.yeokjeon.erp.mail.dto.resend.ResendSendAttachmentDto;
import com.yeokjeon.erp.mail.dto.resend.ResendSendRequestDto;
import com.yeokjeon.erp.mail.mapper.MailAddrMapper;
import com.yeokjeon.erp.mail.mapper.MailBodyMapper;
import com.yeokjeon.erp.mail.mapper.MailMstMapper;
import com.yeokjeon.erp.mail.support.MailAddressParser;
import com.yeokjeon.erp.mail.support.MailHtmlToText;
import com.yeokjeon.erp.mail.support.MailMessageIdUtil;
import com.yeokjeon.erp.mail.support.MailOpenTokenCodec;
import com.yeokjeon.erp.mail.support.MailSearchTextBuilder;
import com.yeokjeon.erp.mail.support.MailSubjectNormalizer;
import com.yeokjeon.erp.mail.support.MailTrackingPixel;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.util.StringUtils;

import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 메일 발송 — 작성/대기열 등록(트랜잭션)과 실제 발송(무트랜잭션)을 분리한다.
 *
 * <p>왜 나누는가. 사용자가 "보내기"를 눌렀을 때 그 요청 안에서 Resend 를 호출하면
 * 두 가지가 동시에 망가진다. (1) Resend 가 느리면 사용자 요청이 그만큼 멈춘다.
 * (2) 발송은 성공했는데 그 뒤 DB 커밋이 실패하면 "보낸 기록 없이 실제로 나간 메일"이 생긴다.
 * 그래서 작성 요청은 {@code send_status='QUEUED'} 까지만 하고 끝낸다. 실제 송신은
 * 워커가 트랜잭션 밖에서 하고, 결과만 짧은 트랜잭션으로 되쓴다.
 *
 * <p>덕분에 발송 실패가 상위 트랜잭션을 롤백시키는 일이 구조적으로 불가능하다 —
 * 발송 시점에는 감쌀 상위 트랜잭션 자체가 없다.
 *
 * <p>중복 발송 방지는 {@code Idempotency-Key = "mail-" + mailIdx} 가 맡는다.
 * 워커가 응답을 못 받고 재시도해도 Resend 가 24시간 동안 같은 키를 기억한다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailSendService {

    private static final int MAX_BATCH = 200;

    /**
     * Resend 의 {@code to} 상한.
     *
     * <p>한 요청에 50명을 넘기면 Resend 가 거부한다. 조직도에서 부서 전체를 고르면
     * 이 값을 넘길 수 있어서 {@link #compose} 가 이 크기로 잘라 여러 통으로 만든다.
     */
    static final int RESEND_TO_LIMIT = 50;

    /** Resend 예약 상한(일). 넘겨 보내면 발송 시점에 4xx 가 난다. */
    private static final int SCHEDULE_MAX_DAYS = 30;

    /**
     * 최소 예약 여유(초).
     *
     * <p>워커 주기(기본 10초)보다 넉넉해야 한다. "10초 뒤" 예약은 Resend 에 넘기기도 전에
     * 시각이 지나 버려 예약이 아니라 즉시 발송이 된다.
     */
    private static final int MIN_LEAD_SECONDS = 60;

    private static final int EMAIL_MAX = 320;
    private static final int NAME_MAX = 255;
    private static final int SUMMARY_MAX = 500;
    private static final int ERR_MAX = 500;
    private static final int RESEND_ID_MAX = 100;

    private final MailMstMapper mailMstMapper;
    private final MailBodyMapper mailBodyMapper;
    private final MailAddrMapper mailAddrMapper;
    private final MailThreadService mailThreadService;
    private final MailAttachmentService mailAttachmentService;
    private final ResendClient resendClient;
    private final ResendProperties properties;
    private final MailImmediateExecutor immediateExecutor;
    private final PlatformTransactionManager transactionManager;

    private TransactionTemplate txTemplate;

    @PostConstruct
    void initTxTemplate() {
        this.txTemplate = new TransactionTemplate(transactionManager);
    }

    /**
     * 메일 작성 저장. 외부 호출은 하지 않는다.
     *
     * <p>{@code sendNow=false} 는 DRAFT 로만 남긴다 — 첨부를 붙이려면 mail_idx 가 먼저
     * 있어야 하는데, 첨부 업로드 전에 발송돼 버리면 첨부 없는 메일이 나가기 때문이다.
     */
    @Transactional
    public MailSendResultDto compose(MailSendRequestDto body, String callerUserId) {
        if (body == null) {
            throw new IllegalArgumentException("작성 내용이 없습니다.");
        }
        List<MailAddressParser.Address> to = MailAddressParser.parseAll(body.to());
        if (to.isEmpty()) {
            throw new IllegalArgumentException("받는 사람을 한 명 이상 입력해 주세요.");
        }
        String fromEmail = resolveFromEmail(body.fromEmail());
        List<MailAddressParser.Address> cc = MailAddressParser.parseAll(body.cc());
        List<MailAddressParser.Address> bcc = MailAddressParser.parseAll(body.bcc());
        List<MailAddressParser.Address> replyTo = MailAddressParser.parseAll(body.replyTo());

        String subject = MailSubjectNormalizer.clipSubject(body.subject());
        String subjectNorm = MailSubjectNormalizer.normalize(body.subject());
        OffsetDateTime now = OffsetDateTime.now();

        // 우리 쪽 Message-ID. Resend 가 실제 헤더에 무엇을 넣는지는 응답으로 알 수 없으므로
        // 외부에는 보내지 않고, "우리가 보낸 메일에 우리가 다시 답장"할 때의 로컬 기준점으로만 쓴다.
        String rfcMessageId = MailMessageIdUtil.generate(fromEmail);
        String inReplyTo = null;
        String refsTxt = null;
        long threadIdx;

        MailMstJdbcRow parent = findParent(body.replyToMailIdx());
        if (parent != null) {
            inReplyTo = MailMessageIdUtil.strip(parent.rfcMessageId());
            List<String> references = new ArrayList<>(MailMessageIdUtil.parseReferences(parent.refsTxt()));
            if (inReplyTo != null) {
                references.add(inReplyTo);
            }
            refsTxt = MailMessageIdUtil.joinReferences(references);
            // 답장은 스레드 판정을 다시 하지 않는다. 사용자가 "이 메일에 답장"이라고 이미 말했으므로
            // 제목을 바꿔 보냈더라도 원본과 같은 대화로 묶는 것이 맞다.
            threadIdx = parent.threadIdx();
        } else {
            threadIdx = mailThreadService.resolveThreadIdx(subjectNorm, rfcMessageId, null, null, now);
        }

        boolean sendNow = body.sendNow() == null || Boolean.TRUE.equals(body.sendNow());
        String bodyHtml = body.bodyHtml();
        String bodyText = StringUtils.hasText(body.bodyText())
                ? body.bodyText()
                : MailHtmlToText.toPlainText(bodyHtml);
        if (!StringUtils.hasText(bodyHtml) && !StringUtils.hasText(bodyText)) {
            throw new IllegalArgumentException("본문을 입력해 주세요.");
        }

        OffsetDateTime scheduledAt = normalizeScheduledAt(body.scheduledAt(), now);
        String readReceiptYn = Boolean.TRUE.equals(body.readReceipt()) ? "Y" : "N";
        String importance = normalizeImportance(body.importance());
        if ("Y".equals(readReceiptYn) && !properties.isTrackingConfigured()) {
            // 요청은 받아 두되 실제로는 픽셀이 안 심긴다. 조용히 무시하면 사용자는
            // "수신확인을 켰는데 영원히 안 잡히는" 상태를 설정 문제로 인지하지 못한다.
            log.warn("수신확인이 요청됐지만 추적 설정(RESEND_TRACKING_BASE_URL)이 없어 픽셀을 심을 수 없습니다.");
        }

        /*
         * 수신자를 50명씩 나눈다 (mal001-J).
         *
         * Resend 는 한 요청의 to 를 최대 50명까지만 받는다. 조직도에서 부서를 통째로
         * 고르면 이 상한을 넘길 수 있어서, 발송 단계에서 갈라야 한다.
         *
         * **왜 발송(dispatch)이 아니라 작성(compose) 단계에서 나누는가.**
         * dispatchRow 에서 나누면 한 mail_mst 행에 Resend email id 가 여러 개 생기는데,
         * resend_email_id 는 유니크 단일 컬럼이라 하나밖에 못 담는다. 나머지 id 로 오는
         * 웹훅은 짝을 찾지 못해 배달 상태·바운스가 통째로 유실된다.
         * 여기서 나누면 각 통이 온전한 메일 한 건이 되어 추적·재발송·취소가 전부 정상 동작한다.
         * 사용자에게도 보낸메일함에 "3통"으로 보이는 편이 실제와 맞다.
         *
         * cc/bcc/reply-to 는 첫 통에만 붙인다. 모든 통에 넣으면 참조자가 같은 메일을
         * 나뉜 수만큼 받는다.
         */
        List<List<MailAddressParser.Address>> chunks = chunkRecipients(to);

        List<Long> createdIdxes = new ArrayList<>(chunks.size());
        String firstStatus = null;
        for (int i = 0; i < chunks.size(); i++) {
            boolean firstChunk = i == 0;
            long created = insertOutgoing(
                    threadIdx,
                    // Message-ID 는 통마다 달라야 한다. 같은 값이 두 통에 붙으면 수신자
                    // 클라이언트가 뒤에 온 것을 중복으로 보고 버릴 수 있다.
                    firstChunk ? rfcMessageId : MailMessageIdUtil.generate(fromEmail),
                    inReplyTo,
                    refsTxt,
                    subject,
                    subjectNorm,
                    fromEmail,
                    clip(firstNonBlank(body.fromNm(), properties.getFromName()), NAME_MAX),
                    chunks.get(i),
                    firstChunk ? cc : List.of(),
                    firstChunk ? bcc : List.of(),
                    firstChunk ? replyTo : List.of(),
                    bodyHtml,
                    bodyText,
                    sendNow ? "QUEUED" : "DRAFT",
                    scheduledAt,
                    readReceiptYn,
                    importance,
                    trimToNull(callerUserId),
                    body.partnerIdx(),
                    body.mappingId(),
                    now);
            createdIdxes.add(created);
            if (firstChunk) {
                firstStatus = sendNow ? "QUEUED" : "DRAFT";
            }
        }

        mailThreadService.touch(threadIdx);

        /*
         * 저장 직후 즉시 발송 시도 (mal001-M).
         *
         * 사용자 원문: "메일을 보내고 발송대기가 너무 긴것같은데". 지금까지는 여기서
         * QUEUED 로 저장만 하고 워커 주기를 기다렸다. 그 대기는 사용자가 "보내기"를 누른
         * 직후에 그대로 체감된다.
         *
         * runAfterCommit 이어야 한다. 이 메서드는 @Transactional 이라 지금 즉시 제출하면
         * 아직 커밋되지 않은 행을 다른 스레드가 조회하게 되고(READ COMMITTED) 선점이
         * 매번 0건으로 실패해 기능이 있으나 마나 해진다.
         *
         * 실패하거나 큐가 넘쳐 버려져도 상관없다 — 행은 QUEUED 그대로라 워커가 집는다.
         * 나뉜 통(chunks)까지 전부 걸지만, 실행기가 스로틀·큐 상한으로 폭주를 막는다.
         */
        if (sendNow) {
            for (Long created : createdIdxes) {
                immediateExecutor.runAfterCommit("send-" + created, () -> dispatchNow(created));
            }
        }

        long mailIdx = createdIdxes.get(0);
        log.info("메일 작성 저장 mailIdx={} status={} 수신자={}명 {}통 예약={} by={}",
                mailIdx, firstStatus, to.size(), chunks.size(), scheduledAt, callerUserId);

        return new MailSendResultDto(
                mailIdx,
                firstStatus,
                "",
                composeMessage(sendNow, scheduledAt, to.size(), chunks.size()));
    }

    /**
     * 예약 발송 취소 (mal001-F).
     *
     * <p><b>Resend 취소를 먼저 하고 DB 를 되돌린다.</b> 순서를 바꾸면 DB 는 DRAFT 인데
     * 예약 시각이 되면 메일이 실제로 나가는 최악의 상태가 된다 — 사용자는 취소했다고
     * 믿고 있고, 되돌릴 방법도 없다.
     *
     * <p>Resend 는 예약 메일의 <b>시각만</b> 바꿀 수 있고 내용은 못 고친다. 그래서 화면
     * 흐름을 "예약 수정"이 아니라 "취소 → 임시보관함에서 고쳐 다시 발송"으로 만들었다.
     * 이 API 가 그 첫 단계다.
     *
     * <p>{@code @Transactional} 을 붙이지 않는다. 이 메서드는 외부 HTTP 를 부르는데,
     * 트랜잭션으로 감싸면 Resend 응답을 기다리는 내내 DB 커넥션과 행 잠금을 쥐고 있게 된다
     * (이 클래스가 발송을 트랜잭션 밖으로 뺀 것과 같은 이유). 상태 갱신만 짧게 커밋한다.
     */
    public MailSendResultDto cancelSchedule(long mailIdx, String callerUserId) {
        MailMstJdbcRow row = requireOutgoing(mailIdx);
        if (!"SCHEDULED".equals(nullToEmpty(row.sendStatus()))) {
            throw new IllegalStateException("예약 상태의 메일만 취소할 수 있습니다.");
        }
        if (StringUtils.hasText(row.resendEmailId())) {
            if (!resendClient.isEnabled()) {
                // 키가 없으면 Resend 쪽 예약을 풀 수 없다. DB 만 DRAFT 로 바꾸면
                // 예약 시각에 메일이 그대로 나간다 — 취소된 줄 알았던 메일이.
                throw new IllegalStateException(
                        "Resend API 키가 설정되지 않아 예약을 취소할 수 없습니다. 관리자에게 문의해 주세요.");
            }
            try {
                resendClient.cancelScheduled(row.resendEmailId());
            } catch (ResendApiException e) {
                // 이미 발송된 뒤라면 Resend 가 4xx 를 준다. "취소 실패"가 아니라
                // "취소할 것이 없다"는 뜻이므로 사용자에게 그렇게 설명한다.
                if (!e.retryable()) {
                    throw new IllegalStateException(
                            "이미 발송되어 예약을 취소할 수 없습니다: " + e.getMessage());
                }
                throw e;
            }
        }

        int updated = mailMstMapper.updateScheduleCancelled(mailIdx);
        if (updated == 0) {
            // Resend 취소는 됐는데 DB 만 못 바꾼 상태. 그대로 두면 화면은 예약으로 보이는데
            // 실제로는 나가지 않는다. 예외로 드러내야 담당자가 알아챈다.
            throw new IllegalStateException("예약 취소 상태를 반영하지 못했습니다.");
        }
        log.info("메일 예약 취소 mailIdx={} by={}", mailIdx, callerUserId);
        return new MailSendResultDto(mailIdx, "DRAFT", "",
                "예약을 취소했습니다. 임시보관함에서 내용을 고쳐 다시 보낼 수 있습니다.");
    }

    /**
     * 임시보관(DRAFT) → 발송 대기(QUEUED).
     *
     * <p>실패한 메일(FAILED)은 여기로 되돌리지 않는다 — 실패 사유를 확인하지 않은 채
     * 같은 메일을 반복 발송하는 사고를 막기 위해, 재시도는 {@link #dispatchOne(long)} 로만 한다.
     */
    @Transactional
    public MailSendResultDto queue(long mailIdx, String callerUserId) {
        MailMstJdbcRow row = requireOutgoing(mailIdx);
        String status = nullToEmpty(row.sendStatus());
        if ("SENT".equals(status)) {
            throw new IllegalStateException("이미 발송된 메일입니다.");
        }
        if ("QUEUED".equals(status)) {
            throw new IllegalStateException("이미 발송 대기 중인 메일입니다.");
        }
        int updated = mailMstMapper.updateSendQueued(mailIdx);
        if (updated == 0) {
            throw new IllegalStateException("임시보관 상태의 메일만 발송할 수 있습니다.");
        }
        // 임시보관함에서 보낸 메일도 즉시 시도한다 (mal001-M). compose 와 같은 이유로
        // 커밋 이후에 걸어야 선점이 성공한다.
        immediateExecutor.runAfterCommit("send-" + mailIdx, () -> dispatchNow(mailIdx));
        log.info("메일 발송 대기 등록 mailIdx={} by={}", mailIdx, callerUserId);
        return new MailSendResultDto(mailIdx, "QUEUED", "", "발송 대기열에 넣었습니다.");
    }

    /**
     * QUEUED 를 최대 limit 건 실제로 보낸다(워커 전용, 트랜잭션 없음).
     *
     * @return 성공 건수
     */
    public int dispatchQueued(int limit) {
        if (!resendClient.isEnabled()) {
            log.warn("Resend API 키가 없어 메일 발송을 건너뜁니다(RESEND_API_KEY 미설정).");
            return 0;
        }
        ResendProperties.Sync sync = properties.getSync();
        List<MailMstJdbcRow> rows = mailMstMapper.selectSendQueued(
                clampBatch(limit), sync.getMaxTryCnt(), sync.getBackoffMinutes());
        int success = 0;
        for (MailMstJdbcRow row : rows) {
            try {
                /*
                 * 선점에 실패하면 건너뛴다 (mal001-M).
                 *
                 * 예전에는 select 결과를 그대로 발송했다. 이제는 저장 직후 즉시 트리거가
                 * 같은 행을 먼저 집을 수 있으므로, select 와 실제 발송 사이에 원자적
                 * 선점을 한 단계 둔다. select 는 "후보 고르기"일 뿐이고 소유권은
                 * claimSendQueued 가 준다.
                 */
                if (!claimSend(row.mailIdx())) {
                    log.debug("이미 다른 경로가 선점한 발송 건 — 건너뛴다 mailIdx={}", row.mailIdx());
                    continue;
                }
                if ("SENT".equals(dispatchClaimed(row).sendStatus())) {
                    success++;
                }
            } catch (RuntimeException e) {
                // 한 건의 실패가 대기열 전체를 막아서는 안 된다.
                log.warn("메일 발송 실패 mailIdx={}", row.mailIdx(), e);
            }
        }
        if (!rows.isEmpty()) {
            log.info("메일 발송 {}/{}건 완료", success, rows.size());
        }
        return success;
    }

    /**
     * 저장 직후 즉시 발송 시도 (mal001-M). 전용 실행기 스레드에서만 부른다.
     *
     * <p><b>이 메서드는 최적화이지 발송의 유일한 경로가 아니다.</b> 선점에 실패하거나
     * 조건이 안 맞으면 아무 것도 하지 않고 조용히 돌아간다 — 행은 QUEUED 그대로라
     * {@code MailSendWorker} 가 안전망으로 다시 집는다. 그래서 예외를 던지지 않는다.
     *
     * <p>트랜잭션 없이 돈다(이 클래스의 대전제). 호출부가
     * {@link MailImmediateExecutor#runAfterCommit} 로 커밋 이후를 보장한다.
     */
    public void dispatchNow(long mailIdx) {
        if (!resendClient.isEnabled()) {
            return;
        }
        if (!claimSend(mailIdx)) {
            // 워커가 이미 가져갔거나 QUEUED 가 아니다(예: 백오프 중인 재시도 건).
            log.debug("즉시 발송 선점 실패 — 워커에 맡긴다 mailIdx={}", mailIdx);
            return;
        }
        MailMstJdbcRow row = mailMstMapper.selectByIdx(mailIdx);
        if (row == null || Boolean.TRUE.equals(row.deletedYn())) {
            return;
        }
        MailSendResultDto result = dispatchClaimed(row);
        log.info("즉시 발송 시도 mailIdx={} 결과={}", mailIdx, result.sendStatus());
    }

    /** 선점 시도. 성공(1건 갱신)해야 이 스레드가 그 메일을 보낼 자격을 갖는다. */
    private boolean claimSend(Long mailIdx) {
        ResendProperties.Sync sync = properties.getSync();
        return mailMstMapper.claimSendQueued(mailIdx, sync.getMaxTryCnt(), sync.getBackoffMinutes()) > 0;
    }

    /**
     * 단건 즉시 발송(수동 재시도). 트랜잭션 없음.
     *
     * <p>실패를 예외로 던지지 않고 결과 DTO 에 담아 돌려주는 이유: 이 메서드를 부른 요청이
     * 다른 작업과 한 트랜잭션에 묶여 있을 수 있는데, 예외가 올라가면 그 작업까지 되돌려진다.
     * 발송 실패는 "메일 한 통의 상태"일 뿐 호출자의 작업을 무효로 만들 사유가 아니다.
     */
    public MailSendResultDto dispatchOne(long mailIdx) {
        MailMstJdbcRow row = requireOutgoing(mailIdx);
        if ("SENT".equals(nullToEmpty(row.sendStatus()))) {
            throw new IllegalStateException("이미 발송된 메일입니다.");
        }
        if (!resendClient.isEnabled()) {
            return new MailSendResultDto(mailIdx, nullToEmpty(row.sendStatus()), "",
                    "Resend API 키가 설정되지 않아 발송할 수 없습니다. 관리자에게 문의해 주세요.");
        }
        return dispatchRow(row);
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    /**
     * 발신 메일 한 통을 저장한다(mail_mst + mail_addr_dtl + mail_body).
     *
     * <p>compose 에서 분리한 이유는 수신자 50명 초과 시 이 묶음을 여러 번 반복해야 하기
     * 때문이다. 인자가 많지만 세 테이블에 한 번에 써야 하는 값들이라 나눌 수가 없다 —
     * 중간에 하나만 저장되면 본문 없는 메일이나 수신자 없는 메일이 남는다.
     *
     * @return 새로 만들어진 mail_idx
     */
    private long insertOutgoing(long threadIdx,
                                String rfcMessageId,
                                String inReplyTo,
                                String refsTxt,
                                String subject,
                                String subjectNorm,
                                String fromEmail,
                                String fromNm,
                                List<MailAddressParser.Address> to,
                                List<MailAddressParser.Address> cc,
                                List<MailAddressParser.Address> bcc,
                                List<MailAddressParser.Address> replyTo,
                                String bodyHtml,
                                String bodyText,
                                String sendStatus,
                                OffsetDateTime scheduledAt,
                                String readReceiptYn,
                                String importance,
                                String userId,
                                Integer partnerIdx,
                                Long mappingId,
                                OffsetDateTime now) {

        MailMstInsertParam param = new MailMstInsertParam();
        param.setThreadIdx(threadIdx);
        param.setDirection("OUT");
        param.setRfcMessageId(rfcMessageId);
        param.setInReplyTo(inReplyTo);
        param.setRefsTxt(refsTxt);
        param.setSubject(subject);
        param.setSubjectNorm(subjectNorm);
        param.setFromEmail(fromEmail);
        param.setFromNm(fromNm);
        param.setToSummary(MailAddressParser.summarize(to, SUMMARY_MAX));
        param.setSnippet(MailHtmlToText.snippetOf(bodyText, bodyHtml, properties.getSnippetMaxChars()));
        param.setAttCnt(0);
        // 발신 메일의 본문은 우리가 이미 갖고 있다. PENDING 으로 두면 본문 수집 워커가
        // 있지도 않은 수신 메일을 Resend 에 물어보게 된다.
        param.setBodyStatus("DONE");
        /*
         * 예약 메일도 여기서는 QUEUED 로 둔다.
         *
         * SCHEDULED 로 바로 넣지 않는 이유: 예약은 우리가 시각을 지키는 것이 아니라
         * Resend 에 맡기는 것이라, 먼저 Resend 에 넘겨 email id 를 받아 와야 비로소
         * "예약됨"이다. 그 호출은 워커가 트랜잭션 밖에서 하고(이 클래스의 대전제),
         * 성공하면 updateScheduled 가 send_status 를 SCHEDULED 로 올린다.
         *
         * 그 사이 짧은 동안(워커 주기 10초) 예약 메일이 임시보관함에 보인다. 예약메일함에
         * 먼저 띄웠다가 Resend 호출이 실패하면 "예약됐다고 표시된 안 나갈 메일"이 남는데,
         * 그쪽이 훨씬 나쁘다.
         */
        param.setSendStatus(sendStatus);
        // 내가 쓴 메일을 나에게 안 읽음으로 표시할 이유가 없다.
        param.setReadYn("Y");
        param.setUserId(userId);
        param.setPartnerIdx(partnerIdx);
        param.setMappingId(mappingId);
        param.setMailAt(now);
        param.setScheduledAt(scheduledAt);
        param.setReadReceiptYn(readReceiptYn);
        param.setImportance(importance);
        mailMstMapper.insert(param);

        Long mailIdx = param.getMailIdx();
        if (mailIdx == null) {
            throw new IllegalStateException("메일 저장에 실패했습니다.");
        }

        List<MailAddrDtlJdbcRow> addresses = new ArrayList<>();
        appendAddresses(addresses, mailIdx, "FROM",
                List.of(new MailAddressParser.Address(fromEmail, nullToEmpty(fromNm))));
        appendAddresses(addresses, mailIdx, "TO", to);
        appendAddresses(addresses, mailIdx, "CC", cc);
        appendAddresses(addresses, mailIdx, "BCC", bcc);
        appendAddresses(addresses, mailIdx, "REPLY_TO", replyTo);
        mailAddrMapper.insertBatch(mailIdx, addresses);

        Set<String> participants = new LinkedHashSet<>();
        participants.add(fromEmail);
        participants.addAll(MailAddressParser.emails(to));
        participants.addAll(MailAddressParser.emails(cc));
        participants.addAll(MailAddressParser.emails(bcc));
        int bodyMaxBytes = properties.getBodyMaxBytes();
        boolean truncated = MailSearchTextBuilder.exceedsBytes(bodyText, bodyMaxBytes)
                || MailSearchTextBuilder.exceedsBytes(bodyHtml, bodyMaxBytes);
        mailBodyMapper.upsert(
                mailIdx,
                MailSearchTextBuilder.truncateToBytes(bodyText, bodyMaxBytes),
                MailSearchTextBuilder.truncateToBytes(bodyHtml, bodyMaxBytes),
                null,
                MailSearchTextBuilder.build(subject, participants, bodyText, properties.getSearchMaxBytes()),
                truncated);

        return mailIdx;
    }

    /**
     * 수신자를 Resend 상한({@link #RESEND_TO_LIMIT})씩 자른다.
     *
     * <p>50명 이하면 원본 리스트를 그대로 담은 한 덩어리를 준다 — 대부분의 발송이
     * 여기 해당하므로 불필요한 복사를 하지 않는다.
     */
    private static List<List<MailAddressParser.Address>> chunkRecipients(
            List<MailAddressParser.Address> to) {

        if (to.size() <= RESEND_TO_LIMIT) {
            return List.of(to);
        }
        List<List<MailAddressParser.Address>> chunks = new ArrayList<>();
        for (int start = 0; start < to.size(); start += RESEND_TO_LIMIT) {
            chunks.add(List.copyOf(to.subList(start, Math.min(start + RESEND_TO_LIMIT, to.size()))));
        }
        return chunks;
    }

    /**
     * 예약 시각 검증.
     *
     * <p>과거 시각을 거부하는 이유: Resend 는 지난 {@code scheduled_at} 을 받으면 즉시
     * 발송해 버린다. 사용자는 "예약했는데 바로 나갔다"고 느끼고, 되돌릴 방법도 없다.
     *
     * <p>{@link #SCHEDULE_MAX_DAYS} 상한은 Resend 제한이다. 넘겨 보내면 발송 시점에
     * 4xx 가 나는데, 그때는 이미 작성 화면을 떠난 뒤라 사용자가 원인을 알 수 없다.
     * 여기서 막아야 작성 중에 알려 줄 수 있다.
     *
     * <p>{@code MIN_LEAD_SECONDS} 를 두는 이유: "1초 뒤" 같은 예약은 워커가 Resend 에
     * 넘기기도 전에 시각이 지나 버린다. 그러면 예약이 아니라 그냥 발송이다.
     */
    private static OffsetDateTime normalizeScheduledAt(OffsetDateTime scheduledAt, OffsetDateTime now) {
        if (scheduledAt == null) {
            return null;
        }
        if (scheduledAt.isBefore(now.plusSeconds(MIN_LEAD_SECONDS))) {
            throw new IllegalArgumentException(
                    "예약 시각은 지금부터 " + MIN_LEAD_SECONDS + "초 이후여야 합니다.");
        }
        if (scheduledAt.isAfter(now.plusDays(SCHEDULE_MAX_DAYS))) {
            throw new IllegalArgumentException(
                    "예약은 최대 " + SCHEDULE_MAX_DAYS + "일 뒤까지만 가능합니다.");
        }
        return scheduledAt;
    }

    /** 중요도 정규화. 빈 값·모르는 값은 보통(N)으로 본다 — 발송을 막을 만한 사안이 아니다. */
    private static String normalizeImportance(String importance) {
        if (!StringUtils.hasText(importance)) {
            return "N";
        }
        String value = importance.trim().toUpperCase(java.util.Locale.ROOT);
        return switch (value) {
            case "H", "HIGH" -> "H";
            case "L", "LOW" -> "L";
            default -> "N";
        };
    }

    /** 작성 결과 안내 문구. 나뉘어 나가는 경우를 감추지 않는다 — 보낸메일함 건수와 맞아야 한다. */
    private static String composeMessage(boolean sendNow,
                                         OffsetDateTime scheduledAt,
                                         int recipientCnt,
                                         int chunkCnt) {
        String split = chunkCnt > 1
                ? " 받는 사람이 " + recipientCnt + "명이라 " + chunkCnt + "통으로 나뉘어 나갑니다."
                : "";
        if (!sendNow) {
            return "임시 저장했습니다." + split;
        }
        if (scheduledAt != null) {
            return "예약 발송을 등록했습니다." + split;
        }
        return "발송 대기열에 넣었습니다." + split;
    }

    /**
     * 보내는 사람 주소를 정한다. <b>요청 값을 그대로 믿지 않는다.</b>
     *
     * <p>Resend 는 "검증된 도메인인가"만 확인하므로 자사 도메인 안의 임의 로컬파트는 전부
     * 통과한다. 요청 본문의 fromEmail 을 무조건 우선하면, mal001 생성 권한만 있는 사원이
     * {@code ceo@우리도메인} 으로 회사 DKIM 서명이 붙은 메일을 거래처에 보낼 수 있고
     * mail_mst.from_email 에도 그 주소가 남아 발신 이력까지 오염된다.
     *
     * <p>그래서 서버 설정에 등록된 주소(resend.from-email + resend.allowed-from-emails)만
     * 받아들이고, 그 밖이면 조용히 바꿔치기하지 않고 거부한다 — 사용자가 "대표 명의로
     * 보냈다"고 오해한 채 다른 주소로 나가는 편이 더 나쁘다.
     */
    private String resolveFromEmail(String requested) {
        // normalizeEmail 은 null 을 "" 로 돌려준다(널 검사가 따로 필요 없다).
        String fallback = MailAddressParser.normalizeEmail(properties.getFromEmail());
        String candidate = MailAddressParser.normalizeEmail(requested);
        if (!candidate.isEmpty() && !candidate.equalsIgnoreCase(fallback)) {
            if (!properties.isFromEmailAllowed(candidate)) {
                log.warn("허용되지 않은 발신 주소 요청을 거부했습니다. requested={}", candidate);
                throw new IllegalArgumentException(
                        "허용되지 않은 보내는 사람 주소입니다: " + candidate);
            }
            return candidate;
        }
        if (fallback.isEmpty()) {
            // 키와 마찬가지로 앱을 죽이지 않고, 무엇을 설정해야 하는지만 알린다.
            throw new IllegalStateException(
                    "보내는 사람 주소가 설정되지 않았습니다. 환경변수 RESEND_FROM_EMAIL 을 설정해 주세요.");
        }
        return fallback;
    }

    /**
     * 수동 재시도 경로({@link #dispatchOne}) 전용.
     *
     * <p>여기서는 선점을 하지 않는다. 대상이 QUEUED 가 아닐 수 있고(DRAFT·FAILED 를
     * 사람이 직접 다시 보내는 흐름), 사람이 명시적으로 누른 재시도를 조건 불일치로
     * 조용히 삼키면 화면에 아무 반응이 없어 원인을 알 수 없다.
     */
    private MailSendResultDto dispatchRow(MailMstJdbcRow row) {
        final long mailIdx = row.mailIdx();
        // 시도 횟수를 먼저 커밋해 둔다. 호출 도중 프로세스가 죽어도 무한 재시도로 번지지 않는다.
        txTemplate.executeWithoutResult(status -> mailMstMapper.markSendTried(mailIdx));
        return dispatchClaimed(row);
    }

    /**
     * 선점이 끝난 뒤의 실제 발송 (mal001-M).
     *
     * <p>{@code claimSendQueued} 가 이미 {@code send_try_cnt}/{@code send_tried_at} 을
     * 올려 커밋했으므로 여기서 다시 {@code markSendTried} 를 부르면 시도 횟수가 두 배로
     * 소모돼 maxTryCnt 에 절반 만에 도달한다. 그래서 시도 기록은 호출부(선점)가 맡고
     * 이 메서드는 발송과 결과 반영만 한다.
     *
     * <p>{@code row} 는 선점 이전에 읽은 값이라 {@code sendTryCnt} 가 1 낮다. 아래
     * 재시도 판정이 {@code +1} 을 하는 것이 그 보정이다(기존 markSendTried 경로와 동일).
     */
    private MailSendResultDto dispatchClaimed(MailMstJdbcRow row) {
        final long mailIdx = row.mailIdx();

        ResendSendRequestDto request;
        try {
            request = buildRequest(row);
        } catch (RuntimeException e) {
            // 본문·수신자가 없는 등 데이터 자체가 잘못된 경우. 재시도해도 같으므로 즉시 확정한다.
            return failed(mailIdx, clip(rootMessage(e), ERR_MAX), true);
        }

        try {
            String resendEmailId = resendClient.sendEmail(request, "mail-" + mailIdx);
            OffsetDateTime sentAt = OffsetDateTime.now();
            String emailId = clip(resendEmailId, RESEND_ID_MAX);

            /*
             * 예약 메일은 SENT 가 아니라 SCHEDULED 로 확정한다 (mal001-F).
             *
             * Resend 가 200 을 준 것은 "예약을 접수했다"는 뜻이지 "보냈다"가 아니다.
             * SENT 로 기록하면 아직 나가지도 않은 메일이 보낸메일함에 나타나고,
             * 예약메일함은 비어 사용자가 취소할 대상을 찾지 못한다.
             *
             * 아직 시각이 남은 경우에만 SCHEDULED 다. 예약 시각이 이미 지났다면
             * Resend 가 즉시 보내므로 그냥 SENT 로 둔다.
             */
            OffsetDateTime scheduledAt = row.scheduledAt();
            if (scheduledAt != null && scheduledAt.isAfter(sentAt)) {
                txTemplate.executeWithoutResult(status ->
                        mailMstMapper.updateScheduled(mailIdx, scheduledAt, emailId));
                log.info("메일 예약 접수 mailIdx={} scheduledAt={}", mailIdx, scheduledAt);
                return new MailSendResultDto(mailIdx, "SCHEDULED", emailId, "예약 발송이 등록되었습니다.");
            }

            txTemplate.executeWithoutResult(status ->
                    mailMstMapper.updateSendSent(mailIdx, emailId, sentAt));
            log.info("메일 발송 완료 mailIdx={}", mailIdx);
            return new MailSendResultDto(mailIdx, "SENT", emailId, "메일을 발송했습니다.");
        } catch (ResendApiException e) {
            int tried = (row.sendTryCnt() == null ? 0 : row.sendTryCnt()) + 1;
            if (e.retryable() && tried < properties.getSync().getMaxTryCnt()) {
                // QUEUED 를 그대로 둔다. 백오프가 지나면 워커가 다시 집어 간다.
                log.warn("메일 발송 일시 실패(재시도 예정) mailIdx={} status={} try={}",
                        mailIdx, e.statusCode(), tried);
                return new MailSendResultDto(mailIdx, "QUEUED", "",
                        "일시적인 오류로 발송을 다시 시도합니다: " + e.getMessage());
            }
            // 비재시도성 4xx(422 등)는 다시 보내도 같은 결과다. 시도 횟수가 남아 있어도
            // 여기서 확정하지 않으면 DB 는 QUEUED 로 되돌아가 워커가 헛발송을 반복한다.
            return failed(mailIdx, clip(e.getMessage(), ERR_MAX), !e.retryable());
        }
    }

    /**
     * 발송 실패를 DB 에 되쓴다.
     *
     * <p>{@code permanent} 는 "재시도해도 결과가 같은가"다. false 면 매퍼가 시도 횟수를 보고
     * QUEUED(재시도 대기)/FAILED(소진)를 정한다. 임계값을 매퍼에 박아 두지 않고 설정값을
     * 넘기는 이유는 selectSendQueued 의 조건과 반드시 같은 숫자여야 하기 때문이다.
     */
    private MailSendResultDto failed(long mailIdx, String message, boolean permanent) {
        int maxTryCnt = properties.getSync().getMaxTryCnt();
        txTemplate.executeWithoutResult(status ->
                mailMstMapper.updateSendFailed(mailIdx, message, maxTryCnt, permanent));
        log.warn("메일 발송 실패 확정 mailIdx={} permanent={} 사유={}", mailIdx, permanent, message);
        return new MailSendResultDto(mailIdx, "FAILED", "", message);
    }

    /** DB 에 저장된 메일을 Resend 발송 요청으로 변환한다. */
    private ResendSendRequestDto buildRequest(MailMstJdbcRow row) {
        long mailIdx = row.mailIdx();
        List<MailAddrDtlJdbcRow> addresses = mailAddrMapper.selectByMailIdx(mailIdx);
        List<String> to = emailsOf(addresses, "TO");
        if (to.isEmpty()) {
            throw new IllegalStateException("받는 사람이 없어 발송할 수 없습니다.");
        }
        MailBodyJdbcRow body = mailBodyMapper.selectByMailIdx(mailIdx);
        String html = body == null ? null : body.bodyHtml();
        String text = body == null ? null : body.bodyText();
        if (!StringUtils.hasText(html) && !StringUtils.hasText(text)) {
            throw new IllegalStateException("본문이 없어 발송할 수 없습니다.");
        }

        Map<String, String> headers = new LinkedHashMap<>();
        // 답장임을 수신자 메일 클라이언트가 알아보게 하는 표준 헤더. 이 두 개가 없으면
        // 상대방 받은편지함에서 새 대화로 갈라진다.
        if (StringUtils.hasText(row.inReplyTo())) {
            headers.put("In-Reply-To", MailMessageIdUtil.angled(row.inReplyTo()));
        }
        if (StringUtils.hasText(row.refsTxt())) {
            headers.put("References", row.refsTxt().trim());
        }
        /*
         * 중요도 (mal001-H).
         *
         * 세 헤더를 함께 보낸다. 표준이 하나로 정리된 적이 없어서 클라이언트마다 보는
         * 헤더가 다르다 — Outlook 은 X-Priority 와 Importance 를, 일부 웹메일은 Importance
         * 만, 오래된 클라이언트는 X-MSMail-Priority 만 본다. 하나만 넣으면 어디선가는
         * 표시가 안 되고, 셋을 넣어도 부작용은 없다.
         *
         * 낮음(L)도 함께 표현한다. 보통(N)은 헤더를 아예 넣지 않는다 — 기본값이라
         * 명시할 이유가 없고, 헤더가 많을수록 스팸 필터 점수에 불리하다.
         *
         * 이 헤더를 존중할지는 전적으로 수신자 클라이언트에 달렸다. 무시하는 웹메일이 많다.
         */
        /*
         * 자동전달로 만들어진 메일 표시 (mal001-L).
         *
         * RFC 3834 가 정한 헤더다. 자동응답기(부재중 알림 등)는 이 헤더가 있으면 답장하지
         * 않게 되어 있다. 우리 쪽 무한 전달 방어는 fwd_src_idx 표시와 발신 주소 검사가
         * 맡지만, 그 방어는 <b>우리 시스템 안에서만</b> 유효하다. 전달받은 쪽이 다른
         * 메일 시스템이면 이 헤더가 유일한 신호다.
         */
        if (row.fwdSrcIdx() != null) {
            headers.put("Auto-Submitted", "auto-forwarded");
        }

        String importance = nullToEmpty(row.importance());
        if ("H".equals(importance)) {
            headers.put("X-Priority", "1");
            headers.put("X-MSMail-Priority", "High");
            headers.put("Importance", "high");
        } else if ("L".equals(importance)) {
            headers.put("X-Priority", "5");
            headers.put("X-MSMail-Priority", "Low");
            headers.put("Importance", "low");
        }

        /*
         * 수신확인 추적픽셀 (mal001-G).
         *
         * **DB 에 저장된 본문은 건드리지 않는다.** 픽셀은 나가는 요청에만 섞는다.
         * 저장 본문에 심어 버리면 (1) 우리 화면에서 내 메일을 열 때마다 내 열람수가 오르고,
         * (2) 재발송할 때 픽셀이 두 겹으로 붙어 한 번 열람에 카운트가 2씩 오른다.
         *
         * 평문(text) 파트에는 넣지 않는다 — 평문에는 이미지를 심을 수 없고, 눈에 보이는
         * URL 만 남으면 수신자에게 추적 사실을 알릴 뿐 얻는 것이 없다.
         */
        String outboundHtml = html;
        if ("Y".equals(nullToEmpty(row.readReceiptYn()))
                && properties.isTrackingConfigured()
                && StringUtils.hasText(outboundHtml)) {
            try {
                String pixelUrl = properties.buildTrackingPixelUrl(
                        MailOpenTokenCodec.encode(mailIdx, properties.resolveTrackingSecret()));
                if (!MailTrackingPixel.contains(outboundHtml, pixelUrl)) {
                    outboundHtml = MailTrackingPixel.inject(outboundHtml, pixelUrl);
                }
            } catch (RuntimeException e) {
                // 픽셀을 못 만든다고 메일을 못 보낼 이유는 없다. 수신확인만 포기한다.
                log.warn("추적픽셀 생성 실패 — 수신확인 없이 발송한다. mailIdx={}", mailIdx, e);
            }
        }

        List<ResendSendAttachmentDto> attachments = mailAttachmentService.buildSendAttachments(mailIdx);

        return new ResendSendRequestDto(
                formatFrom(row.fromNm(), row.fromEmail()),
                to,
                nullIfEmpty(emailsOf(addresses, "CC")),
                nullIfEmpty(emailsOf(addresses, "BCC")),
                nullIfEmpty(emailsOf(addresses, "REPLY_TO")),
                nullToEmpty(row.subject()),
                StringUtils.hasText(outboundHtml) ? outboundHtml : null,
                StringUtils.hasText(text) ? text : null,
                headers.isEmpty() ? null : headers,
                attachments.isEmpty() ? null : attachments,
                // 예약 시각은 ISO-8601 로 넘긴다. Resend 가 자연어("in 1 min")도 받지만
                // 해석 규칙이 문서화돼 있지 않아 우리 쪽에서 애매함을 남기지 않는다.
                row.scheduledAt() == null
                        ? null
                        : row.scheduledAt().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME));
    }

    /**
     * {@code 역전에프앤씨 <no-reply@x.com>} 형태로 만든다.
     * 표시이름에 콤마·꺾쇠가 있으면 따옴표로 감싸야 헤더가 두 명으로 쪼개지지 않는다.
     */
    private static String formatFrom(String name, String email) {
        String address = nullToEmpty(email);
        String display = name == null ? "" : name.trim();
        if (display.isEmpty()) {
            return address;
        }
        if (display.indexOf(',') >= 0 || display.indexOf('<') >= 0
                || display.indexOf('>') >= 0 || display.indexOf('"') >= 0) {
            display = "\"" + display.replace("\"", "'") + "\"";
        }
        return display + " <" + address + ">";
    }

    private MailMstJdbcRow findParent(Long replyToMailIdx) {
        if (replyToMailIdx == null || replyToMailIdx <= 0) {
            return null;
        }
        MailMstJdbcRow parent = mailMstMapper.selectByIdx(replyToMailIdx);
        if (parent == null || Boolean.TRUE.equals(parent.deletedYn())) {
            throw new ResourceNotFoundException("원본 메일", "mailIdx", replyToMailIdx);
        }
        return parent;
    }

    private MailMstJdbcRow requireOutgoing(long mailIdx) {
        MailMstJdbcRow row = mailMstMapper.selectByIdx(mailIdx);
        if (row == null || Boolean.TRUE.equals(row.deletedYn())) {
            throw new ResourceNotFoundException("메일", "mailIdx", mailIdx);
        }
        if (!"OUT".equals(row.direction())) {
            throw new IllegalStateException("발신 메일만 발송할 수 있습니다.");
        }
        return row;
    }

    private static List<String> emailsOf(List<MailAddrDtlJdbcRow> rows, String addrType) {
        if (rows == null || rows.isEmpty()) {
            return List.of();
        }
        Set<String> unique = new LinkedHashSet<>();
        for (MailAddrDtlJdbcRow row : rows) {
            if (addrType.equals(row.addrType()) && StringUtils.hasText(row.email())) {
                unique.add(row.email().trim());
            }
        }
        return unique.isEmpty() ? List.of() : new ArrayList<>(unique);
    }

    private static List<String> nullIfEmpty(List<String> values) {
        // Resend 요청 DTO 는 NON_NULL 직렬화라, 빈 배열 대신 null 을 넣어야 필드가 아예 빠진다.
        return values == null || values.isEmpty() ? null : values;
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

    private static int clampBatch(int limit) {
        return limit <= 0 ? 1 : Math.min(limit, MAX_BATCH);
    }

    private static String clip(String value, int max) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.length() <= max ? trimmed : trimmed.substring(0, max);
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
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

    private static String rootMessage(Throwable e) {
        Throwable cursor = e;
        while (cursor.getCause() != null && cursor.getCause() != cursor) {
            cursor = cursor.getCause();
        }
        String message = cursor.getMessage();
        return StringUtils.hasText(message) ? message : cursor.getClass().getSimpleName();
    }
}
