package com.yeokjeon.erp.active.dto;

import java.time.LocalDate;
import java.util.List;

public record ActivityPlanMonthDayDto(LocalDate planDate, List<ActivityPlanStoreItemDto> items) {}
