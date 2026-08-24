package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * mail_forward_rule 한 행(자동전달 예외 규칙).
 *
 * <p>필드 순서를 XML resultMap 의 {@code <arg>} 순서 = 테이블 컬럼 순서와 맞춰 둘 것.
 */
public record MailForwardRuleJdbcRow(
        Long mailFwdRuleIdx,
        String userId,
        /** EMAIL=주소 완전일치 / DOMAIN=도메인 일치(@ 없이 저장) */
        String matchType,
        String matchVal,
        String forwardEmail,
        String useYn,
        Integer sortOrder,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {
}
