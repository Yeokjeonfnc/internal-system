package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;
import java.time.ZoneId;

/**
 * 자동분류 규칙 한 개(화면 응답용).
 *
 * <p>{@link MailListItemDto} 와 같은 규칙 — 문자열에 null 을 내보내지 않는다.
 * Flutter 모델이 수동 fromJson 이라 null 하나에 설정 화면 전체가 흰 화면이 된다.
 * 다만 <b>조건 필드는 빈 문자열이 곧 "이 조건 없음"</b> 이라는 약속이다. 화면은
 * {@code fromVal} 이 비었으면 보낸사람 조건 행을 아예 그리지 않으면 된다.
 *
 * <p>{@code actionFolderIdx} 만 null 을 유지한다. "메일함 이동이 아님"과 "0번 메일함"은
 * 다른 뜻이라 0 으로 뭉갤 수 없다.
 */
public record MailRuleDto(
        long ruleIdx,
        String ruleNm,
        int sortOrder,
        boolean use,
        /** CONTAINS(포함) / EQUALS(일치) / STARTS(시작함). 조건이 없으면 "". */
        String fromOp,
        String fromVal,
        String toOp,
        String toVal,
        String subjOp,
        String subjVal,
        /** MOVE / READ */
        String actionType,
        Long actionFolderIdx,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    public static MailRuleDto fromRow(MailRuleJdbcRow row) {
        return new MailRuleDto(
                row.mailRuleIdx() == null ? 0L : row.mailRuleIdx(),
                nz(row.ruleNm()),
                row.sortOrder() == null ? 0 : row.sortOrder(),
                "Y".equals(row.useYn()),
                nz(row.fromOp()),
                nz(row.fromVal()),
                nz(row.toOp()),
                nz(row.toVal()),
                nz(row.subjOp()),
                nz(row.subjVal()),
                nz(row.actionType()),
                row.actionFolderIdx(),
                toSeoul(row.createdAt()),
                toSeoul(row.updatedAt()));
    }

    private static String nz(String value) {
        return value == null ? "" : value;
    }

    /** DB 는 timestamptz(UTC)로 주고 화면은 한국 시각을 기대한다. DTO 경계에서 한 번만 바꾼다. */
    private static OffsetDateTime toSeoul(OffsetDateTime value) {
        return value == null ? null : value.atZoneSameInstant(SEOUL).toOffsetDateTime();
    }
}
