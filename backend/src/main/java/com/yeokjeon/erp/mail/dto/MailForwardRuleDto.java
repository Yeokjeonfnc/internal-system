package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;
import java.time.ZoneId;

/**
 * 자동전달 예외 규칙 한 개(화면 응답용).
 *
 * <p>문자열에 null 을 내보내지 않는다({@link MailListItemDto} 와 같은 규칙).
 */
public record MailForwardRuleDto(
        long ruleIdx,
        /** EMAIL / DOMAIN */
        String matchType,
        String matchVal,
        String forwardEmail,
        boolean use,
        int sortOrder,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    public static MailForwardRuleDto fromRow(MailForwardRuleJdbcRow row) {
        return new MailForwardRuleDto(
                row.mailFwdRuleIdx() == null ? 0L : row.mailFwdRuleIdx(),
                nz(row.matchType()),
                nz(row.matchVal()),
                nz(row.forwardEmail()),
                "Y".equals(row.useYn()),
                row.sortOrder() == null ? 0 : row.sortOrder(),
                toSeoul(row.createdAt()),
                toSeoul(row.updatedAt()));
    }

    private static String nz(String value) {
        return value == null ? "" : value;
    }

    private static OffsetDateTime toSeoul(OffsetDateTime value) {
        return value == null ? null : value.atZoneSameInstant(SEOUL).toOffsetDateTime();
    }
}
