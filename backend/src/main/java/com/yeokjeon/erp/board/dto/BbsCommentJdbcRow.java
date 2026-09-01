package com.yeokjeon.erp.board.dto;

import java.time.OffsetDateTime;

public record BbsCommentJdbcRow(
        Integer commentIdx,
        Integer postIdx,
        String bodyTxt,
        String createdBy,
        String authorNm,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {}
