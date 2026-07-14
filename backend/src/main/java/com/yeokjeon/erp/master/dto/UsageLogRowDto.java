package com.yeokjeon.erp.master.dto;

import java.time.OffsetDateTime;

/** 사용기록 목록 행. */
public record UsageLogRowDto(
        Long logIdx,
        String userId,
        String userNm,
        String deptNm,
        String positionNm,
        String svYn,
        String useType,
        String useTypeNm,
        String useDetail,
        String menuCd,
        Integer storeIdx,
        String storeNm,
        String tagUid,
        Integer distanceM,
        OffsetDateTime usedAt) {}
