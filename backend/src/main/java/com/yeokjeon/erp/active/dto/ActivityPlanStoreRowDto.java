package com.yeokjeon.erp.active.dto;

import java.time.LocalDate;

public record ActivityPlanStoreRowDto(
        LocalDate planDate,
        int storeIdx,
        String storeNm,
        String brandNm,
        int assigneeUserIdx,
        String assigneeUserName,
        boolean planned,
        boolean completed) {}
