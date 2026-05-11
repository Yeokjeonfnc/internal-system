package com.yeokjeon.erp.active.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * {@code chk_mst} 조회·생성·수정 응답 — 기존 Map 키와 동일.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ChkMstResponseDto(
        Integer chkIdx,
        String brandCd,
        String chkType,
        String chkTypeNm,
        String chkContent,
        Integer baseScore,
        Character useYn,
        Integer displayOrder) {}
