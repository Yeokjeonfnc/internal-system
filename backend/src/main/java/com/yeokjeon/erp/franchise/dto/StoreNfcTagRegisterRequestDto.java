package com.yeokjeon.erp.franchise.dto;

import jakarta.validation.constraints.NotBlank;

public record StoreNfcTagRegisterRequestDto(
        @NotBlank String tagUid, String registeredBy) {}
