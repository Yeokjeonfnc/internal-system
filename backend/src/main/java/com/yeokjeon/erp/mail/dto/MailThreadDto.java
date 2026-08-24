package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * 스레드(대화 묶음) 하나와 거기 속한 메일 목록.
 *
 * <p>메일은 {@code MailListItemDto} 로만 담는다 — 대화를 펼칠 때 본문까지 전부
 * 끌어오면 스레드가 길어질수록 응답이 눈덩이처럼 커진다. 본문은 사용자가 실제로
 * 펼친 한 건만 상세 API 로 따로 읽는다.
 */
public record MailThreadDto(
        long threadIdx,
        String subjectNorm,
        int mailCnt,
        OffsetDateTime firstMailAt,
        OffsetDateTime lastMailAt,
        List<MailListItemDto> mails) {

    public static MailThreadDto of(MailThreadMstJdbcRow row, List<MailMstJdbcRow> mails) {
        List<MailListItemDto> items = mails == null
                ? List.of()
                : mails.stream().map(MailListItemDto::fromRow).toList();
        return new MailThreadDto(
                row.threadIdx() == null ? 0L : row.threadIdx(),
                row.subjectNorm() == null ? "" : row.subjectNorm(),
                row.mailCnt() == null ? items.size() : row.mailCnt(),
                MailListItemDto.toSeoul(row.firstMailAt()),
                MailListItemDto.toSeoul(row.lastMailAt()),
                items);
    }
}
