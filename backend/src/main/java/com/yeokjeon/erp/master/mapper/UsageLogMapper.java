package com.yeokjeon.erp.master.mapper;

import com.yeokjeon.erp.master.dto.UsageLogRowDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.util.List;

@Mapper
public interface UsageLogMapper {

    int insertLogin(
            @Param("userId") String userId,
            @Param("userNm") String userNm,
            @Param("deptNm") String deptNm,
            @Param("positionNm") String positionNm,
            @Param("svYn") String svYn);

    int insertMenu(
            @Param("userId") String userId,
            @Param("userNm") String userNm,
            @Param("deptNm") String deptNm,
            @Param("positionNm") String positionNm,
            @Param("svYn") String svYn,
            @Param("menuCd") String menuCd,
            @Param("useDetail") String useDetail);

    int insertTag(
            @Param("userId") String userId,
            @Param("userNm") String userNm,
            @Param("deptNm") String deptNm,
            @Param("positionNm") String positionNm,
            @Param("svYn") String svYn,
            @Param("menuCd") String menuCd,
            @Param("useDetail") String useDetail,
            @Param("storeIdx") Integer storeIdx,
            @Param("tagUid") String tagUid,
            @Param("tagLat") Double tagLat,
            @Param("tagLng") Double tagLng,
            @Param("distanceM") Integer distanceM);

    List<UsageLogRowDto> selectList(
            @Param("userNm") String userNm,
            @Param("useType") String useType,
            @Param("publicOnly") boolean publicOnly,
            @Param("startDt") LocalDate startDt,
            @Param("endDt") LocalDate endDt);

    List<UsageLogRowDto> selectEntryTagsForActivity(
            @Param("userId") String userId,
            @Param("storeIdx") Integer storeIdx,
            @Param("unlinkedOnly") boolean unlinkedOnly);
}
