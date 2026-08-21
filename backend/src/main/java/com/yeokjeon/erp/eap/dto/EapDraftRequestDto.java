package com.yeokjeon.erp.eap.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

public record EapDraftRequestDto(
        @NotBlank @Size(max = 64) String formCode,
        @Size(max = 32) String erpMenuId,
        @Size(max = 64) String erpSourceId,
        @NotBlank @Size(max = 500) String title,
        @Size(max = 64) String draftUserId,
        String contentHtml,
        /** 작성중(WRITING) 문서 수정·재기안 시 기존 매핑 id */
        Long mappingId,
        /** WRITING / TEMPSAVE / DRAFT / INPROGRESS */
        @Size(max = 16) String status,
        @Valid List<EapLineMemberRequestDto> lines) {
}
