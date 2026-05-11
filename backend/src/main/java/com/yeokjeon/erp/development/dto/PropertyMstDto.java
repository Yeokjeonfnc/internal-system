package com.yeokjeon.erp.development.dto;

import com.yeokjeon.erp.development.entity.Property;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * {@code property_mst} API 응답 — 필드명은 기존 {@code Map} 응답과 동일(프론트 물건 모델 JSON 호환).
 */
public record PropertyMstDto(
        Integer propIdx,
        String propNm,
        String zipCd,
        String address,
        String addressDetail,
        BigDecimal latitude,
        BigDecimal longitude,
        String region,
        String propStatus,
        String propType,
        Integer floor,
        BigDecimal contArea,
        BigDecimal realArea,
        Long rentDeposit,
        Long monthlyRent,
        Long premiumFee,
        Long maintFee,
        String propNotes,
        LocalDate surveyDt,
        LocalDateTime createDt,
        LocalDateTime updateDt,
        String surveyor) {

    public static PropertyMstDto fromEntity(Property p) {
        return new PropertyMstDto(
                p.getPropIdx(),
                p.getPropNm(),
                p.getZipCd(),
                p.getAddress(),
                p.getAddressDetail(),
                p.getLatitude(),
                p.getLongitude(),
                p.getRegion(),
                p.getPropStatus(),
                p.getPropType(),
                p.getFloor(),
                p.getContArea(),
                p.getRealArea(),
                p.getRentDeposit(),
                p.getMonthlyRent(),
                p.getPremiumFee(),
                p.getMaintFee(),
                p.getPropNotes(),
                p.getSurveyDt(),
                p.getCreateDt(),
                p.getUpdateDt(),
                p.getSurveyor());
    }
}
