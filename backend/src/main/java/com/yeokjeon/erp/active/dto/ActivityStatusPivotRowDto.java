package com.yeokjeon.erp.active.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.LocalDate;

/** 활동 현황 피벗(가맹점별/담당자별) — 기존 status API Map 키와 동일. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ActivityStatusPivotRowDto(
        String storeNm,
        String userName,
        String userId,
        LocalDate actDt,
        Long count) {}
