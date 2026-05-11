package com.yeokjeon.erp.franchise.dto;

import java.time.LocalDateTime;

/** `store_history` 조회 원시 행 — `StrService`에서 `StoreHistoryRowDto`로 가공. */
public record StoreHistoryJdbcRow(
        Long hisIdx,
        Integer storeIdx,
        String chgType,
        String storeNm,
        String chgContentRaw,
        String chgUserId,
        LocalDateTime chgDt) {}
