package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * 첨부 한 건.
 *
 * <p>{@code downloadable} 을 서버가 계산해서 내려 주는 이유: 수신 첨부는 웹훅 시점에
 * 메타만 생기고 실물은 나중에 배치가 받아 온다. 화면이 "fetchedAt 이 null 이 아니고
 * storedName 도 있고 삭제도 안 됐으면" 같은 판정을 직접 하게 두면 규칙이 갈라진다.
 *
 * <p>{@code fetchedAt} 은 null 을 유지한다 — "아직 못 받았다"와 "1970년에 받았다"를
 * 구분해야 하므로 기본값으로 뭉갤 수 없다.
 */
public record MailAttachmentDto(
        long mailAttIdx,
        long mailIdx,
        String fileName,
        long fileSize,
        String contentType,
        String contentId,
        boolean inline,
        boolean downloadable,
        OffsetDateTime fetchedAt) {

    public static MailAttachmentDto fromRow(MailAttJdbcRow row) {
        boolean deleted = Boolean.TRUE.equals(row.deletedYn());
        boolean downloadable = row.fetchedAt() != null
                && row.storedName() != null
                && !row.storedName().isBlank()
                && !deleted;
        return new MailAttachmentDto(
                row.mailAttIdx() == null ? 0L : row.mailAttIdx(),
                row.mailIdx() == null ? 0L : row.mailIdx(),
                row.fileName() == null ? "" : row.fileName(),
                row.fileSize() == null ? 0L : row.fileSize(),
                row.contentType() == null ? "" : row.contentType(),
                row.contentId() == null ? "" : row.contentId(),
                "Y".equals(row.inlineYn()),
                downloadable,
                MailListItemDto.toSeoul(row.fetchedAt()));
    }
}
