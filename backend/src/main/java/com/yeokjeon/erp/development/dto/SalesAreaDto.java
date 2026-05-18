package com.yeokjeon.erp.development.dto;

/**
 * 영업지역(DEV003) 목록 행 — {@code sale_zone_mst} 기준 {@code FULL OUTER JOIN store_mst},
 * {@code property_mst}·{@code code_mst} 조회.
 */
public record SalesAreaDto(
        Integer zoneIdx,
        Integer storeIdx,
        String settingDateYmd,
        String storeNm,
        String franchiseLabel,
        String brandCd,
        String brandNm,
        String regionCd,
        String regionNm,
        String propNm,
        String areaSettingLabel,
        String salesAreaName,
        Boolean isAreaConfigured,
        Boolean isStrategicOpening,
        Boolean isFranchise,
        String mapAddress,
        java.math.BigDecimal latitude,
        java.math.BigDecimal longitude) {}
