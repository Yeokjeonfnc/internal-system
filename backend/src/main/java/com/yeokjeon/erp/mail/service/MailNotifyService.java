package com.yeokjeon.erp.mail.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.yeokjeon.erp.chat.ws.ChatSessionRegistry;
import com.yeokjeon.erp.mail.config.MailImmediateExecutor;
import com.yeokjeon.erp.mail.dto.MailAddrDtlJdbcRow;
import com.yeokjeon.erp.mail.dto.MailMstJdbcRow;
import com.yeokjeon.erp.mail.dto.MailUserRefJdbcRow;
import com.yeokjeon.erp.mail.mapper.MailAddrMapper;
import com.yeokjeon.erp.mail.mapper.MailMstMapper;
import com.yeokjeon.erp.mail.mapper.MailNotifMapper;
import com.yeokjeon.erp.mail.mapper.MailRecipientMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * 수신 메일 → ERP 알림 (mal001-N).
 *
 * <p>사용자 원문: "메일 받으면 erp창에서 알림 바로 올 수 있도록 해줘". 메일 화면을 열어
 * 두지 않아도 알림함에 뜨게 하는 것이 목적이라, 기존 알림 체계({@code notif_mst})에
 * 그대로 얹는다. 새 알림 테이블·새 조회 API 를 만들지 않은 이유는 화면이 이미
 * {@code /notifications} 를 보고 있어서, 거기 한 줄만 들어가면 별도 작업 없이 뜨기 때문이다.
 *
 * <p><b>왜 별도 서비스인가.</b> {@link MailReceiveService} 는 "Resend 가 준 것을 그대로
 * 적재한다"가 전부여야 한다({@link MailAutoProcessService} 를 가른 것과 같은 이유).
 * 알림은 실패해도 메일 적재는 살아남아야 하는데, 한 클래스에 두면 언젠가 한 트랜잭션으로
 * 묶이고 그 순간 알림 하나 때문에 메일을 통째로 못 받는 사고가 난다.
 *
 * <p><b>호출부가 예외를 삼킨다.</b> 이 클래스의 공개 메서드는 {@code @Transactional} 이라
 * 예외가 나면 자기 트랜잭션만 롤백된다. 그 예외를 잡는 try/catch 는 반드시
 * {@link MailReceiveService} 쪽(=프록시 바깥)에 있어야 한다. 같은 빈 안에서 잡으면
 * 스프링이 rollback-only 로 표시해 둔 트랜잭션을 커밋하려다
 * {@code UnexpectedRollbackException} 이 터진다({@code MailWebhookService} 주석과 같은 함정).
 *
 * <p><b>실시간 푸시 (mal001-N2).</b> {@code notif_mst} 에 넣는 것만으로는 화면을
 * <b>새로고침해야</b> 알림이 보인다 — 알림 배지는 화면에 처음 들어올 때 한 번만 세기
 * 때문이다. 그래서 알림을 실제로 새로 넣은 사람에게 WebSocket 프레임을 함께 쏜다.
 * 자세한 내용은 {@link #pushAfterCommit}.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailNotifyService {

    /**
     * 메일 수신 알림의 종류 코드.
     *
     * <p>기존 값(ACTIVITY_APPROVAL / APPROVAL / STORE / EAP_APPROVAL)과 겹치지 않는 새 코드다.
     * 기존 코드를 재사용하면 활동 알림용 조회가 메일 알림까지 끌어와 결재 화면이 깨진다
     * ({@code ActMstMapper} 의 알림 쿼리들은 전부 {@code notif_typ} 으로 대상을 좁힌다).
     *
     * <p>{@code notif_mst.notif_typ} 은 varchar(40) 이라 길이도 여유가 있다.
     */
    private static final String NOTIF_TYP = "MAIL_RECEIVED";

    /** {@code notif_mst.msg_txt} 는 varchar(500). 넘치면 INSERT 자체가 실패한다. */
    private static final int MSG_MAX = 500;

    /**
     * 알림함에서 종류를 눈으로 구분하기 위한 접두어.
     *
     * <p>화면이 {@code notif_typ} 으로 아이콘을 나누기 전까지는 이것이 유일한 단서다.
     */
    private static final String MSG_PREFIX = "[메일] ";

    /**
     * 메시지에 넣는 제목 길이 상한.
     *
     * <p>제목이 길어도 보낸사람은 반드시 보여야 해서 제목만 먼저 자른다. 전자결재
     * 알림도 같은 방식으로 제목을 80자에서 자른다({@code EapDocumentService}).
     */
    private static final int SUBJECT_IN_MSG_MAX = 120;

    /** 보낸사람 표시 길이 상한. 표시이름이 비정상적으로 긴 스팸이 실제로 온다. */
    private static final int SENDER_IN_MSG_MAX = 80;

    private final MailMstMapper mailMstMapper;
    private final MailAddrMapper mailAddrMapper;
    private final MailRecipientMapper mailRecipientMapper;
    private final MailNotifMapper mailNotifMapper;

    /**
     * 접속 중인 사용자 소켓 보관소.
     *
     * <p><b>이름이 chat 이지만 채팅 전용이 아니다.</b> 이 클래스는
     * {@code userId → Set<WebSocketSession>} 맵과 {@code sendToUsers} 뿐이고 채팅 개념이
     * 전혀 없는 도메인 중립 컴포넌트라, 메일 알림도 같은 소켓에 그대로 태운다.
     * 알림 전용 소켓을 새로 파면 사용자마다 소켓이 두 개가 되고
     * {@code AuthTokenFilter} 의 {@code ?token=} 허용 경로까지 늘려야 한다
     * (자세한 근거는 {@code ChatWebSocketConfig} 주석).
     */
    private final ChatSessionRegistry chatSessionRegistry;

    /**
     * 커밋 이후로 푸시를 미루는 데 쓴다.
     *
     * <p>메일 도메인이 이미 쓰고 있는 실행기를 그대로 재사용한다 — 커밋 후 실행,
     * 예외 삼킴, 큐 넘치면 버림이 전부 여기 이미 구현돼 있다.
     */
    private final MailImmediateExecutor immediateExecutor;

    private final ObjectMapper objectMapper;

    /**
     * 수신 메일 1건에 대한 알림을 만든다.
     *
     * <p>수신 저장 <b>직후</b>에 부른다. 본문 수집을 기다리지 않는 이유는 알림에 필요한
     * 값(보낸사람·제목)이 웹훅 페이로드에 이미 다 있고, 사용자가 원한 것이 "메일 받으면
     * 바로"이기 때문이다. 본문 수집까지 기다리면 알림이 그만큼 늦는다.
     *
     * @return 실제로 들어간 알림 건수(로그·시험용)
     */
    @Transactional
    public int notifyReceived(long mailIdx) {
        MailMstJdbcRow mail = mailMstMapper.selectByIdx(mailIdx);
        if (mail == null || Boolean.TRUE.equals(mail.deletedYn())) {
            return 0;
        }
        // 알림은 받은 메일에만 건다. 내가 보낸 메일을 나에게 알릴 이유가 없다.
        if (!"IN".equals(mail.direction())) {
            return 0;
        }
        /*
         * 자동전달로 만들어진 메일은 제외한다.
         *
         * 전달 메일은 우리 시스템이 스스로 만들어 보낸 것이고(direction='OUT'), 그것이
         * 외부를 돌아 다시 수신될 때 fwd_src_idx 는 비어 있다. 그래도 이 검사를 남기는
         * 이유는 자동분류·자동전달 엔진이 쓰는 대상 판정과 기준을 맞춰 두기 위해서다
         * (MailAutoProcessService.isRuleTarget 과 같은 조건).
         */
        if (mail.fwdSrcIdx() != null) {
            return 0;
        }
        /*
         * act_idx 는 integer 다(notif_mst 스키마). mail_idx 는 bigint 라 이론적으로
         * 넘칠 수 있어 전자결재와 같은 방식으로 막는다({@code EapDocumentService} 도
         * mappingId 가 Integer.MAX_VALUE 를 넘으면 알림을 만들지 않는다).
         *
         * 여기서 act_idx 없이 넣으면 "어느 메일의 알림인가"를 잃어 중복 판정이 불가능해진다.
         * 21억 통을 받으면 그때 notif_mst 를 bigint 로 옮겨야 한다.
         */
        if (mailIdx > Integer.MAX_VALUE) {
            log.warn("mail_idx 가 notif_mst.act_idx(integer) 범위를 넘어 알림을 건너뜁니다. mailIdx={}",
                    mailIdx);
            return 0;
        }

        List<String> targets = resolveTargets(mailIdx);
        if (targets.isEmpty()) {
            // selectAdminUserIds 까지 비었다는 뜻(관리자 계정이 하나도 없는 상태).
            log.warn("메일 수신 알림 대상을 정하지 못했습니다 mailIdx={}", mailIdx);
            return 0;
        }

        String msg = buildMessage(mail);
        int actIdx = (int) mailIdx;
        int inserted = 0;
        /*
         * 푸시 대상은 "이번에 실제로 알림이 새로 들어간 사람"뿐이다.
         *
         * insertIfAbsent 가 0 을 돌려준 사람은 이미 같은 메일 알림을 가지고 있다는
         * 뜻이라, 그 사람에게 프레임을 보내면 알림함에는 새 줄이 하나도 없는데
         * 토스트만 다시 뜬다. 웹훅은 at-least-once 라 이 상황이 실제로 일어난다.
         */
        List<String> pushTargets = new ArrayList<>(targets.size());
        for (String userId : targets) {
            int n = mailNotifMapper.insertIfAbsent(userId, msg, NOTIF_TYP, actIdx);
            if (n > 0) {
                pushTargets.add(userId);
            }
            inserted += n;
        }
        if (inserted > 0) {
            log.info("메일 수신 알림 생성 mailIdx={} 대상={}명 신규={}건", mailIdx, targets.size(), inserted);
            pushAfterCommit(pushTargets, msg, mailIdx);
        } else {
            // 재전달 웹훅·원장 재처리로 같은 메일이 다시 온 경우. 정상 동작이다.
            log.debug("메일 수신 알림이 이미 있어 건너뜀 mailIdx={}", mailIdx);
        }
        return inserted;
    }

    // ── 실시간 푸시 ─────────────────────────────────────────────────────────

    /**
     * 알림이 들어간 사용자에게 WebSocket 프레임을 보낸다 — <b>커밋된 뒤에</b>.
     *
     * <p><b>왜 커밋 후인가.</b> 프레임을 받은 클라이언트는 곧바로
     * {@code GET /notifications} 로 알림함을 다시 조회한다. 커밋 전에 보내면 그 조회에
     * 방금 넣은 알림이 <b>아직 안 보여서</b>(READ COMMITTED) 배지가 그대로고, 사용자는
     * "토스트는 떴는데 알림함은 비어 있는" 상태를 본다. 그래서
     * {@link MailImmediateExecutor#runAfterCommit} 으로 미룬다 — 본문 수집 즉시 트리거가
     * 같은 이유로 쓰는 장치다.
     *
     * <p><b>소켓은 부가 기능이다.</b> 여기서 무슨 일이 나도 알림 저장·메일 수신은
     * 멀쩡해야 한다. 그래서 (1) 직렬화 실패는 로그만 남기고 조용히 포기하고,
     * (2) 전송은 실행기 안에서 돌아 본 트랜잭션 스레드와 완전히 분리되며,
     * (3) 실행기 큐가 넘치면 그냥 버려진다. 못 받은 사용자는 화면을 다시 열 때
     * 기존 경로(진입 시 1회 조회)로 알림을 보게 되므로 잃는 것은 "즉시성"뿐이다.
     *
     * <p>프레임: {@code {"type":"notification","notifTyp":"MAIL_RECEIVED",
     * "msgTxt":"...","mailIdx":123,"createDt":"..."}}.
     * 프론트({@code WebSocketChatService._onFrame}) 의 switch 에는 default 가 없어
     * 모르는 type 은 조용히 무시된다 — 서버를 먼저 배포해도 구 버전 앱은 안 깨진다.
     */
    private void pushAfterCommit(List<String> userIds, String msgTxt, long mailIdx) {
        if (userIds.isEmpty()) {
            return;
        }
        final String payload;
        try {
            Map<String, Object> frame = new LinkedHashMap<>();
            frame.put("type", "notification");
            frame.put("notifTyp", NOTIF_TYP);
            frame.put("msgTxt", msgTxt);
            frame.put("mailIdx", mailIdx);
            /*
             * 화면에 뿌리는 값이 아니라 "방금 것"임을 알리는 표식이다. 알림함 목록은
             * 어차피 REST 로 다시 받아 오므로 여기서 notif_mst.create_dt 를 되읽는
             * 추가 조회는 하지 않는다(알림 하나 때문에 SELECT 를 늘릴 이유가 없다).
             */
            frame.put("createDt", LocalDateTime.now().toString());
            payload = objectMapper.writeValueAsString(frame);
        } catch (Exception e) {
            log.warn("메일 알림 푸시 직렬화 실패(무시) mailIdx={}: {}", mailIdx, e.getMessage());
            return;
        }
        // 커밋 뒤 다른 스레드에서 읽으므로 방어 복사한다(호출부 리스트가 나중에 바뀌어도 안전).
        final List<String> recipients = List.copyOf(userIds);
        immediateExecutor.runAfterCommit("mail-notif-push-" + mailIdx, () -> {
            try {
                chatSessionRegistry.sendToUsers(recipients, payload);
            } catch (RuntimeException e) {
                // sendToUsers 는 세션별 IOException 을 이미 삼키지만, 그 바깥에서
                // 터지는 것까지 여기서 막는다. 푸시 실패는 알림 저장과 무관하다.
                log.warn("메일 알림 푸시 실패(무시) mailIdx={}", mailIdx, e);
            }
        });
    }

    // ── 대상 판정 ───────────────────────────────────────────────────────────

    /**
     * 알림 대상자를 정한다.
     *
     * <p><b>왜 어려운가.</b> 수신 메일의 {@code mail_mst.user_id} 는 담당자 미지정(NULL)
     * 이다 — 이 ERP 의 받은메일함은 개인 사서함이 아니라 공용 이력이고, 담당자는 사람이
     * 화면에서 배정한다. 그래서 "누구 앞으로 온 메일인가"는 <b>주소로만</b> 적혀 있다.
     *
     * <p><b>1순위: 수신자 주소 역추적.</b> 자동분류·자동전달이 이미 쓰는 방식을 그대로
     * 재사용한다({@code MailAutoProcessService.resolveOwnerUserId} → TO 먼저, 그다음 CC 를
     * {@code user_mst} 에서 되짚는다). 같은 판정을 두 벌 만들면 규칙은 A 에게 걸리는데
     * 알림은 B 에게 가는 상태가 언젠가 반드시 생긴다.
     *
     * <p><b>다만 규칙과 달리 "한 명"으로 좁히지 않는다.</b> 자동분류는 메일함을 한 곳으로만
     * 옮길 수 있어 주인이 단수여야 하지만, 알림은 받은 사람 모두에게 가는 것이 맞다.
     * 세 사람이 함께 받은 메일을 한 사람만 알게 되면 나머지 둘은 자기 앞으로 온 메일을
     * 놓친다. TO 를 먼저, 그다음 CC 를 훑되 <b>걸리는 사원 전부</b>를 대상으로 한다.
     *
     * <p><b>2순위(폴백): 관리자.</b> 공용 주소(info@, help@ 등)로 온 메일은 어느 사원과도
     * 매칭되지 않는다. 그때 아무에게도 안 보내면 <b>메일이 온 사실 자체를 아무도 모른다</b>.
     * 자동분류는 "아무 것도 안 함"이 안전한 선택이지만(분류를 못 했을 뿐 메일은 목록에
     * 있다) 알림은 반대다 — 안 보내면 기능이 없는 것과 같다. 그래서 관리자에게라도 보낸다.
     *
     * <p>BCC 는 보지 않는다. 수신 메일의 BCC 는 원래 헤더에 남지 않아 신뢰할 수 없고,
     * 자동분류·자동전달의 주인 판정도 TO/CC 만 본다.
     */
    private List<String> resolveTargets(long mailIdx) {
        List<MailAddrDtlJdbcRow> addresses = mailAddrMapper.selectByMailIdx(mailIdx);
        List<String> ordered = new ArrayList<>(emailsOf(addresses, "TO", "CC"));

        if (!ordered.isEmpty()) {
            List<MailUserRefJdbcRow> refs = mailRecipientMapper.selectUserRefsByEmails(ordered);
            Map<String, String> byEmail = new HashMap<>(refs.size());
            for (MailUserRefJdbcRow ref : refs) {
                if (ref.email() != null && StringUtils.hasText(ref.userId())) {
                    byEmail.putIfAbsent(lower(ref.email()), ref.userId());
                }
            }
            // 주소 순서(TO → CC)를 그대로 유지한다. 겸직·별칭으로 같은 사람이 두 번
            // 걸릴 수 있어 LinkedHashSet 으로 중복만 걷어낸다.
            Set<String> users = new LinkedHashSet<>();
            for (String email : ordered) {
                String userId = byEmail.get(email);
                if (userId != null) {
                    users.add(userId);
                }
            }
            if (!users.isEmpty()) {
                return new ArrayList<>(users);
            }
        }

        List<String> admins = mailNotifMapper.selectAdminUserIds();
        log.info("사내 수신자를 못 찾아 관리자에게 메일 알림을 보냅니다 mailIdx={} 관리자={}명",
                mailIdx, admins.size());
        return admins;
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

    // ── 메시지 ──────────────────────────────────────────────────────────────

    /**
     * 알림 문구를 만든다.
     *
     * <p>보낸사람과 제목이 <b>둘 다</b> 들어가야 한다. 제목만 있으면 누가 보낸 것인지 몰라
     * 열어 보기 전에는 급한 메일인지 판단할 수 없고, 보낸사람만 있으면 무슨 내용인지 모른다.
     *
     * <p>앞에 "[메일]" 을 붙여 알림함에서 종류를 눈으로 구분할 수 있게 한다 — 화면이
     * {@code notif_typ} 으로 아이콘을 나누기 전까지는 이 접두어가 유일한 단서다.
     */
    private static String buildMessage(MailMstJdbcRow mail) {
        String sender = clip(senderLabel(mail), SENDER_IN_MSG_MAX);
        if (sender.isEmpty()) {
            sender = "보낸사람 미상";
        }
        String subject = clip(nz(mail.subject()).trim(), SUBJECT_IN_MSG_MAX);
        if (subject.isEmpty()) {
            // 제목 없는 메일이 실제로 온다. 빈 문자열로 두면 "…님이 보낸 메일: " 로
            // 끝나 잘린 문장처럼 보인다.
            subject = "(제목 없음)";
        }
        return clip(MSG_PREFIX + sender + " : " + subject, MSG_MAX);
    }

    /** {@code 홍길동(hong@x.com)} 형태. 표시이름이 없으면 주소만 쓴다. */
    private static String senderLabel(MailMstJdbcRow mail) {
        String name = nz(mail.fromNm()).trim();
        String email = nz(mail.fromEmail()).trim();
        if (name.isEmpty()) {
            return email;
        }
        if (email.isEmpty()) {
            return name;
        }
        return name + "(" + email + ")";
    }

    private static String clip(String value, int max) {
        if (value == null) {
            return "";
        }
        String trimmed = value.trim();
        return trimmed.length() <= max ? trimmed : trimmed.substring(0, max);
    }

    private static String nz(String value) {
        return value == null ? "" : value;
    }

    private static String lower(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }
}
