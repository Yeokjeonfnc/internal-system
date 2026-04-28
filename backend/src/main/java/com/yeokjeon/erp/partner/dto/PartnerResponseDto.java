package com.yeokjeon.erp.partner.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.LocalDate;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PartnerResponseDto {
    private Integer partnerIdx;
    private String partnerNm;
    private String partnerStatus;
    private String partnerTel;
    private String partnerEmail;
    private String gender;
    private LocalDateTime createDt;
    private LocalDateTime updateDt;
    private LocalDate partnerBirth;

    @JsonProperty("pZipCd")
    private String pZipCd;

    @JsonProperty("pAddress")
    private String pAddress;

    @JsonProperty("pAddressDetail")
    private String pAddressDetail;

    @JsonProperty("pRegion")
    private String pRegion;
}
