package com.yeokjeon.erp.active.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotBlank;

/** {@code POST /checklists}·{@code PUT /checklists/{chkIdx}} 공통 요청 본문. */
@JsonIgnoreProperties(ignoreUnknown = true)
public record ChkMstWriteRequestDto(
        @NotBlank String brandCd,
        @NotBlank String chkType,
        @NotBlank String chkContent,
        Integer baseScore,
        Character useYn) {}
