package com.yeokjeon.erp.eap.dto;

import java.time.OffsetDateTime;

public record EapDocLineDto(
        Long lineId,
        String roleCd,
        int sortOrder,
        String userId,
        String userNm,
        String titleNm,
        String lineStatus,
        OffsetDateTime actedAt) {

    public static EapDocLineDto fromRow(EapDocLineJdbcRow row) {
        return new EapDocLineDto(
                row.lineId(),
                row.roleCd() == null ? "" : row.roleCd(),
                row.sortOrder() == null ? 0 : row.sortOrder(),
                row.userId() == null ? "" : row.userId(),
                row.userNm() == null ? "" : row.userNm(),
                row.titleNm() == null ? "" : row.titleNm(),
                row.lineStatus() == null ? "WAIT" : row.lineStatus(),
                EapDocumentDto.toSeoul(row.actedAt()));
    }
}
