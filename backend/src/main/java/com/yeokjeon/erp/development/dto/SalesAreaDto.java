package com.yeokjeon.erp.development.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.yeokjeon.erp.development.util.GeometryJson;
import java.math.BigDecimal;
import java.util.Map;

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
        String zoneInfo,
        Boolean isAreaConfigured,
        Boolean isStrategicOpening,
        Boolean isFranchise,
        String mapAddress,
        BigDecimal latitude,
        BigDecimal longitude,
        String geometryType,
        String geometryDataJson,
        Integer propIdx) {

    @JsonProperty("geometryData")
    public Map<String, Object> geometryData() {
        return GeometryJson.toMapLenient(geometryDataJson);
    }
}
