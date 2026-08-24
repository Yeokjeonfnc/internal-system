package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;
import java.time.ZoneId;

/**
 * 사용자 정의 메일함 한 개(화면 응답용).
 *
 * <p>{@code MailListItemDto} 와 같은 규칙 — 문자열에 null 을 내보내지 않는다.
 * Flutter 모델이 수동 fromJson 이라 null 하나에 사이드바 전체가 흰 화면이 된다.
 * 다만 {@code parentFolderIdx} 는 null 을 유지한다. "최상위 메일함"과 "0번 메일함의
 * 자식"은 다른 뜻이라 0 으로 뭉갤 수 없다.
 */
public record MailFolderDto(
        long folderIdx,
        Long parentFolderIdx,
        String folderNm,
        int sortOrder,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    public static MailFolderDto fromRow(MailFolderJdbcRow row) {
        return new MailFolderDto(
                row.mailFolderIdx() == null ? 0L : row.mailFolderIdx(),
                row.parentFolderIdx(),
                row.folderNm() == null ? "" : row.folderNm(),
                row.sortOrder() == null ? 0 : row.sortOrder(),
                toSeoul(row.createdAt()),
                toSeoul(row.updatedAt()));
    }

    /** DB 는 timestamptz(UTC)로 주고 화면은 한국 시각을 기대한다. DTO 경계에서 한 번만 바꾼다. */
    private static OffsetDateTime toSeoul(OffsetDateTime value) {
        return value == null ? null : value.atZoneSameInstant(SEOUL).toOffsetDateTime();
    }
}
