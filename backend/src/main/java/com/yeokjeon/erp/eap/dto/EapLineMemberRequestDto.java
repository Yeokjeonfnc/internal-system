package com.yeokjeon.erp.eap.dto;

import jakarta.validation.constraints.Size;

public record EapLineMemberRequestDto(
        @Size(max = 16) String roleCd,
        Integer sortOrder,
        @Size(max = 64) String userId,
        @Size(max = 100) String userNm,
        @Size(max = 64) String titleNm) {
}
