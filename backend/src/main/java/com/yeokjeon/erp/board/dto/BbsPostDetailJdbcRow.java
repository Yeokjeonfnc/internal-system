package com.yeokjeon.erp.board.dto;

import java.time.OffsetDateTime;

public record BbsPostDetailJdbcRow(
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
        Boolean hasAttachment) {}
