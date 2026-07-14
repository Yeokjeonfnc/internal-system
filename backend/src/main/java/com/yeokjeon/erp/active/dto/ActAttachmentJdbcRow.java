package com.yeokjeon.erp.active.dto;

import java.time.LocalDateTime;

public record ActAttachmentJdbcRow(
        Integer actAttIdx,
        Integer actIdx,
        String fileName,
        String storedName,
        Long fileSize,
        String contentType,
        LocalDateTime attachedAt,
        LocalDateTime modifiedAt,
        String modifiedBy,
        String modifiedByNm,
        boolean deletedYn) {}
