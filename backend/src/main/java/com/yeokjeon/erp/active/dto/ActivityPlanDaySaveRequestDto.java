package com.yeokjeon.erp.active.dto;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.List;

public record ActivityPlanDaySaveRequestDto(
        @NotNull LocalDate planDate, @NotNull List<Integer> storeIdxs) {}
