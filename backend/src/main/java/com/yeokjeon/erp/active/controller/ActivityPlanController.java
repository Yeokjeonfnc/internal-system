package com.yeokjeon.erp.active.controller;

import com.yeokjeon.erp.active.dto.ActivityPlanCalendarContextDto;
import com.yeokjeon.erp.active.dto.ActivityPlanDayDetailDto;
import com.yeokjeon.erp.active.dto.ActivityPlanDaySaveRequestDto;
import com.yeokjeon.erp.active.dto.ActivityPlanMonthResponseDto;
import com.yeokjeon.erp.active.dto.TeamViewPermissionDto;
import com.yeokjeon.erp.active.dto.TeamViewPermissionSaveRequestDto;
import com.yeokjeon.erp.active.service.ActivityPlanService;
import com.yeokjeon.erp.auth.access.AccessDeniedException;
import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.common.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
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
    private final MenuAccessGuard menuAccessGuard;

    /*
     * viewerUserIdx 는 "누가 보는가"를 정하는 값이고, 서비스는 이 값으로 팀 캘린더
     * 열람 권한을 판정한다. 토큰 필터는 문자열 userId 파라미터만 대조하므로 숫자
     * userIdx 는 걸러지지 않았다 — 남의 번호를 넣으면 볼 수 없는 팀 일정이 열렸다.
     * 아래 ensureSelfUserIdx 로 토큰 주인의 번호와 일치하는지 확인한다.
     */

    @GetMapping("/activity-plans/calendar-context")
    public ResponseEntity<ApiResponse<ActivityPlanCalendarContextDto>> calendarContext(
            @RequestParam int viewerUserIdx, HttpServletRequest request) {
        ensureViewer(request, viewerUserIdx);
        return ResponseEntity.ok(
                ApiResponse.success(activityPlanService.calendarContext(viewerUserIdx)));
    }

    @GetMapping("/activity-plans/month")
    public ResponseEntity<ApiResponse<ActivityPlanMonthResponseDto>> monthPlans(
            @RequestParam int viewerUserIdx,
            @RequestParam int year,
            @RequestParam int month,
            @RequestParam(required = false) List<Integer> assigneeUserIdxs,
            HttpServletRequest request) {
        ensureViewer(request, viewerUserIdx);
        return ResponseEntity.ok(ApiResponse.success(
                activityPlanService.monthPlans(viewerUserIdx, year, month, assigneeUserIdxs)));
    }

    @GetMapping("/activity-plans/day")
    public ResponseEntity<ApiResponse<ActivityPlanDayDetailDto>> dayDetail(
            @RequestParam int viewerUserIdx,
            @RequestParam int assigneeUserIdx,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate planDate,
            HttpServletRequest request) {
        ensureViewer(request, viewerUserIdx);
        return ResponseEntity.ok(ApiResponse.success(
                activityPlanService.dayDetail(viewerUserIdx, assigneeUserIdx, planDate)));
    }

    @PutMapping("/activity-plans/day")
    public ResponseEntity<ApiResponse<Void>> saveDayStores(
            @RequestParam int viewerUserIdx,
            @RequestParam(required = false) String createdBy,
            @Valid @RequestBody ActivityPlanDaySaveRequestDto body,
            HttpServletRequest request) {
        String caller = MenuAccessGuard.callerId(request);
        menuAccessGuard.ensureSelfUserIdx(caller, viewerUserIdx);
        // 작성자는 기록용이므로 클라이언트 값 대신 토큰 주인으로 덮어쓴다.
        activityPlanService.saveDayStores(viewerUserIdx, caller != null ? caller : createdBy, body);
        return ResponseEntity.ok(ApiResponse.success("활동 계획이 저장되었습니다.", null));
    }

    @GetMapping("/users/{userIdx}/team-view-permissions")
    public ResponseEntity<ApiResponse<List<TeamViewPermissionDto>>> teamViewPermissions(
            @PathVariable int userIdx, HttpServletRequest request) {
        ensureSelfOrPermissionAdmin(request, userIdx, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(
                ApiResponse.success(activityPlanService.listTeamViewPermissions(userIdx)));
    }

    /**
     * 내 캘린더를 누구에게 보여줄지는 나만 정할 수 있다. 검사가 없으면 아무나 자기 자신을
     * 남의 열람 허용 목록에 추가해 일정을 들여다볼 수 있었다.
     *
     * <p>단, 메뉴권한 관리(mst003) 화면에서 관리자가 다른 사원의 설정을 대신 편집하는
     * 정상 경로가 있으므로 그 권한 보유자도 허용한다.
     */
    @PutMapping("/users/{userIdx}/team-view-permissions")
    public ResponseEntity<ApiResponse<Void>> saveTeamViewPermissions(
            @PathVariable int userIdx,
            @RequestParam(required = false) String grantedBy,
            @Valid @RequestBody TeamViewPermissionSaveRequestDto body,
            HttpServletRequest request) {
        String caller = ensureSelfOrPermissionAdmin(
                request, userIdx, MenuAccessGuard.Action.UPDATE);
        activityPlanService.saveTeamViewPermissions(
                userIdx, caller != null ? caller : grantedBy, body);
        return ResponseEntity.ok(ApiResponse.success("팀 캘린더 열람 권한이 저장되었습니다.", null));
    }

    private void ensureViewer(HttpServletRequest request, int viewerUserIdx) {
        menuAccessGuard.ensureSelfUserIdx(MenuAccessGuard.callerId(request), viewerUserIdx);
    }

    /** 본인이거나 메뉴권한 관리(mst003) 권한자일 것. 호출자 ID 를 돌려준다. */
    private String ensureSelfOrPermissionAdmin(
            HttpServletRequest request, int targetUserIdx, MenuAccessGuard.Action action) {
        String caller = MenuAccessGuard.callerId(request);
        try {
            menuAccessGuard.ensureSelfUserIdx(caller, targetUserIdx);
        } catch (AccessDeniedException notSelf) {
            menuAccessGuard.ensure(caller, MenuCodes.MST003, action);
        }
        return caller;
    }
}
