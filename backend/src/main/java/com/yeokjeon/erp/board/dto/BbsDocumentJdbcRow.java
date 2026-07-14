package com.yeokjeon.erp.board.dto;

import java.time.OffsetDateTime;

public record BbsDocumentJdbcRow(
        Integer bbsDocIdx,
        Integer postIdx,
        String fileName,
        String storedName,
        Long fileSize,
        String contentType,
        OffsetDateTime attachedAt) {}
