package com.yeokjeon.erp.board.dto;

import java.time.OffsetDateTime;

public record BbsPostListJdbcRow(
        Integer postIdx,
        Integer folderIdx,
        String folderNm,
        Integer storeIdx,
        String storeNm,
        String title,
        String privateYn,
        String noticeYn,
        Integer viewCnt,
        String createdBy,
        String authorNm,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        Boolean hasAttachment,
        String thumbContentType,
        Integer thumbDocIdx) {}
