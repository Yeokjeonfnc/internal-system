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
        String surveyor,
        Integer parkingCount) {

    /**
     * 주차가능대수({@code parking_count})를 뺀 생성자.
     *
     * <p>{@code parking_count} 는 선택 컬럼이라 아직 적용되지 않은 DB 가 있다. 목록 조회
     * (MyBatis {@code propertyMstDto} resultMap)와 JPA 엔티티 변환은 이 컬럼을 건드리지
     * 않고 이 생성자만 쓴다 — 컬럼이 없는 DB 에서도 물건 목록·상세가 그대로 뜬다.
     * 값은 {@link #withParkingCount(Integer)} 로 나중에 얹는다.
     */
    public PropertyMstDto(
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
        this(
                propIdx,
                propNm,
                zipCd,
                address,
                addressDetail,
                latitude,
                longitude,
                region,
                propStatus,
                propType,
                floor,
                contArea,
                realArea,
                rentDeposit,
                monthlyRent,
                premiumFee,
                maintFee,
                propNotes,
                surveyDt,
                createDt,
                updateDt,
                surveyor,
                null);
    }

    /** 주차가능대수만 갈아 끼운 복사본. */
    public PropertyMstDto withParkingCount(Integer parkingCount) {
        return new PropertyMstDto(
                propIdx,
                propNm,
                zipCd,
                address,
                addressDetail,
                latitude,
                longitude,
                region,
                propStatus,
                propType,
                floor,
                contArea,
                realArea,
                rentDeposit,
                monthlyRent,
                premiumFee,
                maintFee,
                propNotes,
                surveyDt,
                createDt,
                updateDt,
                surveyor,
                parkingCount);
    }

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
