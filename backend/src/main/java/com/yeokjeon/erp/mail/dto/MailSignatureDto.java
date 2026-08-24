package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;
import java.time.ZoneId;

/**
 * 개인 서명 한 개(화면 응답용).
 *
 * <p>{@code defaultNew}/{@code defaultReply} 를 char(1) 그대로 내보내지 않고 boolean 으로
 * 바꾼다. 화면은 체크박스 하나라 'Y'/'N' 문자열을 비교하게 두면 프런트마다
 * 대소문자·공백 처리가 갈린다.
 */
public record MailSignatureDto(
        long signIdx,
        String signNm,
        String signHtml,
        /** 새 메일 작성 시 기본으로 붙일 서명인가. 사용자당 최대 하나만 true. */
        boolean defaultNew,
        /** 답장·전달 시 기본으로 붙일 서명인가. 사용자당 최대 하나만 true. */
        boolean defaultReply,
        int sortOrder,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    public static MailSignatureDto fromRow(MailSignatureJdbcRow row) {
        return new MailSignatureDto(
                row.mailSignIdx() == null ? 0L : row.mailSignIdx(),
                row.signNm() == null ? "" : row.signNm(),
                row.signHtml() == null ? "" : row.signHtml(),
                "Y".equals(row.defaultNewYn()),
                "Y".equals(row.defaultReplyYn()),
                row.sortOrder() == null ? 0 : row.sortOrder(),
                toSeoul(row.createdAt()),
                toSeoul(row.updatedAt()));
    }

    private static OffsetDateTime toSeoul(OffsetDateTime value) {
        return value == null ? null : value.atZoneSameInstant(SEOUL).toOffsetDateTime();
    }
}
