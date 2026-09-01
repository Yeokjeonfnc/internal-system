package com.yeokjeon.erp.board.dto;

import java.time.OffsetDateTime;

public record BbsCommentDto(
        Integer commentIdx,
        Integer postIdx,
        String bodyTxt,
        String createdBy,
        String authorNm,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {

    public static BbsCommentDto fromRow(BbsCommentJdbcRow row) {
        return new BbsCommentDto(
                row.commentIdx(),
                row.postIdx(),
                row.bodyTxt(),
                row.createdBy(),
                row.authorNm(),
                row.createdAt(),
                row.updatedAt());
    }
}
