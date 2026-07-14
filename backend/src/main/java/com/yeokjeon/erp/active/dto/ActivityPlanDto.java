package com.yeokjeon.erp.active.dto;

import java.time.OffsetDateTime;

public record ActivityPlanDto(
        Integer planIdx,
        Integer assigneeUserIdx,
        String assigneeUserName,
        Integer assigneeDeptIdx,
        String assigneeDeptNm,
        String title,
        OffsetDateTime planStartAt,
        OffsetDateTime planEndAt,
        String allDayYn,
        String locationTxt,
        String onlineMeetingYn,
        String planStatus,
        String memoTxt,
        String createdBy,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {}
