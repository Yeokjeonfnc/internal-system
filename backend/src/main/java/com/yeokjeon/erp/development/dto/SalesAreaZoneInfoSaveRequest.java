package com.yeokjeon.erp.development.dto;

/** 영업지역 비고(zone_info) 저장. */
public record SalesAreaZoneInfoSaveRequest(
        Integer zoneIdx,
        Integer propIdx,
        Integer storeIdx,
        String zoneInfo) {}
