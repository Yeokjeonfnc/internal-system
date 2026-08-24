package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.dto.MailForwardDto;
import com.yeokjeon.erp.mail.dto.MailForwardRuleDto;
import com.yeokjeon.erp.mail.dto.MailForwardRuleInsertParam;
import com.yeokjeon.erp.mail.dto.MailForwardRuleJdbcRow;
import com.yeokjeon.erp.mail.dto.MailForwardRuleSaveRequestDto;
import com.yeokjeon.erp.mail.dto.MailForwardSaveRequestDto;
import com.yeokjeon.erp.mail.dto.MailUserRefJdbcRow;
import com.yeokjeon.erp.mail.mapper.MailForwardMapper;
import com.yeokjeon.erp.mail.mapper.MailRecipientMapper;
import com.yeokjeon.erp.mail.support.MailAddressParser;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Locale;

/**
 * 자동전달 설정 CRUD (mal001-L) — 전체 전달 + 발신자별 예외 규칙.
 *
 * <p>다우오피스 사양을 따른다.
 * <ol>
 *   <li>전체 자동전달: 받는 메일 전부를 지정 주소로. <b>원본을 남길지 지울지 선택</b></li>
 *   <li>예외 규칙: 특정 발신자 주소·도메인은 다른 주소로. 상한 10개(다우 기본값)</li>
 * </ol>
 *
 * <p><b>이 기능은 메일을 회사 밖으로 내보낸다.</b> 그래서 다른 개인 설정보다 검증이 빡빡하다.
 * 특히 전달 주소를 자유롭게 바꿀 수 있다는 것은 곧 "내 앞으로 오는 메일을 임의의 외부
 * 주소로 흘릴 수 있다"는 뜻이라, 소유자 조건을 서비스와 SQL 양쪽에 두었다.
 *
 * <p>실제 전달 실행은 {@link MailAutoProcessService} 가 한다. 여기는 설정만 다룬다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailForwardService {

    /**
     * 예외 규칙 상한.
     *
     * <p>다우오피스 기본 최대치가 10개라 같은 값으로 맞췄다. DB 트리거가 아니라 서비스에서
     * 막는 이유는, 트리거로 두면 마이그레이션·일괄 정리 스크립트까지 같이 막혀 운영이
     * 불편해지기 때문이다.
     */
    public static final int MAX_FORWARD_RULES = 10;

    private static final String MATCH_EMAIL = "EMAIL";
    private static final String MATCH_DOMAIN = "DOMAIN";

    private final MailForwardMapper mailForwardMapper;
    private final MailRecipientMapper mailRecipientMapper;
    private final ResendProperties properties;

    @Transactional(readOnly = true)
    public MailForwardDto get(String userId) {
        String uid = requireUserId(userId);
        return MailForwardDto.of(
                mailForwardMapper.selectSetting(uid),
                rulesOf(uid),
                MAX_FORWARD_RULES);
    }

    /**
     * 전체 자동전달 설정 저장(PUT).
     *
     * <p>세 값이 한 덩어리라 부분 갱신하지 않는다 — 화면도 토글과 주소를 함께 저장한다.
     */
    @Transactional
    public MailForwardDto save(MailForwardSaveRequestDto body, String userId) {
        String uid = requireUserId(userId);
        if (body == null) {
            throw new IllegalArgumentException("저장할 내용이 없습니다.");
        }
        boolean use = Boolean.TRUE.equals(body.use());
        String forwardEmail = MailAddressParser.normalizeEmail(body.forwardEmail());
        if (use) {
            if (forwardEmail.isEmpty()) {
                // DB CHECK 도 같은 조건을 막지만, 여기서 걸러야 사용자가 읽을 문장이 나간다.
                // 켜 놓고 주소가 비면 "전달 중"으로 보이는데 아무 데도 가지 않는다.
                throw new IllegalArgumentException("전달받을 주소를 입력해 주세요.");
            }
            ensureForwardable(forwardEmail, uid);
        }

        mailForwardMapper.upsertSetting(
                uid,
                use ? "Y" : "N",
                // 끌 때 주소를 지우지 않는다. 잠깐 껐다 켜는 사용이 흔한데 매번 다시
                // 입력하게 만들 이유가 없다(빈 값이면 매퍼가 기존 값을 유지한다).
                forwardEmail.isEmpty() ? null : forwardEmail,
                Boolean.FALSE.equals(body.keepOriginal()) ? "N" : "Y");

        log.info("자동전달 설정 저장 use={} keepOriginal={} by={}",
                use, !Boolean.FALSE.equals(body.keepOriginal()), uid);
        return get(uid);
    }

    @Transactional(readOnly = true)
    public List<MailForwardRuleDto> listRules(String userId) {
        return rulesOf(requireUserId(userId));
    }

    @Transactional
    public MailForwardRuleDto createRule(MailForwardRuleSaveRequestDto body, String userId) {
        String uid = requireUserId(userId);
        if (body == null) {
            throw new IllegalArgumentException("저장할 내용이 없습니다.");
        }
        if (mailForwardMapper.countRulesByUserId(uid) >= MAX_FORWARD_RULES) {
            throw new IllegalStateException(
                    "예외 규칙은 최대 " + MAX_FORWARD_RULES + "개까지 만들 수 있습니다.");
        }
        String matchType = normalizeMatchType(body.matchType());
        String matchVal = normalizeMatchVal(matchType, body.matchVal());
        String forwardEmail = MailAddressParser.normalizeEmail(body.forwardEmail());
        if (forwardEmail.isEmpty()) {
            throw new IllegalArgumentException("전달받을 주소를 입력해 주세요.");
        }
        ensureForwardable(forwardEmail, uid);
        if (mailForwardMapper.countRuleByMatch(uid, matchType, matchVal, null) > 0) {
            throw new IllegalArgumentException("같은 조건의 예외 규칙이 이미 있습니다: " + matchVal);
        }

        MailForwardRuleInsertParam param = new MailForwardRuleInsertParam();
        param.setUserId(uid);
        param.setMatchType(matchType);
        param.setMatchVal(matchVal);
        param.setForwardEmail(forwardEmail);
        param.setUseYn(Boolean.FALSE.equals(body.use()) ? "N" : "Y");
        param.setSortOrder(body.sortOrder() != null
                ? body.sortOrder()
                : mailForwardMapper.selectNextRuleSortOrder(uid));
        mailForwardMapper.insertRule(param);

        Long newIdx = param.getMailFwdRuleIdx();
        if (newIdx == null) {
            throw new IllegalStateException("예외 규칙 생성에 실패했습니다.");
        }
        log.info("자동전달 예외 규칙 생성 ruleIdx={} {}={} by={}", newIdx, matchType, matchVal, uid);
        return MailForwardRuleDto.fromRow(requireRule(newIdx, uid));
    }

    /** 예외 규칙 수정(PATCH). 보내지 않은 필드는 그대로 둔다. */
    @Transactional
    public MailForwardRuleDto updateRule(long ruleIdx,
                                         MailForwardRuleSaveRequestDto body,
                                         String userId) {
        String uid = requireUserId(userId);
        if (body == null) {
            throw new IllegalArgumentException("변경할 내용이 없습니다.");
        }
        MailForwardRuleJdbcRow current = requireRule(ruleIdx, uid);

        // 매칭 조건은 타입과 값이 한 쌍이다. 타입만 바꾸면(EMAIL→DOMAIN) 기존 값이
        // 새 타입 기준으로 다시 정규화돼야 해서, 어느 한쪽만 와도 둘 다 계산한다.
        String matchType = body.matchType() != null
                ? normalizeMatchType(body.matchType())
                : current.matchType();
        String matchVal = null;
        if (body.matchVal() != null || body.matchType() != null) {
            matchVal = normalizeMatchVal(matchType,
                    body.matchVal() != null ? body.matchVal() : current.matchVal());
            if (mailForwardMapper.countRuleByMatch(uid, matchType, matchVal, ruleIdx) > 0) {
                throw new IllegalArgumentException("같은 조건의 예외 규칙이 이미 있습니다: " + matchVal);
            }
        }

        String forwardEmail = null;
        if (body.forwardEmail() != null) {
            forwardEmail = MailAddressParser.normalizeEmail(body.forwardEmail());
            if (forwardEmail.isEmpty()) {
                throw new IllegalArgumentException("전달받을 주소를 입력해 주세요.");
            }
            ensureForwardable(forwardEmail, uid);
        }

        mailForwardMapper.updateRule(
                ruleIdx,
                uid,
                body.matchType() != null ? matchType : null,
                matchVal,
                forwardEmail,
                body.use() == null ? null : (body.use() ? "Y" : "N"),
                body.sortOrder());

        log.info("자동전달 예외 규칙 수정 ruleIdx={} by={}", ruleIdx, uid);
        return MailForwardRuleDto.fromRow(requireRule(ruleIdx, uid));
    }

    @Transactional
    public void deleteRule(long ruleIdx, String userId) {
        String uid = requireUserId(userId);
        requireRule(ruleIdx, uid);
        int deleted = mailForwardMapper.deleteRule(ruleIdx, uid);
        if (deleted == 0) {
            throw new IllegalStateException("예외 규칙 삭제에 실패했습니다.");
        }
        log.info("자동전달 예외 규칙 삭제 ruleIdx={} by={}", ruleIdx, uid);
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    private List<MailForwardRuleDto> rulesOf(String userId) {
        return mailForwardMapper.selectRulesByUserId(userId).stream()
                .map(MailForwardRuleDto::fromRow)
                .toList();
    }

    /**
     * 전달 주소로 써도 되는가.
     *
     * <p>두 가지를 막는다. 둘 다 <b>무한 전달</b>로 이어지는 설정이다.
     * <ol>
     *   <li>우리 시스템 발신 주소({@code resend.from-email} 계열) — 그 주소로 보낸 메일은
     *       다시 우리 수신함으로 들어와 또 전달된다</li>
     *   <li>설정 주인 본인의 사내 주소 — 자기 앞으로 온 메일을 자기에게 다시 보내는 것이라
     *       받는 즉시 다시 전달 대상이 된다</li>
     * </ol>
     *
     * <p>실행 단계({@link MailAutoProcessService})에도 같은 방어가 한 겹 더 있다. 설정을
     * 만든 뒤에 사원 주소가 바뀌는 경우까지 여기서 잡을 수는 없기 때문이다.
     */
    private void ensureForwardable(String forwardEmail, String userId) {
        if (properties.isFromEmailAllowed(forwardEmail)) {
            throw new IllegalArgumentException(
                    "시스템 발신 주소로는 전달할 수 없습니다: " + forwardEmail);
        }
        List<MailUserRefJdbcRow> refs =
                mailRecipientMapper.selectUserRefsByEmails(List.of(forwardEmail));
        for (MailUserRefJdbcRow ref : refs) {
            if (userId.equalsIgnoreCase(ref.userId())) {
                throw new IllegalArgumentException(
                        "본인 주소로는 전달할 수 없습니다(메일이 계속 되돌아옵니다): " + forwardEmail);
            }
        }
    }

    private static String normalizeMatchType(String matchType) {
        if (!StringUtils.hasText(matchType)) {
            throw new IllegalArgumentException("매칭 방식(EMAIL 또는 DOMAIN)을 지정해 주세요.");
        }
        String value = matchType.trim().toUpperCase(Locale.ROOT);
        if (!MATCH_EMAIL.equals(value) && !MATCH_DOMAIN.equals(value)) {
            throw new IllegalArgumentException("매칭 방식은 EMAIL 또는 DOMAIN 이어야 합니다.");
        }
        return value;
    }

    /**
     * 매칭 비교값 정규화.
     *
     * <p>DOMAIN 은 {@code @} 없이 도메인만 저장한다. 사용자가 {@code @hometax.go.kr} 이나
     * {@code tax@hometax.go.kr} 을 넣어도 도메인만 떼어 낸다 — 거부하고 다시 입력하게 하는
     * 것보다 의도대로 받아 주는 편이 낫고, 저장 형태가 하나여야 판정도 단순해진다.
     */
    private static String normalizeMatchVal(String matchType, String matchVal) {
        if (!StringUtils.hasText(matchVal)) {
            throw new IllegalArgumentException("발신자 조건을 입력해 주세요.");
        }
        String value = matchVal.trim().toLowerCase(Locale.ROOT);
        if (MATCH_DOMAIN.equals(matchType)) {
            int at = value.lastIndexOf('@');
            if (at >= 0) {
                value = value.substring(at + 1);
            }
            if (value.isEmpty() || value.indexOf('.') < 0) {
                throw new IllegalArgumentException("도메인 형식이 올바르지 않습니다: " + matchVal);
            }
            return value;
        }
        if (value.indexOf('@') <= 0 || value.endsWith("@")) {
            throw new IllegalArgumentException("발신자 주소 형식이 올바르지 않습니다: " + matchVal);
        }
        return value;
    }

    /** 소유자 조건이 SQL 에 있으므로 남의 규칙이면 null 이 오고, 그대로 404 가 된다. */
    private MailForwardRuleJdbcRow requireRule(long ruleIdx, String userId) {
        MailForwardRuleJdbcRow row = mailForwardMapper.selectRuleByIdx(ruleIdx, userId);
        if (row == null) {
            throw new ResourceNotFoundException("자동전달 예외 규칙", "ruleIdx", ruleIdx);
        }
        return row;
    }

    private static String requireUserId(String userId) {
        if (!StringUtils.hasText(userId)) {
            throw new IllegalStateException("로그인 정보를 확인할 수 없습니다.");
        }
        return userId.trim();
    }
}
