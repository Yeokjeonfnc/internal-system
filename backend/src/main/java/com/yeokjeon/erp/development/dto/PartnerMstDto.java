package com.yeokjeon.erp.development.dto;

import com.yeokjeon.erp.development.entity.Partner;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * {@code partner_mst} API 응답 — 필드명은 기존 {@code Map} 응답과 동일(프론트 {@code Partner} JSON 호환).
 */
public record PartnerMstDto(
        Integer partnerIdx,
        String partnerNm,
        String partnerStatus,
        String partnerTel,
        String partnerEmail,
        String gender,
        LocalDateTime createDt,
        LocalDateTime updateDt,
        LocalDate partnerBirth,
        String pZipCd,
        String pAddress,
        String pAddressDetail,
        String pRegion) {

    public static PartnerMstDto fromEntity(Partner p) {
        return new PartnerMstDto(
                p.getPartnerIdx(),
                p.getPartnerNm(),
                p.getPartnerStatus(),
                p.getPartnerTel(),
                p.getPartnerEmail(),
                p.getGender(),
                p.getCreateDt(),
                p.getUpdateDt(),
                p.getPartnerBirth(),
                p.getPZipCd(),
                p.getPAddress(),
                p.getPAddressDetail(),
                p.getPRegion());
    }
}
