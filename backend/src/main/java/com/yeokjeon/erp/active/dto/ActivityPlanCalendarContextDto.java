package com.yeokjeon.erp.active.dto;

import java.util.List;

public record ActivityPlanCalendarContextDto(
        Integer viewerUserIdx,
        String viewerUserName,
        Integer viewerDeptIdx,
        String viewerDeptNm,
        List<ActivityPlanCalendarTeamDto> teams,
        List<ActivityPlanCalendarMemberDto> members) {}
