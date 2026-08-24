package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.mail.dto.MailRuleDto;
import com.yeokjeon.erp.mail.dto.MailRuleInsertParam;
import com.yeokjeon.erp.mail.dto.MailRuleJdbcRow;
import com.yeokjeon.erp.mail.dto.MailRuleSaveRequestDto;
import com.yeokjeon.erp.mail.mapper.MailRuleMapper;
import com.yeokjeon.erp.mail.support.MailRuleMatcher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * 자동분류 규칙 CRUD (mal001-K).
 *
 * <p>다우오피스 사양을 그대로 따랐다. 조건은 보낸사람·수신자(참조 포함)·메일제목 셋뿐이고
 * <b>AND 로만</b> 묶이며, 처리는 메일함 이동 <b>또는</b> 읽음처리 중 하나다. OR 을 넣지 않은
 * 이유는 조건을 1:N 행으로 쪼개야 해서인데, 그러면 "규칙 하나 = 행 하나"라는 단순함이
 * 깨지고 화면도 훨씬 복잡해진다. OR 이 필요하면 규칙을 두 개 만드는 편이 사용자에게도
 * 무엇이 걸리는지 분명하다.
 *
 * <p><b>규칙은 개인 소유물이다.</b> {@link MailFolderService} 와 같은 방식으로 모든 조회·
 * 변경이 {@code userId} 를 조건으로 갖고 SQL 에도 같은 조건이 한 번 더 들어 있다.
 * 남의 규칙에 접근하면 403 이 아니라 <b>404</b> 를 준다 — 403 은 "그 번호의 규칙이
 * 존재한다"는 사실을 알려 주는 셈이다.
 *
 * <p>설정 이후 수신분부터 적용된다. 기존 메일 소급 적용은 하지 않는다(다우와 동일).
 * 이미 사람이 정리해 둔 메일함을 규칙이 뒤엎으면 되돌릴 방법이 없다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailRuleService {

    /**
     * 한 사용자가 만들 수 있는 규칙 수.
     *
     * <p>다우오피스는 상한을 명시하지 않지만, 수신 1건마다 규칙 전부를 순서대로 훑으므로
     * 개수가 그대로 수신 처리 비용이다. 메일함 상한(50)과 같은 값으로 맞춰 두었다.
     */
    public static final int MAX_RULES_PER_USER = 50;

    /** 메일함 이동 */
    private static final String ACTION_MOVE = "MOVE";
    /** 읽음처리 */
    private static final String ACTION_READ = "READ";

    private final MailRuleMapper mailRuleMapper;
    private final MailFolderService mailFolderService;

    @Transactional(readOnly = true)
    public List<MailRuleDto> list(String userId) {
        return mailRuleMapper.selectByUserId(requireUserId(userId)).stream()
                .map(MailRuleDto::fromRow)
                .toList();
    }

    @Transactional
    public MailRuleDto create(MailRuleSaveRequestDto body, String userId) {
        String uid = requireUserId(userId);
        if (body == null || !StringUtils.hasText(body.ruleNm())) {
            throw new IllegalArgumentException("규칙 이름을 입력해 주세요.");
        }
        if (mailRuleMapper.countByUserId(uid) >= MAX_RULES_PER_USER) {
            throw new IllegalStateException(
                    "규칙은 최대 " + MAX_RULES_PER_USER + "개까지 만들 수 있습니다.");
        }

        Condition from = Condition.of(body.fromOp(), body.fromVal());
        Condition to = Condition.of(body.toOp(), body.toVal());
        Condition subj = Condition.of(body.subjOp(), body.subjVal());
        requireAnyCondition(from, to, subj);

        String actionType = normalizeAction(body.actionType());
        Long folderIdx = resolveActionFolder(actionType, body.actionFolderIdx(), uid);

        MailRuleInsertParam param = new MailRuleInsertParam();
        param.setUserId(uid);
        param.setRuleNm(body.ruleNm().trim());
        param.setUseYn(Boolean.FALSE.equals(body.use()) ? "N" : "Y");
        param.setSortOrder(body.sortOrder() != null
                ? body.sortOrder()
                : mailRuleMapper.selectNextSortOrder(uid));
        param.setFromOp(from.op());
        param.setFromVal(from.val());
        param.setToOp(to.op());
        param.setToVal(to.val());
        param.setSubjOp(subj.op());
        param.setSubjVal(subj.val());
        param.setActionType(actionType);
        param.setActionFolderIdx(folderIdx);
        mailRuleMapper.insert(param);

        Long newIdx = param.getMailRuleIdx();
        if (newIdx == null) {
            throw new IllegalStateException("규칙 생성에 실패했습니다.");
        }
        log.info("메일 규칙 생성 ruleIdx={} action={} by={}", newIdx, actionType, uid);
        return findOne(newIdx, uid);
    }

    /**
     * 규칙 수정(PATCH).
     *
     * <p><b>조건을 지우려면 빈 문자열을 보낸다.</b> record 로는 "필드를 안 보냄"과
     * "null 을 보냄"을 구분할 수 없어서 null 을 "안 바꿈"으로 쓰기로 했고, 그러면 조건을
     * 지울 표현이 없어진다. {@code fromVal: ""} 이 그 표현이다
     * ({@link MailFolderService} 가 최상위 이동을 0 으로 약속한 것과 같은 사정).
     */
    @Transactional
    public MailRuleDto update(long ruleIdx, MailRuleSaveRequestDto body, String userId) {
        String uid = requireUserId(userId);
        if (body == null) {
            throw new IllegalArgumentException("변경할 내용이 없습니다.");
        }
        MailRuleJdbcRow current = requireRule(ruleIdx, uid);

        // "요청에 그 조건이 실려 있었는가". op 만 보내든 val 만 보내든 손댄 것으로 본다.
        boolean fromGiven = body.fromOp() != null || body.fromVal() != null;
        boolean toGiven = body.toOp() != null || body.toVal() != null;
        boolean subjGiven = body.subjOp() != null || body.subjVal() != null;

        Condition from = fromGiven
                ? Condition.patch(body.fromOp(), body.fromVal(), current.fromOp(), current.fromVal())
                : new Condition(current.fromOp(), current.fromVal());
        Condition to = toGiven
                ? Condition.patch(body.toOp(), body.toVal(), current.toOp(), current.toVal())
                : new Condition(current.toOp(), current.toVal());
        Condition subj = subjGiven
                ? Condition.patch(body.subjOp(), body.subjVal(), current.subjOp(), current.subjVal())
                : new Condition(current.subjOp(), current.subjVal());
        // 수정 결과가 "조건 없는 규칙"이 되면 안 된다. 그런 규칙은 모든 수신 메일을
        // 첫 번째로 잡아 버려서 아래에 있는 규칙이 전부 죽는다(DB CHECK 도 같은 조건).
        requireAnyCondition(from, to, subj);

        boolean actionGiven = body.actionType() != null || body.actionFolderIdx() != null;
        String actionType = current.actionType();
        Long folderIdx = current.actionFolderIdx();
        if (actionGiven) {
            actionType = body.actionType() != null
                    ? normalizeAction(body.actionType())
                    : normalizeAction(current.actionType());
            Long requested = body.actionFolderIdx() != null
                    ? body.actionFolderIdx()
                    : current.actionFolderIdx();
            folderIdx = resolveActionFolder(actionType, requested, uid);
        }

        mailRuleMapper.update(
                ruleIdx,
                uid,
                StringUtils.hasText(body.ruleNm()) ? body.ruleNm().trim() : null,
                body.use() == null ? null : (body.use() ? "Y" : "N"),
                body.sortOrder(),
                fromGiven, from.op(), from.val(),
                toGiven, to.op(), to.val(),
                subjGiven, subj.op(), subj.val(),
                actionGiven, actionType, folderIdx);

        log.info("메일 규칙 수정 ruleIdx={} by={}", ruleIdx, uid);
        return findOne(ruleIdx, uid);
    }

    /**
     * 순서 변경 — 보낸 배열 순서가 곧 새 우선순위다.
     *
     * <p>규칙마다 sortOrder 숫자를 받지 않는 이유: 화면이 계산한 숫자가 겹치면 두 규칙의
     * 순서가 조회 시점에 따라 달라지고, 같은 메일이 날마다 다른 메일함으로 간다.
     * 배열 위치를 그대로 0,1,2… 로 다시 매기면 그 상태가 만들어질 수 없다.
     *
     * @return 실제로 순서가 바뀐 규칙 수. 남의 idx 가 섞여 있으면 요청보다 적다.
     */
    @Transactional
    public int reorder(List<Long> ruleIdxes, String userId) {
        String uid = requireUserId(userId);
        if (ruleIdxes == null || ruleIdxes.isEmpty()) {
            throw new IllegalArgumentException("순서를 정할 규칙이 없습니다.");
        }
        // 중복 idx 가 섞이면 같은 행에 두 개의 순서가 배정돼 결과가 어느 쪽인지 알 수 없다.
        // 앞에 나온 위치를 살린다(사용자가 드래그로 옮긴 위치가 앞쪽이다).
        Set<Long> unique = new LinkedHashSet<>();
        for (Long idx : ruleIdxes) {
            if (idx != null && idx > 0) {
                unique.add(idx);
            }
        }
        if (unique.isEmpty()) {
            throw new IllegalArgumentException("순서를 정할 규칙이 없습니다.");
        }
        int affected = mailRuleMapper.reorder(uid, new ArrayList<>(unique));
        log.info("메일 규칙 순서 변경 {}건 by={}", affected, uid);
        return affected;
    }

    @Transactional
    public void delete(long ruleIdx, String userId) {
        String uid = requireUserId(userId);
        requireRule(ruleIdx, uid);
        int deleted = mailRuleMapper.delete(ruleIdx, uid);
        if (deleted == 0) {
            throw new IllegalStateException("규칙 삭제에 실패했습니다.");
        }
        log.info("메일 규칙 삭제 ruleIdx={} by={}", ruleIdx, uid);
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    /**
     * 조건 한 쌍(연산자 + 비교값).
     *
     * <p>둘은 언제나 같이 있거나 같이 없다(DB CHECK 도 그 형태다). 따로 다루면
     * "연산자는 있는데 값이 없는" 조합이 만들어져 판정 결과를 예측할 수 없다.
     */
    private record Condition(String op, String val) {

        /** 생성용. 값이 비면 조건 자체가 없는 것으로 본다. */
        static Condition of(String op, String val) {
            if (!StringUtils.hasText(val)) {
                return new Condition(null, null);
            }
            // 값만 보내고 연산자를 빼먹는 요청이 실제로 흔하다. 거부하는 대신 가장 넓은
            // 연산자(포함)로 떨어뜨린다 — 사용자가 기대하는 기본 동작이기도 하다.
            String normalized = MailRuleMatcher.normalizeOp(op);
            return new Condition(normalized == null ? MailRuleMatcher.OP_CONTAINS : normalized,
                    val.trim());
        }

        /**
         * 수정용. 빈 문자열이 "이 조건을 지운다"는 뜻이라 {@link #of} 와 갈라진다.
         *
         * <p>연산자만 바꾸는 요청({@code fromOp} 만 전송)도 받아야 해서 값이 null 이면
         * 기존 값을 유지한다.
         */
        static Condition patch(String op, String val, String currentOp, String currentVal) {
            String targetVal = val != null ? val.trim() : currentVal;
            if (!StringUtils.hasText(targetVal)) {
                return new Condition(null, null);
            }
            String normalized = MailRuleMatcher.normalizeOp(op != null ? op : currentOp);
            return new Condition(normalized == null ? MailRuleMatcher.OP_CONTAINS : normalized,
                    targetVal);
        }

        boolean present() {
            return val != null;
        }
    }

    private static void requireAnyCondition(Condition from, Condition to, Condition subj) {
        if (!from.present() && !to.present() && !subj.present()) {
            throw new IllegalArgumentException(
                    "보낸사람·수신자·제목 중 최소 한 가지 조건을 지정해 주세요.");
        }
    }

    private static String normalizeAction(String actionType) {
        if (!StringUtils.hasText(actionType)) {
            throw new IllegalArgumentException("처리 방식(MOVE 또는 READ)을 지정해 주세요.");
        }
        String value = actionType.trim().toUpperCase(Locale.ROOT);
        if (!ACTION_MOVE.equals(value) && !ACTION_READ.equals(value)) {
            throw new IllegalArgumentException("처리 방식은 MOVE 또는 READ 여야 합니다.");
        }
        return value;
    }

    /**
     * 처리 방식에 맞는 대상 메일함을 정한다.
     *
     * <p>MOVE 면 대상이 반드시 있어야 하고 <b>본인 소유여야</b> 한다 — 확인하지 않으면
     * FK 는 통과하고 내 메일이 남의 메일함으로 들어간다(FK 는 소유자를 보지 않는다).
     * READ 면 대상이 없어야 한다. 두 경우 모두 DB CHECK 가 한 번 더 막지만, 여기서
     * 걸러야 사용자에게 제약 위반 원문 대신 읽을 수 있는 문장이 나간다.
     */
    private Long resolveActionFolder(String actionType, Long requested, String userId) {
        if (ACTION_MOVE.equals(actionType)) {
            if (requested == null || requested <= 0) {
                throw new IllegalArgumentException("메일함 이동 규칙은 대상 메일함을 지정해야 합니다.");
            }
            // 남의 메일함이면 여기서 404 가 난다(MailFolderService 가 소유자를 확인한다).
            mailFolderService.ensureOwned(requested, userId);
            return requested;
        }
        return null;
    }

    private MailRuleDto findOne(long ruleIdx, String userId) {
        return MailRuleDto.fromRow(requireRule(ruleIdx, userId));
    }

    /** 소유자 조건이 SQL 에 있으므로 남의 규칙이면 null 이 오고, 그대로 404 가 된다. */
    private MailRuleJdbcRow requireRule(long ruleIdx, String userId) {
        MailRuleJdbcRow row = mailRuleMapper.selectByIdx(ruleIdx, userId);
        if (row == null) {
            throw new ResourceNotFoundException("메일 규칙", "ruleIdx", ruleIdx);
        }
        return row;
    }

    private static String requireUserId(String userId) {
        if (!StringUtils.hasText(userId)) {
            // 토큰에서 온 값이라 정상 흐름에서는 비어 있을 수 없다. 비어 있다면 필터를
            // 거치지 않은 호출이므로 조건 없는 전체 조회로 이어지기 전에 끊는다.
            throw new IllegalStateException("로그인 정보를 확인할 수 없습니다.");
        }
        return userId.trim();
    }
}
