package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.dto.MailAddrDtlJdbcRow;
import com.yeokjeon.erp.mail.dto.MailBodyJdbcRow;
import com.yeokjeon.erp.mail.dto.MailForwardRuleJdbcRow;
import com.yeokjeon.erp.mail.dto.MailForwardSettingJdbcRow;
import com.yeokjeon.erp.mail.dto.MailMstJdbcRow;
import com.yeokjeon.erp.mail.dto.MailRuleJdbcRow;
import com.yeokjeon.erp.mail.dto.MailSendRequestDto;
import com.yeokjeon.erp.mail.dto.MailSendResultDto;
import com.yeokjeon.erp.mail.dto.MailUserRefJdbcRow;
import com.yeokjeon.erp.mail.mapper.MailAddrMapper;
import com.yeokjeon.erp.mail.mapper.MailBodyMapper;
import com.yeokjeon.erp.mail.mapper.MailForwardMapper;
import com.yeokjeon.erp.mail.mapper.MailMstMapper;
import com.yeokjeon.erp.mail.mapper.MailRecipientMapper;
import com.yeokjeon.erp.mail.mapper.MailRuleMapper;
import com.yeokjeon.erp.mail.support.MailHtmlToText;
import com.yeokjeon.erp.mail.support.MailRuleMatcher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * 수신 메일 자동 처리 — 자동분류 규칙 적용(mal001-K) + 자동전달(mal001-L).
 *
 * <p><b>왜 별도 서비스인가.</b> {@link MailReceiveService} 는 "Resend 가 준 것을 그대로
 * 적재한다"가 전부여야 한다. 사용자 설정에 따라 메일이 옮겨지거나 밖으로 나가는 판단은
 * 성격이 전혀 다르고, 무엇보다 <b>실패해도 적재는 살아남아야</b> 한다. 두 관심사를 한
 * 클래스에 두면 언젠가 한 트랜잭션으로 묶이고, 그 순간 규칙 하나가 잘못돼서 메일을
 * 통째로 못 받는 사고가 난다.
 *
 * <p><b>호출부가 예외를 삼킨다.</b> 이 클래스의 공개 메서드는 {@code @Transactional} 이라
 * 예외가 나면 자기 트랜잭션만 롤백된다. 그 예외를 잡는 try/catch 는 반드시
 * {@link MailReceiveService} 쪽(=프록시 바깥)에 있어야 한다. 같은 빈 안에서 잡으면
 * 스프링이 트랜잭션을 rollback-only 로 표시해 둔 상태라 커밋 시점에
 * {@code UnexpectedRollbackException} 이 터진다({@code MailWebhookService} 주석과 같은 함정).
 *
 * <p><b>"누구의 설정을 적용할 것인가."</b> 이 ERP 의 받은메일함은 개인 사서함이 아니라
 * 공용 이력이라 {@code mail_mst.user_id} 가 수신 시점에 비어 있다(담당자는 사람이 화면에서
 * 배정한다). 그런데 규칙·전달은 개인 설정이다. 그래서 <b>수신자 주소로 사원을 되짚어</b>
 * 그 사람의 설정을 적용한다. TO 를 먼저 보고 없으면 CC 를 본다 — 받는사람이 참조자보다
 * 주인일 가능성이 높다. 사내 수신자를 못 찾으면 아무 것도 하지 않는다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailAutoProcessService {

    /** 규칙 처리: 메일함 이동 */
    private static final String ACTION_MOVE = "MOVE";

    /** 전달 예외 규칙: 주소 완전일치 */
    private static final String MATCH_EMAIL = "EMAIL";

    /** 전달 메일 제목 앞에 붙이는 표시. 이미 붙어 있으면 두 번 붙이지 않는다. */
    private static final String FWD_PREFIX = "FW: ";

    private static final int SUBJECT_MAX = 500;

    private static final DateTimeFormatter STAMP =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    private final MailMstMapper mailMstMapper;
    private final MailAddrMapper mailAddrMapper;
    private final MailBodyMapper mailBodyMapper;
    private final MailRuleMapper mailRuleMapper;
    private final MailForwardMapper mailForwardMapper;
    private final MailRecipientMapper mailRecipientMapper;
    private final MailSendService mailSendService;
    private final ResendProperties properties;

    /**
     * 자동분류 규칙 적용 — 수신 저장 <b>직후</b>에 부른다.
     *
     * <p>웹훅 페이로드에 이미 들어 있는 값(보낸사람·수신자·제목)만으로 판정하므로 본문
     * 수집을 기다릴 필요가 없다. 사용자 입장에서도 메일이 목록에 뜨는 순간 이미 분류돼
     * 있어야 자연스럽다.
     *
     * <p>규칙은 sort_order 순으로 훑어 <b>첫 매칭 하나만</b> 적용한다. 여러 개를 적용하면
     * folder_idx 를 덮어써서 결과가 규칙 순서에 좌우되는데, 그 동작은 사용자가 예측할 수 없다.
     *
     * @return 규칙이 하나라도 걸렸으면 true(로그·시험용)
     */
    @Transactional
    public boolean applyRules(long mailIdx) {
        MailMstJdbcRow mail = mailMstMapper.selectByIdx(mailIdx);
        if (!isRuleTarget(mail)) {
            return false;
        }
        List<MailAddrDtlJdbcRow> addresses = mailAddrMapper.selectByMailIdx(mailIdx);
        String owner = resolveOwnerUserId(addresses);
        if (owner == null) {
            log.debug("사내 수신자를 찾지 못해 자동분류를 건너뛴다 mailIdx={}", mailIdx);
            return false;
        }
        List<MailRuleJdbcRow> rules = mailRuleMapper.selectActiveByUserId(owner);
        if (rules.isEmpty()) {
            return false;
        }

        String fromEmail = lower(mail.fromEmail());
        String subject = mail.subject() == null ? "" : mail.subject();
        // 다우오피스의 "수신자(참조 포함)" 는 받는사람과 참조를 한 조건으로 묶는다.
        Set<String> recipients = emailsOf(addresses, "TO", "CC");

        for (MailRuleJdbcRow rule : rules) {
            if (!matches(rule, fromEmail, recipients, subject)) {
                continue;
            }
            if (ACTION_MOVE.equals(rule.actionType())) {
                int moved = mailMstMapper.updateRuleFolder(mailIdx, rule.actionFolderIdx());
                log.info("자동분류 규칙 적용(이동) mailIdx={} ruleIdx={} folderIdx={} 갱신={}건",
                        mailIdx, rule.mailRuleIdx(), rule.actionFolderIdx(), moved);
            } else {
                mailMstMapper.updateReadYn(mailIdx, "Y");
                log.info("자동분류 규칙 적용(읽음) mailIdx={} ruleIdx={}",
                        mailIdx, rule.mailRuleIdx());
            }
            return true;
        }
        return false;
    }

    /**
     * 자동전달 — <b>본문 수집이 끝난 뒤</b>에 부른다.
     *
     * <p>수신 저장 직후가 아닌 이유가 핵심이다. Resend 수신 웹훅에는 본문이 없어서
     * ({@link MailReceiveService} 클래스 주석 참고) 그 시점에 전달하면 <b>본문이 빈 메일</b>이
     * 나간다. 받는 사람은 그게 전달된 메일인지도 알 수 없다. 그래서 본문이 채워진 뒤로 미룬다.
     *
     * <p>대신 본문 수집이 끝내 실패한 메일은 전달되지 않는다. 빈 메일을 보내는 것보다
     * 안 보내는 편이 낫다고 판단했다(발송 실패는 로그에 남고, 원본은 받은메일함에 그대로 있다).
     *
     * <p><b>무한 전달 방지가 이 메서드의 가장 중요한 책임이다.</b> 아래 다섯 겹이 있다.
     * <ol>
     *   <li>{@code fwd_src_idx} 표시가 있는 메일은 대상에서 제외 — 전달로 만들어진 메일</li>
     *   <li>이미 전달한 원본은 제외({@code countByFwdSrcIdx}) — 본문 수동 재수집 대비</li>
     *   <li>보낸사람이 <b>우리 시스템 발신 주소</b>면 제외 — 전달 메일이 외부를 돌아
     *       수신으로 되돌아온 경우다. 새 행이라 1·2번으로는 못 잡는 유일한 경로다</li>
     *   <li>전달 대상이 원본 발신자·원본 수신자·우리 발신 주소면 제외 — 곧바로 되돌아온다</li>
     *   <li>나가는 메일에 {@code Auto-Submitted: auto-forwarded}(RFC 3834) — 상대편
     *       자동응답기가 되받아치지 않게 한다</li>
     * </ol>
     *
     * @return 실제로 전달을 만들었으면 true
     */
    @Transactional
    public boolean autoForward(long mailIdx) {
        MailMstJdbcRow mail = mailMstMapper.selectByIdx(mailIdx);
        if (!isForwardTarget(mail)) {
            return false;
        }
        List<MailAddrDtlJdbcRow> addresses = mailAddrMapper.selectByMailIdx(mailIdx);
        String owner = resolveOwnerUserId(addresses);
        if (owner == null) {
            return false;
        }

        String fromEmail = lower(mail.fromEmail());
        Target target = resolveTarget(owner, fromEmail);
        if (target == null) {
            return false;
        }
        if (!isSafeTarget(target.email(), fromEmail, emailsOf(addresses, "TO", "CC", "BCC"))) {
            log.warn("자동전달 대상이 루프를 만들 수 있어 건너뛴다 mailIdx={} target={}",
                    mailIdx, target.email());
            return false;
        }

        MailBodyJdbcRow body = mailBodyMapper.selectByMailIdx(mailIdx);
        String html = body == null ? null : body.bodyHtml();
        String text = body == null ? null : body.bodyText();
        if (!StringUtils.hasText(text)) {
            text = MailHtmlToText.toPlainText(html);
        }
        if (!StringUtils.hasText(html) && !StringUtils.hasText(text)) {
            log.debug("본문이 아직 없어 자동전달을 미룬다 mailIdx={}", mailIdx);
            return false;
        }

        MailSendRequestDto request = new MailSendRequestDto(
                // 발신 주소는 서버 설정값을 쓴다. 원본 발신자로 위장해 보내면 SPF/DKIM 이
                // 깨져 스팸으로 처리되고, 애초에 우리 도메인 밖 주소는 Resend 가 거부한다.
                null,
                null,
                List.of(target.email()),
                null,
                null,
                // 회신처를 원본 발신자로 둔다. 그래야 전달받은 사람이 "답장"을 누르면
                // 우리 시스템이 아니라 진짜 상대에게 간다.
                StringUtils.hasText(fromEmail) ? List.of(fromEmail) : null,
                forwardSubject(mail.subject()),
                StringUtils.hasText(html) ? forwardHtml(mail, html) : null,
                forwardText(mail, text),
                null,
                mail.partnerIdx(),
                null,
                // 즉시 발송 대기열에 넣는다. 전달은 사람이 다시 확인할 성질이 아니다.
                Boolean.TRUE,
                null,
                // 전달 메일에 수신확인을 걸지 않는다. 원본 발신자가 요청한 것도 아니고,
                // 추적픽셀이 두 겹으로 붙으면 열람 카운트가 어긋난다.
                Boolean.FALSE,
                mail.importance());

        MailSendResultDto result = mailSendService.compose(request, owner);
        // 표시를 남기는 것이 무한 전달을 막는 장치다. compose 요청 DTO 에 필드를 열지 않고
        // 사후에 찍는 이유는, 그 DTO 가 화면이 보내는 값이라 클라이언트가 임의의 메일을
        // "전달로 생성된 것"으로 표시해 규칙 적용에서 빼돌릴 수 있게 되기 때문이다.
        mailMstMapper.updateFwdSrcIdx(result.mailIdx(), mailIdx);

        if (target.deleteOriginal()) {
            // 원본 삭제는 소프트 삭제다(휴지통). 받은메일함이 공용이라 다른 사람 화면에서도
            // 사라지므로, 되돌릴 수 있는 형태여야 한다.
            mailMstMapper.softDelete(mailIdx);
            log.info("자동전달 후 원본을 휴지통으로 보냄 mailIdx={}", mailIdx);
        }
        log.info("자동전달 실행 원본={} 전달메일={} 대상={} 예외규칙={}",
                mailIdx, result.mailIdx(), target.email(), target.byException());
        return true;
    }

    // ── 대상 판정 ───────────────────────────────────────────────────────────

    /** 전달 대상 한 건. 어디서 온 설정인지에 따라 원본 삭제 여부가 갈린다. */
    private record Target(String email, boolean byException, boolean deleteOriginal) {
    }

    private boolean isRuleTarget(MailMstJdbcRow mail) {
        if (mail == null || Boolean.TRUE.equals(mail.deletedYn())) {
            return false;
        }
        // 규칙은 받은 메일에만 건다. 내가 쓴 메일이 내 규칙에 걸려 메일함을 옮겨 다니면
        // 보낸메일함에서 사라진 것처럼 보인다.
        if (!"IN".equals(mail.direction())) {
            return false;
        }
        // 전달로 만들어진 메일은 규칙 대상이 아니다(무한 전달 방지 1겹).
        return mail.fwdSrcIdx() == null;
    }

    private boolean isForwardTarget(MailMstJdbcRow mail) {
        if (!isRuleTarget(mail)) {
            return false;
        }
        // 스팸으로 분류된 메일을 남에게 전달하지 않는다. 전달받은 쪽에서는 그것이
        // 스팸인지 알 수 없고, 우리 도메인 발신 평판만 깎인다.
        if ("Y".equals(mail.spamYn())) {
            return false;
        }
        long mailIdx = mail.mailIdx() == null ? 0L : mail.mailIdx();
        if (mailIdx <= 0) {
            return false;
        }
        // 이미 전달한 원본(무한 전달 방지 2겹). 본문 수동 재수집이 이 경로를 다시 탄다.
        if (mailMstMapper.countByFwdSrcIdx(mailIdx) > 0) {
            log.debug("이미 자동전달한 메일이라 건너뛴다 mailIdx={}", mailIdx);
            return false;
        }
        /*
         * 무한 전달 방지 3겹 — 되돌아온 우리 메일.
         *
         * 전달 대상이 우리가 수신도 하는 도메인이면, 전달로 나간 메일이 웹훅을 타고
         * 다시 들어온다. 그 행은 새로 만들어진 것이라 fwd_src_idx 표시가 없어 1·2겹으로는
         * 잡히지 않는다. 다만 보낸사람이 <b>우리 시스템 발신 주소</b>라는 흔적이 남는다
         * (전달 메일은 언제나 resend.from-email 로 나간다). 그것으로 끊는다.
         */
        if (properties.isFromEmailAllowed(mail.fromEmail())) {
            log.debug("우리 발신 주소에서 온 메일이라 자동전달을 건너뛴다 mailIdx={} from={}",
                    mailIdx, mail.fromEmail());
            return false;
        }
        return true;
    }

    /**
     * 전달 주소를 정한다. <b>예외 규칙이 전체 설정보다 우선한다.</b>
     *
     * <p>예외 규칙의 존재 이유가 "전체 전달과 다르게 보내기"라서, 전체 설정이 이기면
     * 기능 자체가 무의미해진다. 예외 규칙은 전체 자동전달이 꺼져 있어도 동작한다 —
     * 세금계산서만 회계 담당에게 보내고 나머지는 전달하지 않는 쓰임이 실제로 많다.
     *
     * <p>원본 삭제는 <b>전체 자동전달일 때만</b> 적용한다. 예외 규칙은 "이 발신자는 다른
     * 사람이 처리한다"는 뜻이지 "내 이력에서 지운다"는 뜻이 아니다.
     */
    private Target resolveTarget(String ownerUserId, String fromEmail) {
        for (MailForwardRuleJdbcRow rule : mailForwardMapper.selectActiveRulesByUserId(ownerUserId)) {
            if (matchesSender(rule, fromEmail)) {
                String email = lower(rule.forwardEmail());
                return email.isEmpty() ? null : new Target(email, true, false);
            }
        }
        MailForwardSettingJdbcRow setting = mailForwardMapper.selectSetting(ownerUserId);
        if (setting == null || !"Y".equals(setting.useYn())) {
            return null;
        }
        String email = lower(setting.forwardEmail());
        if (email.isEmpty()) {
            return null;
        }
        return new Target(email, false, "N".equals(setting.keepOriginalYn()));
    }

    /** 발신자가 예외 규칙에 걸리는가. DOMAIN 은 하위 도메인까지 본다. */
    private static boolean matchesSender(MailForwardRuleJdbcRow rule, String fromEmail) {
        String value = lower(rule.matchVal());
        if (value.isEmpty() || fromEmail.isEmpty()) {
            return false;
        }
        if (MATCH_EMAIL.equals(rule.matchType())) {
            return fromEmail.equals(value);
        }
        int at = fromEmail.lastIndexOf('@');
        if (at < 0) {
            return false;
        }
        String domain = fromEmail.substring(at + 1);
        // 하위 도메인 포함. 다만 "kr" 이 "example.kr" 에 걸리는 식의 사고를 막으려고
        // 점 경계를 요구한다(endsWith("." + value)).
        return domain.equals(value) || domain.endsWith("." + value);
    }

    /**
     * 전달 대상이 곧바로 되돌아오지 않는가(무한 전달 방지 4겹).
     *
     * <p>설정 저장 시에도 같은 검사를 하지만({@code MailForwardService.ensureForwardable}),
     * 그때 알 수 없는 것이 여기서 드러난다 — 원본의 발신자·수신자가 누구인지는 메일이
     * 도착해야 알 수 있다.
     */
    private boolean isSafeTarget(String target, String fromEmail, Set<String> recipients) {
        if (target.isEmpty()) {
            return false;
        }
        if (target.equals(fromEmail)) {
            // 보낸 사람에게 되돌리기. 상대 서버가 다시 우리에게 보내면 핑퐁이 된다.
            return false;
        }
        if (recipients.contains(target)) {
            // 이미 이 메일을 받은 주소다. 다시 보내 봐야 중복이고, 그 주소가 우리 쪽
            // 수신함이면 그대로 무한 루프다.
            return false;
        }
        // 우리 시스템 발신 주소로 보내면 그 메일이 다시 수신되어 또 전달된다.
        return !properties.isFromEmailAllowed(target);
    }

    // ── 규칙 판정 ───────────────────────────────────────────────────────────

    /** 조건 세 개를 AND 로 묶는다. 값이 없는 조건은 통과로 본다(다우오피스에 OR 은 없다). */
    private static boolean matches(MailRuleJdbcRow rule,
                                   String fromEmail,
                                   Set<String> recipients,
                                   String subject) {
        return MailRuleMatcher.matches(rule.fromOp(), rule.fromVal(), fromEmail)
                && MailRuleMatcher.matchesAny(rule.toOp(), rule.toVal(), recipients)
                && MailRuleMatcher.matches(rule.subjOp(), rule.subjVal(), subject);
    }

    /**
     * 수신자 주소로 설정 주인을 찾는다.
     *
     * <p>TO 를 먼저, 없으면 CC 를 본다. 여러 명이 걸리면 앞선 주소의 주인이 이긴다 —
     * 규칙은 단수의 주인을 요구하는데(메일함은 한 곳으로만 옮길 수 있다) 그 선택 기준이
     * 조회 시점에 따라 달라지면 안 된다.
     *
     * @return 사내 수신자를 못 찾으면 null. 그때는 아무 것도 하지 않는다
     */
    private String resolveOwnerUserId(List<MailAddrDtlJdbcRow> addresses) {
        List<String> ordered = new ArrayList<>(emailsOf(addresses, "TO", "CC"));
        if (ordered.isEmpty()) {
            return null;
        }
        List<MailUserRefJdbcRow> refs = mailRecipientMapper.selectUserRefsByEmails(ordered);
        if (refs.isEmpty()) {
            return null;
        }
        Map<String, String> byEmail = new HashMap<>(refs.size());
        for (MailUserRefJdbcRow ref : refs) {
            if (ref.email() != null && StringUtils.hasText(ref.userId())) {
                byEmail.putIfAbsent(lower(ref.email()), ref.userId());
            }
        }
        for (String email : ordered) {
            String userId = byEmail.get(email);
            if (userId != null) {
                return userId;
            }
        }
        return null;
    }

    /** 지정한 종류의 주소를 순서대로 뽑는다(중복 제거, 소문자). */
    private static Set<String> emailsOf(List<MailAddrDtlJdbcRow> addresses, String... addrTypes) {
        Set<String> result = new LinkedHashSet<>();
        if (addresses == null || addresses.isEmpty()) {
            return result;
        }
        for (String addrType : addrTypes) {
            for (MailAddrDtlJdbcRow row : addresses) {
                if (addrType.equals(row.addrType()) && StringUtils.hasText(row.email())) {
                    result.add(lower(row.email()));
                }
            }
        }
        return result;
    }

    // ── 전달 본문 ───────────────────────────────────────────────────────────

    /** 이미 FW:/Fwd: 로 시작하면 다시 붙이지 않는다. 여러 번 전달되면 제목이 접두어로 뒤덮인다. */
    private static String forwardSubject(String subject) {
        String value = subject == null ? "" : subject.trim();
        String lower = value.toLowerCase(Locale.ROOT);
        String result = (lower.startsWith("fw:") || lower.startsWith("fwd:"))
                ? value
                : FWD_PREFIX + value;
        return result.length() <= SUBJECT_MAX ? result : result.substring(0, SUBJECT_MAX);
    }

    /**
     * 원본 정보 머리글 + 원본 본문.
     *
     * <p><b>머리글이 없으면 안 된다.</b> 전달 메일의 From 은 우리 시스템 주소라, 받는 사람은
     * 원래 누가 보낸 메일인지 알 방법이 아예 없다. 회신처(reply-to)만으로는 화면에 드러나지 않는다.
     */
    private static String forwardHtml(MailMstJdbcRow mail, String html) {
        StringBuilder sb = new StringBuilder(256 + (html == null ? 0 : html.length()));
        sb.append("<div style=\"border-left:3px solid #ccc;padding-left:12px;")
                .append("margin:0 0 16px 0;color:#555;font-size:13px;line-height:1.6\">")
                .append("<b>자동 전달된 메일입니다.</b><br>")
                .append("보낸사람: ").append(escape(senderLabel(mail))).append("<br>")
                .append("받는사람: ").append(escape(nz(mail.toSummary()))).append("<br>")
                .append("받은시각: ").append(escape(stamp(mail))).append("<br>")
                .append("제목: ").append(escape(nz(mail.subject())))
                .append("</div>");
        if (html != null) {
            sb.append(html);
        }
        return sb.toString();
    }

    private static String forwardText(MailMstJdbcRow mail, String text) {
        return "―― 자동 전달된 메일입니다 ――\n"
                + "보낸사람: " + senderLabel(mail) + "\n"
                + "받는사람: " + nz(mail.toSummary()) + "\n"
                + "받은시각: " + stamp(mail) + "\n"
                + "제목: " + nz(mail.subject()) + "\n"
                + "――――――――――――――――――――\n\n"
                + nz(text);
    }

    private static String senderLabel(MailMstJdbcRow mail) {
        String name = nz(mail.fromNm()).trim();
        String email = nz(mail.fromEmail());
        return name.isEmpty() ? email : name + " <" + email + ">";
    }

    private static String stamp(MailMstJdbcRow mail) {
        return mail.mailAt() == null ? "" : mail.mailAt().format(STAMP);
    }

    /**
     * 머리글에 넣는 값만 이스케이프한다. 원본 본문은 손대지 않는다 — 이미 HTML 이고,
     * 여기서 이스케이프하면 본문이 태그 소스로 보인다.
     */
    private static String escape(String value) {
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private static String nz(String value) {
        return value == null ? "" : value;
    }

    private static String lower(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }
}
