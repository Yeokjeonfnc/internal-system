package com.yeokjeon.erp.eap.dto;

import java.time.OffsetDateTime;

public record EapDocLineJdbcRow(
        Long lineId,
        Long mappingId,
        String roleCd,
        Integer sortOrder,
        String userId,
        String userNm,
        String titleNm,
        String lineStatus,
        OffsetDateTime actedAt) {
}
