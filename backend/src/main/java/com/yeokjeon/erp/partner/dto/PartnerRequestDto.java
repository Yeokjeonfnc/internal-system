package com.yeokjeon.erp.partner.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.yeokjeon.erp.partner.entity.Partner;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PartnerRequestDto {

    @NotBlank(message = "예비창업자 성명은 필수입니다")
    private String partnerNm;

    private String partnerStatus;

    @NotBlank(message = "휴대전화번호는 필수입니다")
    private String partnerTel;

    private String partnerEmail;
    private String gender;
    private LocalDate partnerBirth;

    @JsonProperty("pZipCd")
    private String pZipCd;

    @JsonProperty("pAddress")
    private String pAddress;

    @JsonProperty("pAddressDetail")
    private String pAddressDetail;

    @JsonProperty("pRegion")
    private String pRegion;

    public Partner toEntity() {
        return Partner.builder()
                .partnerNm(partnerNm)
                .partnerStatus(partnerStatus)
                .partnerTel(partnerTel)
                .partnerEmail(partnerEmail)
                .gender(gender)
                .partnerBirth(partnerBirth)
                .pZipCd(pZipCd)
                .pAddress(pAddress)
                .pAddressDetail(pAddressDetail)
                .pRegion(pRegion)
                .build();
    }
}
