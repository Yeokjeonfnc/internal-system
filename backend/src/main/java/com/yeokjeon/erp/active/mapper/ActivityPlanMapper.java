package com.yeokjeon.erp.active.mapper;

import com.yeokjeon.erp.active.dto.ActivityPlanCalendarMemberDto;
import com.yeokjeon.erp.active.dto.ActivityPlanCalendarTeamDto;
import com.yeokjeon.erp.active.dto.ActivityPlanStoreRowDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.util.List;

@Mapper
public interface ActivityPlanMapper {

    Integer selectUserDeptIdx(@Param("userIdx") int userIdx);

    String selectDeptNm(@Param("deptIdx") int deptIdx);

    List<Integer> selectGrantedDeptIdxByViewer(@Param("viewerUserIdx") int viewerUserIdx);

    List<ActivityPlanCalendarTeamDto> selectGrantedTeams(@Param("viewerUserIdx") int viewerUserIdx);

    List<ActivityPlanCalendarMemberDto> selectMembersForViewer(@Param("viewerUserIdx") int viewerUserIdx);

    boolean canViewerSeeAssignee(
            @Param("viewerUserIdx") int viewerUserIdx,
            @Param("assigneeUserIdx") int assigneeUserIdx);

    String selectUserId(@Param("userIdx") int userIdx);

    String selectUserName(@Param("userIdx") int userIdx);

    List<ActivityPlanStoreRowDto> selectPlannedStoresInMonth(
            @Param("viewerUserIdx") int viewerUserIdx,
            @Param("monthStart") LocalDate monthStart,
            @Param("monthEnd") LocalDate monthEnd,
            @Param("assigneeUserIdxs") List<Integer> assigneeUserIdxs);

    List<ActivityPlanStoreRowDto> selectCompletedVisitsInMonth(
            @Param("viewerUserIdx") int viewerUserIdx,
            @Param("monthStart") LocalDate monthStart,
            @Param("monthEnd") LocalDate monthEnd,
            @Param("assigneeUserIdxs") List<Integer> assigneeUserIdxs);

    List<ActivityPlanStoreRowDto> selectPlannedStoresOnDay(
            @Param("assigneeUserIdx") int assigneeUserIdx,
            @Param("planDate") LocalDate planDate);

    List<ActivityPlanStoreRowDto> selectCompletedVisitsOnDay(
            @Param("assigneeUserIdx") int assigneeUserIdx,
            @Param("planDate") LocalDate planDate);

    int deletePlannedStoresOnDay(
            @Param("assigneeUserIdx") int assigneeUserIdx,
            @Param("planDate") LocalDate planDate);

    int insertPlannedStore(
            @Param("assigneeUserIdx") int assigneeUserIdx,
            @Param("planDate") LocalDate planDate,
            @Param("storeIdx") int storeIdx,
            @Param("sortOrder") int sortOrder,
            @Param("createdBy") String createdBy);
}
