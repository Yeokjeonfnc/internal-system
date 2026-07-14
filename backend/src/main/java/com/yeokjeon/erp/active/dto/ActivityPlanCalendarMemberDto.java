package com.yeokjeon.erp.active.dto;

public record ActivityPlanCalendarMemberDto(
        Integer userIdx,
        String userName,
        Integer deptIdx,
        String deptNm,
        boolean selfUser) {}
