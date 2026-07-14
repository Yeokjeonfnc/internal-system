package com.yeokjeon.erp.franchise.mapper;

import com.yeokjeon.erp.franchise.dto.StoreHistoryJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface StoreHistoryMapper {

    List<StoreHistoryJdbcRow> selectHistoriesByStoreIdx(@Param("storeIdx") int storeIdx);

    int insertHistorySimple(
            @Param("storeIdx") Integer storeIdx,
            @Param("chgType") String chgType,
            @Param("chgUserId") String chgUserId,
            @Param("storeNm") String storeNm,
            @Param("summaryContent") String summaryContent);

    int insertHistoryActive(
            @Param("storeIdx") Integer storeIdx,
            @Param("chgType") String chgType,
            @Param("chgUserId") String chgUserId,
            @Param("storeNm") String storeNm,
            @Param("summaryText") String summaryText,
            @Param("chgDt") LocalDateTime chgDt);

    int insertHistoryUpdateJson(
            @Param("storeIdx") Integer storeIdx,
            @Param("storeNm") String storeNm,
            @Param("jsonBody") String jsonBody);

    void dropStoreHistoryFkIfExists();
}
