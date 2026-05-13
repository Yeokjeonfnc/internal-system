package com.yeokjeon.erp.development.mapper;

import com.yeokjeon.erp.development.dto.PartnerMstDto;
import com.yeokjeon.erp.development.dto.PropertyMstDto;
import com.yeokjeon.erp.development.dto.SalesAreaDto;
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

    int checkSurveyor(String surveyor);
    int checkDuplicateProperty(String propNm, String address);
    int checkDuplicateProperty2(String propNm, String address, Integer propIdx);

    /** `partner_mst.partner_status` 만 갱신 (가맹점 등록 연동 등). */
    int updatePartnerStatus(
            @Param("partnerIdx") Integer partnerIdx);

    int updatePropertyStatus(
            @Param("propIdx") Integer propIdx);
}
