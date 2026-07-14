package com.yeokjeon.erp.active.mapper;

import com.yeokjeon.erp.active.dto.ActNotifAckDateRow;
import com.yeokjeon.erp.active.dto.ActiveListQuery;
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

/**
 * 활동(active_mst)·체크리스트·알림(notif_mst) 조회/갱신.
 * SQL 본문은 {@code mapper/active/ActMstMapper.xml}.
 */
@Mapper
public interface ActMstMapper {

    List<ActivityStatusPivotRowDto> pivotByStore(
            @Param("startDt") LocalDate startDt,
            @Param("endDt") LocalDate endDt,
            @Param("brandCd") String brandCd);

    List<ActivityStatusPivotRowDto> pivotBySv(
            @Param("startDt") LocalDate startDt,
            @Param("endDt") LocalDate endDt,
            @Param("brandCd") String brandCd);

    int insChkDtl(
            @Param("actIdx") int actIdx,
            @Param("chkIdx") int chkIdx,
            @Param("answerVal") String answerVal,
            @Param("answerScore") int answerScore);

    int delChkDtlByAct(@Param("actIdx") int actIdx);

    List<UserIdNameRow> userNamesByIds(@Param("userIds") List<String> userIds);

    UserWriterDeptRow writerDept(@Param("userId") String userId);

    String userName(@Param("userId") String userId);

    List<ChkResultRowDto> chkResultRows(@Param("actIdx") int actIdx);

    int insChkMst(ChkMstInsertHolder holder);

    int updChkMst(
            @Param("chkIdx") int chkIdx,
            @Param("brandCd") String brandCd,
            @Param("chkType") String chkType,
            @Param("chkContent") String chkContent,
            @Param("baseScore") int baseScore,
            @Param("useYn") Character useYn);

    List<ChkMstResponseDto> chkMstList(
            @Param("brandCd") String brandCd,
            @Param("chkType") String chkType);

    ChkMstResponseDto chkMstOne(@Param("chkIdx") int chkIdx);

    int delChkDtlByChkIdx(@Param("chkIdx") int chkIdx);

    int delChkMst(@Param("chkIdx") int chkIdx);

    List<ActActive> actList(@Param("q") ActiveListQuery q);

    List<ActActive> actListApprMemo(
            @Param("userId") String userId,
            @Param("notifTyp") String notifTyp);

    List<NotifMstDto> notifList(@Param("userId") String userId);

    long notifUnreadCnt(@Param("userId") String userId);

    int notifMarkAllRead(@Param("userId") String userId);

    List<ActNotifAckDateRow> apprAckDays(
            @Param("actIdx") int actIdx,
            @Param("notifTyp") String notifTyp,
            @Param("onlyApprY") boolean onlyApprY);

    int apprNotifCnt(
            @Param("actIdx") int actIdx,
            @Param("userId") String userId,
            @Param("notifTyp") String notifTyp);

    int apprNotifPendingCnt(
            @Param("actIdx") int actIdx,
            @Param("userId") String userId,
            @Param("notifTyp") String notifTyp);

    int apprNotifSetYn(
            @Param("userId") String userId,
            @Param("actIdx") int actIdx,
            @Param("notifTyp") String notifTyp,
            @Param("apprYn") String apprYn);

    int apprCsvAckCnt(
            @Param("actIdx") int actIdx,
            @Param("notifTyp") String notifTyp,
            @Param("peerIds") List<String> peerIds);
}
