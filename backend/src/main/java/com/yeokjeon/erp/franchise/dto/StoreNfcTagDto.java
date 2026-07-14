package com.yeokjeon.erp.franchise.dto;

import java.time.OffsetDateTime;

/** 가맹점에 등록된 NFC 태그 UID. */
public record StoreNfcTagDto(
        Integer storeIdx,
        String tagUid,
        String useYn,
        OffsetDateTime registeredAt,
        String registeredBy) {}
