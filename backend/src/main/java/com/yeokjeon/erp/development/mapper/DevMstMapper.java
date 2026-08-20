package com.yeokjeon.erp.development.mapper;

import com.yeokjeon.erp.development.dto.PartnerMstDto;
import com.yeokjeon.erp.development.dto.PropertyMstDto;
import com.yeokjeon.erp.development.dto.SalesAreaDto;
import com.yeokjeon.erp.development.dto.SalesAreaMapPointDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface DevMstMapper {

    List<PartnerMstDto> selectPartnersOrdered();

    List<PropertyMstDto> selectPropertiesOrdered();

    List<SalesAreaDto> selectSalesAreasForList();

    /** [sale_zone_mst] 없거나 전체조인 실패 시 — [store_mst]만 조회. */
    List<SalesAreaDto> selectSalesAreasStoresOnly();

    List<SalesAreaMapPointDto> selectSalesAreaMapPoints();

    List<SalesAreaMapPointDto> selectSalesAreaMapPointsWithGeometry();

    SalesAreaDto selectSalesAreaDetailByStoreIdx(@Param("storeIdx") Integer storeIdx);

    SalesAreaDto selectSalesAreaDetailByZoneIdx(@Param("zoneIdx") Integer zoneIdx);

    SalesAreaDto selectSalesAreaDetailByPropIdx(@Param("propIdx") Integer propIdx);

    int insertSaleZone(java.util.Map<String, Object> params);

    int updateSaleZone(
            @Param("zoneIdx") Integer zoneIdx,
            @Param("zoneNm") String zoneNm,
            @Param("brandCd") String brandCd,
            @Param("geometryType") String geometryType,
            @Param("geometryDataJson") String geometryDataJson);

    int updateSaleZoneUseYn(
            @Param("zoneIdx") Integer zoneIdx, @Param("useYn") Boolean useYn);

    int updateSaleZoneInfo(
            @Param("zoneIdx") Integer zoneIdx, @Param("zoneInfo") String zoneInfo);

    Integer selectStoreIdxByPropIdx(@Param("propIdx") Integer propIdx);

    Integer selectZoneIdxByPropIdx(@Param("propIdx") Integer propIdx);

    Integer selectZoneIdxByStoreIdx(@Param("storeIdx") Integer storeIdx);

    int updatePropertyZoneIdx(
            @Param("propIdx") Integer propIdx, @Param("zoneIdx") Integer zoneIdx);

    int updatePropertyCoordinates(
            @Param("propIdx") Integer propIdx,
            @Param("latitude") java.math.BigDecimal latitude,
            @Param("longitude") java.math.BigDecimal longitude);

    int updateStoreCoordinates(
            @Param("storeIdx") Integer storeIdx,
            @Param("latitude") java.math.BigDecimal latitude,
            @Param("longitude") java.math.BigDecimal longitude);

    /** 물건 좌표 변경 시 `store_mst.prop_idx` 로 연결된 가맹점 좌표 동기화. */
    int updateStoreCoordinatesByPropIdx(
            @Param("propIdx") Integer propIdx,
            @Param("latitude") java.math.BigDecimal latitude,
            @Param("longitude") java.math.BigDecimal longitude);

    int clearPropertyZoneFromOtherProperties(
            @Param("zoneIdx") Integer zoneIdx, @Param("propIdx") Integer propIdx);

    /*
     * 주차가능대수(property_mst.parking_count) — 선택 컬럼.
     *
     * JPA 엔티티(Property)·목록 조회(selectPropertiesOrdered)에는 넣지 않는다.
     * 넣으면 컬럼이 아직 없는 DB 에서 물건 조회·저장이 통째로 500 이 되기 때문이다.
     * 대신 아래 3개로만 다루고, 호출 전에 countPropertyParkingCountColumn 으로 존재를
     * 먼저 확인한다(실패 쿼리를 날리면 같은 트랜잭션의 저장까지 롤백된다).
     */
    int countPropertyParkingCountColumn();

    Integer selectPropertyParkingCount(@Param("propIdx") Integer propIdx);

    int updatePropertyParkingCount(
            @Param("propIdx") Integer propIdx, @Param("parkingCount") Integer parkingCount);

    int checkSurveyor(String surveyor);

    int checkDuplicateProperty(String propNm, String address);

    int checkDuplicateProperty2(String propNm, String address, Integer propIdx);

    int updatePartnerStatus(@Param("partnerIdx") Integer partnerIdx);

    int updatePropertyStatus(@Param("propIdx") Integer propIdx);
}
