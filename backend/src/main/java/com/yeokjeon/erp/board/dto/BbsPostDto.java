package com.yeokjeon.erp.board.dto;

import java.time.OffsetDateTime;

public record BbsPostDto(
        Integer postIdx,
        Integer folderIdx,
        String folderNm,
        Integer storeIdx,
        String storeNm,
        String title,
        String bodyTxt,
        String privateYn,
        String noticeYn,
        Integer viewCnt,
        String createdBy,
        String authorNm,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        boolean hasAttachment,
        String thumbContentType,
        Integer thumbDocIdx) {

    public static BbsPostDto fromRow(BbsPostListJdbcRow row) {
        return new BbsPostDto(
                row.postIdx(),
                row.folderIdx(),
                row.folderNm(),
                row.storeIdx(),
                row.storeNm(),
                row.title(),
                null,
                row.privateYn(),
                row.noticeYn(),
                row.viewCnt(),
                row.createdBy(),
                row.authorNm(),
                row.createdAt(),
                row.updatedAt(),
                Boolean.TRUE.equals(row.hasAttachment()),
                row.thumbContentType(),
                row.thumbDocIdx());
    }

    public static BbsPostDto fromDetailRow(BbsPostDetailJdbcRow row) {
        return new BbsPostDto(
                row.postIdx(),
                row.folderIdx(),
                row.folderNm(),
                row.storeIdx(),
                row.storeNm(),
                row.title(),
                row.bodyTxt(),
                row.privateYn(),
                row.noticeYn(),
                row.viewCnt(),
                row.createdBy(),
                row.authorNm(),
                row.createdAt(),
                row.updatedAt(),
                Boolean.TRUE.equals(row.hasAttachment()),
                null,
                null);
    }
}
