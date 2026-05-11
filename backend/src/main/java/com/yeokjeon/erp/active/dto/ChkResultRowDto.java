package com.yeokjeon.erp.active.dto;

/** 체크리스트 결과 조회 행 — 기존 {@code chkResults} Map 키와 동일. */
public record ChkResultRowDto(
        Integer chkIdx,
        String brandCd,
        String chkType,
        String chkTypeNm,
        String chkContent,
        Integer baseScore,
        Integer displayOrder,
        String answerVal,
        Integer answerScore) {}
