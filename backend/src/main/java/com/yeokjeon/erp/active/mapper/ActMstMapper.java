package com.yeokjeon.erp.active.mapper;

import com.yeokjeon.erp.active.dto.ActNotifAckDateRow;
import com.yeokjeon.erp.active.dto.ActivityStatusPivotRowDto;
import com.yeokjeon.erp.active.dto.ChkMstInsertHolder;
import com.yeokjeon.erp.active.dto.ChkMstResponseDto;
import com.yeokjeon.erp.active.dto.ChkResultRowDto;
import com.yeokjeon.erp.active.dto.NotifMstDto;
import com.yeokjeon.erp.active.dto.UserIdNameRow;
import com.yeokjeon.erp.active.dto.UserWriterDeptRow;
import com.yeokjeon.erp.active.entity.ActActive;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.util.List;

@Mapper
public interface ActMstMapper {

    List<ActivityStatusPivotRowDto> selectStatusByStore(
            @Param("startDt") LocalDate startDt,
            @Param("endDt") LocalDate endDt,
            @Param("brandCd") String brandCd);

    List<ActivityStatusPivotRowDto> selectStatusBySv(
            @Param("startDt") LocalDate startDt,
            @Param("endDt") LocalDate endDt,
            @Param("brandCd") String brandCd);

    int insertChkResultDtl(
            @Param("actIdx") int actIdx,
            @Param("chkIdx") int chkIdx,
            @Param("answerVal") String answerVal,
            @Param("answerScore") int answerScore);

    int deleteChkResultDtlByActIdx(@Param("actIdx") int actIdx);

    List<UserIdNameRow> selectUserNamesByIds(@Param("userIds") List<String> userIds);

    UserWriterDeptRow selectWriterAndDept(@Param("userId") String userId);

    String selectUserName(@Param("userId") String userId);

    List<ChkResultRowDto> selectChkResultsForActivity(@Param("actIdx") int actIdx);

    int insertChkMst(ChkMstInsertHolder holder);

    int updateChkMst(
            @Param("chkIdx") int chkIdx,
            @Param("brandCd") String brandCd,
            @Param("chkType") String chkType,
            @Param("chkContent") String chkContent,
            @Param("baseScore") int baseScore,
            @Param("useYn") Character useYn);

    List<ChkMstResponseDto> selectChkMstList(
            @Param("brandCd") String brandCd,
            @Param("chkType") String chkType);

    ChkMstResponseDto selectChkMstOne(@Param("chkIdx") int chkIdx);

    List<ActActive> selectAllActivities();

    List<ActActive> selectActivitiesByApprStatus(@Param("apprStatus") String apprStatus);

    List<ActActive> selectActivitiesByStoreIdx(@Param("storeIdx") int storeIdx);

    List<ActActive> selectActivitiesByChkYn(@Param("chkYn") Character chkYn);

    List<ActActive> selectActivitiesBySvForApprNotes(@Param("svId") String svId);

    List<NotifMstDto> selectNotifsForUser(@Param("userId") String userId);

    long countUnreadNotifsForUser(@Param("userId") String userId);

    List<ActNotifAckDateRow> selectApprovalAckDateRows(
            @Param("actIdx") int actIdx,
            @Param("notifTyp") String notifTyp,
            @Param("onlyApprY") boolean onlyApprY);

    int updateApprYnForUserActivityNotifs(
            @Param("userId") String userId,
            @Param("actIdx") int actIdx,
            @Param("notifTyp") String notifTyp,
            @Param("apprYn") String apprYn);
}
