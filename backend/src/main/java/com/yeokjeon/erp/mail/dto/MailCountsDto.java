package com.yeokjeon.erp.mail.dto;

import java.util.List;

/**
 * 메일함별 건수(사이드바 배지용).
 *
 * <p>집계 쿼리가 한 행도 못 돌려주는 경우를 대비해 {@code empty()} 를 둔다. 배지에
 * null 이 흘러가면 화면이 아니라 숫자 렌더링에서 터진다. 같은 이유로 {@code folders}
 * 도 절대 null 을 담지 않는다 — 비어 있으면 빈 리스트다.
 *
 * <p>기본 메일함은 필드로, 사용자 정의 메일함은 {@code folders} 리스트로 나눠 담는다.
 * 사용자 함은 개수가 가변이라 필드로 표현할 수 없고, 화면에서도 기본함 아래 별도
 * 구획으로 그리기 때문에 구조가 갈라져 있는 편이 오히려 쓰기 편하다.
 */
public record MailCountsDto(
        int inbox,
        int inboxUnread,
        int sent,
        int draft,
        int scheduled,
        int failed,
        int spam,
        int spamUnread,
        int trash,
        int star,
        int starUnread,
        int all,
        int allUnread,
        /** 사용자 정의 메일함. 없으면 빈 리스트(절대 null 아님). */
        List<MailFolderCountDto> folders) {

    public static MailCountsDto empty() {
        return new MailCountsDto(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, List.of());
    }

    public static MailCountsDto fromRow(MailCountsJdbcRow row, List<MailFolderCountDto> folders) {
        List<MailFolderCountDto> safeFolders = folders == null ? List.of() : folders;
        if (row == null) {
            // 기본함 집계만 비었을 뿐 사용자 메일함 목록은 살아 있을 수 있다.
            // 그쪽까지 통째로 버리면 사이드바에서 사용자 함이 사라진다.
            return new MailCountsDto(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, safeFolders);
        }
        return new MailCountsDto(
                zero(row.inbox()),
                zero(row.inboxUnread()),
                zero(row.sent()),
                zero(row.draft()),
                zero(row.scheduled()),
                zero(row.failed()),
                zero(row.spam()),
                zero(row.spamUnread()),
                zero(row.trash()),
                zero(row.star()),
                zero(row.starUnread()),
                zero(row.all()),
                zero(row.allUnread()),
                safeFolders);
    }

    private static int zero(Integer value) {
        return value == null ? 0 : value;
    }
}
