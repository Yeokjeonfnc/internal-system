package com.yeokjeon.erp.active.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;

public record ActivityPlanWriteRequestDto(
        @NotBlank String title,
        @NotNull LocalDateTime planStartAt,
        @NotNull LocalDateTime planEndAt,
        String allDayYn,
        String locationTxt,
        String onlineMeetingYn,
        String planStatus,
        String memoTxt) {}
