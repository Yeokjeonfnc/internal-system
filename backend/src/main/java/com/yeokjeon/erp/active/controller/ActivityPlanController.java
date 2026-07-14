package com.yeokjeon.erp.active.controller;

import com.yeokjeon.erp.active.dto.ActivityPlanCalendarContextDto;
import com.yeokjeon.erp.active.dto.ActivityPlanDayDetailDto;
import com.yeokjeon.erp.active.dto.ActivityPlanDaySaveRequestDto;
import com.yeokjeon.erp.active.dto.ActivityPlanMonthResponseDto;
import com.yeokjeon.erp.active.dto.TeamViewPermissionDto;
import com.yeokjeon.erp.active.dto.TeamViewPermissionSaveRequestDto;
import com.yeokjeon.erp.active.service.ActivityPlanService;
import com.yeokjeon.erp.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@Slf4j
@RestController
@RequiredArgsConstructor
public class ActivityPlanController {

    private final ActivityPlanService activityPlanService;

    @GetMapping("/activity-plans/calendar-context")
    public ResponseEntity<ApiResponse<ActivityPlanCalendarContextDto>> calendarContext(
            @RequestParam int viewerUserIdx) {
        return ResponseEntity.ok(
                ApiResponse.success(activityPlanService.calendarContext(viewerUserIdx)));
    }

    @GetMapping("/activity-plans/month")
    public ResponseEntity<ApiResponse<ActivityPlanMonthResponseDto>> monthPlans(
            @RequestParam int viewerUserIdx,
            @RequestParam int year,
            @RequestParam int month,
            @RequestParam(required = false) List<Integer> assigneeUserIdxs) {
        return ResponseEntity.ok(ApiResponse.success(
                activityPlanService.monthPlans(viewerUserIdx, year, month, assigneeUserIdxs)));
    }

    @GetMapping("/activity-plans/day")
    public ResponseEntity<ApiResponse<ActivityPlanDayDetailDto>> dayDetail(
            @RequestParam int viewerUserIdx,
            @RequestParam int assigneeUserIdx,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate planDate) {
        return ResponseEntity.ok(ApiResponse.success(
                activityPlanService.dayDetail(viewerUserIdx, assigneeUserIdx, planDate)));
    }

    @PutMapping("/activity-plans/day")
    public ResponseEntity<ApiResponse<Void>> saveDayStores(
            @RequestParam int viewerUserIdx,
            @RequestParam(required = false) String createdBy,
            @Valid @RequestBody ActivityPlanDaySaveRequestDto body) {
        activityPlanService.saveDayStores(viewerUserIdx, createdBy, body);
        return ResponseEntity.ok(ApiResponse.success("활동 계획이 저장되었습니다.", null));
    }

    @GetMapping("/users/{userIdx}/team-view-permissions")
    public ResponseEntity<ApiResponse<List<TeamViewPermissionDto>>> teamViewPermissions(
            @PathVariable int userIdx) {
        return ResponseEntity.ok(
                ApiResponse.success(activityPlanService.listTeamViewPermissions(userIdx)));
    }

    @PutMapping("/users/{userIdx}/team-view-permissions")
    public ResponseEntity<ApiResponse<Void>> saveTeamViewPermissions(
            @PathVariable int userIdx,
            @RequestParam(required = false) String grantedBy,
            @Valid @RequestBody TeamViewPermissionSaveRequestDto body) {
        activityPlanService.saveTeamViewPermissions(userIdx, grantedBy, body);
        return ResponseEntity.ok(ApiResponse.success("팀 캘린더 열람 권한이 저장되었습니다.", null));
    }
}
