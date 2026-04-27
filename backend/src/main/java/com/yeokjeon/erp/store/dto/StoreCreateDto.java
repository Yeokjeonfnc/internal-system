package com.yeokjeon.erp.store.dto;

import com.yeokjeon.erp.store.entity.Store;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StoreCreateDto {
    
    @NotBlank(message = "가맹점 코드는 필수입니다")
    private String storeCd;
    
    @NotBlank(message = "가맹점명은 필수입니다")
    private String storeNm;
    
    private String ownerNm;
    private String regionCd;
    private String storeTel;
    private String address;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String storeStatus;
    private LocalDate contEndDt;
    private Boolean autoRenewalYn;
    private String storeType;
    private String svId;
    private String adressDetail;
    private String zipCd;
    private String brandCd;
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

    public Store toEntity() {
        return Store.builder()
                .storeCd(storeCd)
                .storeNm(storeNm)
                .ownerNm(ownerNm)
                .regionCd(regionCd)
                .storeTel(storeTel)
                .address(address)
                .latitude(latitude)
                .longitude(longitude)
                .storeStatus(storeStatus)
                .contEndDt(contEndDt)
                .autoRenewalYn(autoRenewalYn != null ? autoRenewalYn : true)
                .storeType(storeType)
                .svId(svId)
                .adressDetail(adressDetail)
                .zipCd(zipCd)
                .brandCd(brandCd)
                .contStartDt(contStartDt)
                .businessNumber(businessNumber)
                .firstContDt(firstContDt)
                .frFee(frFee)
                .eduFee(eduFee)
                .insuDeposit(insuDeposit)
                .contDeposit(contDeposit)
                .contManager(contManager)
                .eduManager(eduManager)
                .contArea(contArea)
                .realArea(realArea)
                .floor(floor)
                .parkingCount(parkingCount)
                .premiumFee(premiumFee)
                .monthlyRent(monthlyRent)
                .rentDeposit(rentDeposit)
                .build();
    }
}
