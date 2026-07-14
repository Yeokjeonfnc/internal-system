package com.yeokjeon.erp.master.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/** {@code POST /owner-users} 요청 본문. */
@JsonIgnoreProperties(ignoreUnknown = true)
public record OwnerUserMstCreateRequestDto(
        @NotBlank String userName,
        @NotBlank String userPassword,
        @NotBlank String userId,
        String userPhone,
        String userEmail,
        @NotNull Integer storeIdx) {}
