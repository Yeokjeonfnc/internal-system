package com.yeokjeon.erp.active.dto;

import java.time.LocalDate;
import java.util.List;

public record ActivityPlanDayDetailDto(
        LocalDate planDate,
        int assigneeUserIdx,
        String assigneeUserName,
        boolean canEdit,
        List<ActivityPlanStoreItemDto> plannedStores,
        List<ActivityPlanStoreItemDto> completedStores) {}
