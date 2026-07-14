package com.yeokjeon.erp.development.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.yeokjeon.erp.development.util.GeometryJson;
import java.math.BigDecimal;
import java.util.Map;

/** 영업지역 검색 지도용 — 가맹점 좌표 + 영역 geometry. */
public record SalesAreaMapPointDto(
        Integer zoneIdx,
        Integer storeIdx,
        String storeNm,
        String zoneNm,
        BigDecimal lat,
        BigDecimal lng,
        String regionCd,
        String brandCd,
        String geometryType,
        @JsonIgnore String geometryDataJson) {

    @JsonProperty("geometryData")
    public Map<String, Object> geometryData() {
        return GeometryJson.toMapLenient(geometryDataJson);
    }
}
