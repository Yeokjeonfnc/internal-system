package com.yeokjeon.erp.board.dto;

import java.time.OffsetDateTime;

public record BbsDocumentDto(
        Integer bbsDocIdx,
        Integer postIdx,
        String fileName,
        String storedName,
        long fileSize,
        String contentType,
        OffsetDateTime attachedAt,
        boolean fileExists) {

    public static BbsDocumentDto fromRow(BbsDocumentJdbcRow row, boolean fileExists) {
        return new BbsDocumentDto(
                row.bbsDocIdx(),
                row.postIdx(),
                row.fileName(),
                row.storedName(),
                row.fileSize() == null ? 0L : row.fileSize(),
                row.contentType(),
                row.attachedAt(),
                fileExists);
    }
}
