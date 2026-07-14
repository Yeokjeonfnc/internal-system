package com.yeokjeon.erp.franchise.dto;

import com.yeokjeon.erp.franchise.entity.Store;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/** {@code store_mst} API 응답 — 기존 JSON 필드명과 동일(프론트 {@code Store} 모델 호환). */
public record StoreMstDto(
        Integer storeIdx,
        String storeCd,
        String storeNm,
        String ownerNm,
        String regionCd,
        String regionNm,
        String storeTel,
        String address,
        BigDecimal latitude,
        BigDecimal longitude,
        String storeStatus,
        String storeStatusNm,
        Boolean closedYn,
        LocalDate contEndDt,
        Boolean autoRenewalYn,
        String storeType,
        String storeTypeNm,
        String svId,
        String svNm,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        String adressDetail,
        String zipCd,
        String brandCd,
        String brandNm,
        LocalDate contStartDt,
        String businessNumber,
        LocalDate firstContDt,
        LocalDate transferDate,
        BigDecimal frFee,
        BigDecimal eduFee,
        BigDecimal insuDeposit,
        BigDecimal contDeposit,
        String contManager,
        String contManagerNm,
        String eduManager,
        String eduManagerNm,
        BigDecimal contArea,
        BigDecimal realArea,
        Integer floor,
        Integer parkingCount,
        Integer premiumFee,
        Integer monthlyRent,
        Integer rentDeposit,
        String notes,
        Integer propIdx,
        Integer partnerIdx) {

    public static StoreMstDto fromEntity(Store store) {
        return new StoreMstDto(
                store.getStoreIdx(),
                store.getStoreCd(),
                store.getStoreNm(),
                store.getOwnerNm(),
                store.getRegionCd(),
                codeName(store.getRegionCd(), store.getRegionNm()),
                store.getStoreTel(),
                store.getAddress(),
                store.getLatitude(),
                store.getLongitude(),
                store.getStoreStatus(),
                codeName(store.getStoreStatus(), store.getStoreStatusNm()),
                ynToBoolean(store.getClosedYn()),
                store.getContEndDt(),
                store.getAutoRenewalYn(),
                store.getStoreType(),
                codeName(store.getStoreType(), store.getStoreTypeNm()),
                store.getSvId(),
                store.getSvNm(),
                store.getCreatedAt(),
                store.getUpdatedAt(),
                store.getAdressDetail(),
                store.getZipCd(),
                store.getBrandCd(),
                codeName(store.getBrandCd(), store.getBrandNm()),
                store.getContStartDt(),
                store.getBusinessNumber(),
                store.getFirstContDt(),
                store.getTransferDate(),
                store.getFrFee(),
                store.getEduFee(),
                store.getInsuDeposit(),
                store.getContDeposit(),
                store.getContManager(),
                store.getContManagerNm(),
                store.getEduManager(),
                store.getEduManagerNm(),
                store.getContArea(),
                store.getRealArea(),
                store.getFloor(),
                store.getParkingCount(),
                store.getPremiumFee(),
                store.getMonthlyRent(),
                store.getRentDeposit(),
                store.getNotes(),
                store.getPropIdx(),
                store.getPartnerIdx());
    }

    private static String codeName(String code, String name) {
        return name != null ? name : code;
    }

    private static Boolean ynToBoolean(String yn) {
        return "Y".equalsIgnoreCase(yn != null ? yn.trim() : "");
    }
}
