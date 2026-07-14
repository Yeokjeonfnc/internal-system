package com.yeokjeon.erp.master.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/** 가맹점 출입 태그 기록. */
public record UsageLogTagRequestDto(
        @NotBlank String userId,
        @NotBlank String userNm,
        String deptNm,
        String positionNm,
        String svYn,
        @NotNull Integer storeIdx,
        @NotBlank String storeNm,
        String address,
        @NotBlank String tagUid,
        @NotNull Double lat,
        @NotNull Double lng) {}
