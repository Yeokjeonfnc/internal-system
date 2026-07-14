package com.yeokjeon.erp.franchise.dto;

import java.math.BigDecimal;

/** NFC UID 조회 — 출입 태그 시 매장·좌표 확인용. */
public record StoreNfcTagLookupDto(
        Integer storeIdx,
        String storeNm,
        String brandNm,
        BigDecimal latitude,
        BigDecimal longitude,
        String tagUid) {}
