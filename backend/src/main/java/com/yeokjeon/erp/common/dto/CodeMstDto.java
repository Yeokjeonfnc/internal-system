package com.yeokjeon.erp.common.dto;

/**
 * {@code code_mst} 조회 행 — API JSON 키는 {@code codeCd}/{@code codeNm} (프론트 {@code CodeOption}과 동일).
 */
public record CodeMstDto(String codeCd, String codeNm) {}
