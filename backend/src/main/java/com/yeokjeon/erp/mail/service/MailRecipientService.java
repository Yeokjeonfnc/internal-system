package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.mail.dto.MailRecipientDto;
import com.yeokjeon.erp.mail.mapper.MailRecipientMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 조직도 수신자 검색 (mal001-J).
 *
 * <p>사원(user_mst) + 거래처(partner_mst) + 부서(dept_mst) 를 한 목록으로 합쳐 준다.
 * 화면이 탭을 나눠 세 번 호출하게 하면, "이름 일부만 아는" 가장 흔한 검색에서
 * 사용자가 어느 탭을 볼지부터 정해야 한다.
 *
 * <p>부서를 고르면 {@link #deptMembers} 로 부서원 주소를 펼쳐 받는다. 부서 자체에는
 * 메일주소가 없어서다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailRecipientService {

    /**
     * 검색 결과 상한.
     *
     * <p>전체 대상이 73건(사원 43 + 거래처 5 + 부서 25)이라 사실상 전부 담기는 값이다.
     * 그래도 상한을 두는 이유는 조직이 커졌을 때 이 API 가 조용히 무거워지지 않게 하려는 것.
     */
    private static final int DEFAULT_LIMIT = 100;
    private static final int MAX_LIMIT = 300;

    /**
     * Resend 의 {@code to} 상한.
     *
     * <p>한 요청에 50명을 넘기면 Resend 가 거부한다. 부서 전체 발송에서 이 값을 넘으면
     * 발송이 여러 통으로 나뉜다({@code MailSendService.compose} 가 처리).
     * 여기서는 화면이 미리 안내할 수 있도록 같은 상수를 노출한다.
     */
    public static final int RESEND_TO_LIMIT = 50;

    private final MailRecipientMapper mailRecipientMapper;

    /**
     * 통합 검색.
     *
     * @param keyword null/빈 값이면 전체를 준다. 화면 첫 진입에서 조직도를 그대로
     *                펼쳐 보여 줄 수 있어야 해서 빈 검색을 허용한다.
     */
    @Transactional(readOnly = true)
    public List<MailRecipientDto> search(String keyword, int limit) {
        // 목록 검색과 달리 최소 글자수 제한을 두지 않는다. 대상이 73건뿐이라
        // 1글자 검색이 전체 스캔이어도 부담이 없고, 성(姓) 한 글자로 찾는 일이 흔하다.
        return mailRecipientMapper.search(blankToNull(keyword), clampLimit(limit)).stream()
                .map(MailRecipientDto::fromRow)
                .toList();
    }

    /**
     * 부서원 메일주소 펼치기.
     *
     * <p>{@code includeSub} 기본값이 false 인 이유: 다우오피스도 트리에서 고른 노드만
     * 넣는 것이 기본이고, 무엇보다 상위 부서를 잘못 고르면 전 직원에게 나가는 사고가 난다.
     * 하위 포함은 사용자가 명시적으로 켤 때만 동작해야 한다.
     */
    @Transactional(readOnly = true)
    public List<MailRecipientDto> deptMembers(int deptIdx, boolean includeSub) {
        List<MailRecipientDto> members =
                mailRecipientMapper.selectDeptMembers(deptIdx, includeSub).stream()
                        .map(MailRecipientDto::fromRow)
                        .toList();
        if (members.size() > RESEND_TO_LIMIT) {
            // 막지는 않는다 — 발송 단계가 50명씩 나눠 보내도록 돼 있다.
            // 다만 여러 통으로 갈라져 나가면 수신자들이 서로의 주소를 볼 수 없게 되므로
            // (같은 to 목록에 없다) 로그에는 남겨 둔다.
            log.info("부서 수신자 {}명 — Resend to 상한({})을 넘어 발송이 여러 통으로 나뉜다. deptIdx={}",
                    members.size(), RESEND_TO_LIMIT, deptIdx);
        }
        return members;
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    private static int clampLimit(int limit) {
        if (limit <= 0) {
            return DEFAULT_LIMIT;
        }
        return Math.min(limit, MAX_LIMIT);
    }

    private static String blankToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
