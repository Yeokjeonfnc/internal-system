package com.yeokjeon.erp.active.dto;

/**
 * 활동 저장 시 요청 본문의 {@code checklistResults[]} 한 행 — {@code chk_result_dtl} 반영용.
 * (컨트롤러는 기존과 같이 {@code Map} 본문; 서비스에서만 타입화.)
 */
public record ChkResultDtlSaveDto(Integer chkIdx, String answerVal, Integer answerScore) {}
