package com.yeokjeon.erp.franchise.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

/** {@code store_doc} 조회 원시 행. */
public record StoreDocumentJdbcRow(
        Integer storeDocIdx,
        Integer storeIdx,
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
