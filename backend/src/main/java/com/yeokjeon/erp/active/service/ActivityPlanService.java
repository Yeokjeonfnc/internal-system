package com.yeokjeon.erp.active.service;

import com.yeokjeon.erp.active.dto.ActivityPlanCalendarContextDto;
import com.yeokjeon.erp.active.dto.ActivityPlanCalendarMemberDto;
import com.yeokjeon.erp.active.dto.ActivityPlanCalendarTeamDto;
import com.yeokjeon.erp.active.dto.ActivityPlanDayDetailDto;
import com.yeokjeon.erp.active.dto.ActivityPlanDaySaveRequestDto;
import com.yeokjeon.erp.active.dto.ActivityPlanMonthDayDto;
import com.yeokjeon.erp.active.dto.ActivityPlanMonthResponseDto;
import com.yeokjeon.erp.active.dto.ActivityPlanStoreItemDto;
import com.yeokjeon.erp.active.dto.ActivityPlanStoreRowDto;
import com.yeokjeon.erp.active.dto.TeamViewPermissionDto;
import com.yeokjeon.erp.active.dto.TeamViewPermissionItemDto;
import com.yeokjeon.erp.active.dto.TeamViewPermissionSaveRequestDto;
import com.yeokjeon.erp.active.mapper.ActivityPlanMapper;
import com.yeokjeon.erp.active.mapper.TeamViewPermissionMapper;
import com.yeokjeon.erp.master.repository.MstUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ActivityPlanService {

    private final ActivityPlanMapper activityPlanMapper;
    private final TeamViewPermissionMapper teamViewPermissionMapper;
    private final MstUserRepository mstUserRepository;

    public ActivityPlanCalendarContextDto calendarContext(int viewerUserIdx) {
        ensureUserExists(viewerUserIdx);
        var viewer = mstUserRepository.findById(viewerUserIdx).orElseThrow();
        Integer deptIdx = activityPlanMapper.selectUserDeptIdx(viewerUserIdx);
        String deptNm = deptIdx != null ? activityPlanMapper.selectDeptNm(deptIdx) : null;
        List<ActivityPlanCalendarTeamDto> teams =
                activityPlanMapper.selectGrantedTeams(viewerUserIdx);
        List<ActivityPlanCalendarMemberDto> members =
                activityPlanMapper.selectMembersForViewer(viewerUserIdx);
        return new ActivityPlanCalendarContextDto(
                viewerUserIdx,
                viewer.getUserName(),
                deptIdx,
                deptNm,
                teams,
                members);
    }

    public ActivityPlanMonthResponseDto monthPlans(
            int viewerUserIdx, int year, int month, List<Integer> assigneeUserIdxs) {
        ensureUserExists(viewerUserIdx);
        if (assigneeUserIdxs != null && assigneeUserIdxs.isEmpty()) {
            return new ActivityPlanMonthResponseDto(List.of());
        }
        YearMonth ym = YearMonth.of(year, month);
        LocalDate monthStart = ym.atDay(1);
        LocalDate monthEnd = ym.plusMonths(1).atDay(1);

        List<ActivityPlanStoreRowDto> planned = activityPlanMapper.selectPlannedStoresInMonth(
                viewerUserIdx, monthStart, monthEnd, assigneeUserIdxs);
        List<ActivityPlanStoreRowDto> completed =
                activityPlanMapper.selectCompletedVisitsInMonth(
                        viewerUserIdx, monthStart, monthEnd, assigneeUserIdxs);

        Map<LocalDate, Map<String, ActivityPlanStoreItemDto>> byDay = new LinkedHashMap<>();
        mergeMonthRow(byDay, planned);
        mergeMonthRow(byDay, completed);

        List<ActivityPlanMonthDayDto> days = byDay.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(e -> new ActivityPlanMonthDayDto(
                        e.getKey(),
                        e.getValue().values().stream()
                                .sorted(Comparator.comparing(ActivityPlanStoreItemDto::storeLabel))
                                .toList()))
                .toList();
        return new ActivityPlanMonthResponseDto(days);
    }

    public ActivityPlanDayDetailDto dayDetail(
            int viewerUserIdx, int assigneeUserIdx, LocalDate planDate) {
        ensureUserExists(viewerUserIdx);
        ensureCanView(viewerUserIdx, assigneeUserIdx);
        if (planDate == null) {
            throw new IllegalArgumentException("날짜는 필수입니다.");
        }

        String assigneeName =
                Objects.requireNonNullElse(activityPlanMapper.selectUserName(assigneeUserIdx), "");
        boolean canEdit = viewerUserIdx == assigneeUserIdx;

        List<ActivityPlanStoreItemDto> planned = activityPlanMapper
                .selectPlannedStoresOnDay(assigneeUserIdx, planDate)
                .stream()
                .map(this::toItem)
                .toList();
        List<ActivityPlanStoreItemDto> completed = activityPlanMapper
                .selectCompletedVisitsOnDay(assigneeUserIdx, planDate)
                .stream()
                .map(this::toItem)
                .toList();

        return new ActivityPlanDayDetailDto(
                planDate, assigneeUserIdx, assigneeName, canEdit, planned, completed);
    }

    @Transactional
    public void saveDayStores(
            int viewerUserIdx, String createdBy, ActivityPlanDaySaveRequestDto body) {
        ensureUserExists(viewerUserIdx);
        if (body == null || body.planDate() == null) {
            throw new IllegalArgumentException("날짜는 필수입니다.");
        }
        activityPlanMapper.deletePlannedStoresOnDay(viewerUserIdx, body.planDate());
        List<Integer> storeIdxs = body.storeIdxs() == null ? List.of() : body.storeIdxs();
        int order = 0;
        for (Integer storeIdx : storeIdxs) {
            if (storeIdx == null || storeIdx <= 0) {
                continue;
            }
            activityPlanMapper.insertPlannedStore(
                    viewerUserIdx, body.planDate(), storeIdx, order++, createdBy);
        }
    }

    public List<TeamViewPermissionDto> listTeamViewPermissions(int viewerUserIdx) {
        ensureUserExists(viewerUserIdx);
        return teamViewPermissionMapper.selectByViewerUserIdx(viewerUserIdx);
    }

    @Transactional
    public void saveTeamViewPermissions(
            int viewerUserIdx, String grantedBy, TeamViewPermissionSaveRequestDto body) {
        ensureUserExists(viewerUserIdx);
        teamViewPermissionMapper.deleteByViewerUserIdx(viewerUserIdx);
        if (body.items() == null || body.items().isEmpty()) {
            return;
        }
        List<TeamViewPermissionItemDto> enabled = body.items().stream()
                .filter(TeamViewPermissionItemDto::canView)
                .toList();
        if (enabled.isEmpty()) {
            return;
        }
        teamViewPermissionMapper.insertBatch(viewerUserIdx, grantedBy, enabled);
    }

    private void mergeMonthRow(
            Map<LocalDate, Map<String, ActivityPlanStoreItemDto>> byDay,
            List<ActivityPlanStoreRowDto> rows) {
        for (ActivityPlanStoreRowDto row : rows) {
            if (row.planDate() == null) {
                continue;
            }
            String key = row.assigneeUserIdx() + ":" + row.storeIdx();
            Map<String, ActivityPlanStoreItemDto> dayMap =
                    byDay.computeIfAbsent(row.planDate(), k -> new LinkedHashMap<>());
            ActivityPlanStoreItemDto existing = dayMap.get(key);
            ActivityPlanStoreItemDto next = toItem(row);
            if (existing == null) {
                dayMap.put(key, next);
                continue;
            }
            dayMap.put(
                    key,
                    new ActivityPlanStoreItemDto(
                            existing.storeIdx(),
                            existing.storeLabel(),
                            existing.assigneeUserIdx(),
                            existing.assigneeUserName(),
                            existing.planned() || next.planned(),
                            existing.completed() || next.completed()));
        }
    }

    private ActivityPlanStoreItemDto toItem(ActivityPlanStoreRowDto row) {
        return new ActivityPlanStoreItemDto(
                row.storeIdx(),
                formatStoreLabel(row.brandNm(), row.storeNm()),
                row.assigneeUserIdx(),
                row.assigneeUserName(),
                row.planned(),
                row.completed());
    }

    private String formatStoreLabel(String brandNm, String storeNm) {
        String brand = brandNm == null ? "" : brandNm.trim();
        String name = storeNm == null ? "" : storeNm.trim();
        if (brand.isEmpty()) {
            return name;
        }
        if (name.isEmpty()) {
            return brand;
        }
        return brand + " · " + name;
    }

    private void ensureCanView(int viewerUserIdx, int assigneeUserIdx) {
        if (!activityPlanMapper.canViewerSeeAssignee(viewerUserIdx, assigneeUserIdx)) {
            throw new IllegalArgumentException("해당 담당자의 활동 계획을 조회할 권한이 없습니다.");
        }
    }

    private void ensureUserExists(int userIdx) {
        mstUserRepository.findById(userIdx)
                .orElseThrow(() -> new com.yeokjeon.erp.exception.ResourceNotFoundException(
                        "사용자", "userIdx", userIdx));
    }
}
