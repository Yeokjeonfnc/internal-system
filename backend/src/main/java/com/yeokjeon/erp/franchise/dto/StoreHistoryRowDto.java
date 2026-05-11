package com.yeokjeon.erp.franchise.dto;

import com.fasterxml.jackson.databind.JsonNode;

import java.time.LocalDateTime;

/** {@code store_history} 목록 행 — 기존 Map 응답 키와 동일. */
public record StoreHistoryRowDto(
        Long historyIdx,
        Integer storeIdx,
        String chgType,
        String storeNm,
        JsonNode chgContent,
        String content,
        String chgUserId,
        LocalDateTime chgDt) {}
