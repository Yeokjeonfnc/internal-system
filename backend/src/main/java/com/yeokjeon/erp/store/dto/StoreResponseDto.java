package com.yeokjeon.erp.store.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StoreResponseDto {
    
    private String storeCd;
    private Integer storeIdx;
    private String storeNm;
    private String ownerNm;
    private String regionCd;
    private String regionNm;
    private String storeTel;
    private String address;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String storeStatus;
    private String storeStatusNm;
    private LocalDate contEndDt;
    private Boolean autoRenewalYn;
    private String storeType;
    private String storeTypeNm;
    private String svId;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String adressDetail;
    private String zipCd;
    private String brandCd;
    private String brandNm;
    private LocalDate contStartDt;
    private String businessNumber;
    private LocalDate firstContDt;
    private BigDecimal frFee;
    private BigDecimal eduFee;
    private BigDecimal insuDeposit;
    private BigDecimal contDeposit;
    private String contManager;
    private String eduManager;
    private BigDecimal contArea;
    private BigDecimal realArea;
    private Integer floor;
    private Integer parkingCount;
    private Integer premiumFee;
    private Integer monthlyRent;
    private Integer rentDeposit;
}   
