package com.yeokjeon.erp.development.dto;

import java.util.Map;

/**
 * 영업지역 생성·수정.
 * <ul>
 *   <li>물건 연결: {@code propIdx} — {@code property_mst.zone_idx = sale_zone_mst.zone_idx}, {@code use_yn=true}</li>
 *   <li>전략출점: {@code propIdx} 없음 — {@code use_yn=false}</li>
 *   <li>가맹점: {@code store_mst.prop_idx} → {@code property_mst}</li>
 * </ul>
 */
public record SalesAreaSaveRequest(
        Integer zoneIdx,
        Integer propIdx,
        Integer storeIdx,
        String zoneNm,
        String geometryType,
        Map<String, Object> geometryData,
        String brandCd,
        java.math.BigDecimal latitude,
        java.math.BigDecimal longitude) {}
