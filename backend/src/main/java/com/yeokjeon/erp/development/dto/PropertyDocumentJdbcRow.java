package com.yeokjeon.erp.development.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

/** {@code property_doc} 조회 원시 행. */
public record PropertyDocumentJdbcRow(
        Integer propertyDocIdx,
        Integer propIdx,
        String fileName,
        String storedName,
        Long fileSize,
        String contentType,
        LocalDate attachmentBaseDate,
        LocalDateTime attachedAt,
        LocalDateTime modifiedAt,
        String modifiedBy,
        String modifiedByNm,
        boolean deletedYn) {}
