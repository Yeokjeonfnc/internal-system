package com.yeokjeon.erp.property.dto;

import com.yeokjeon.erp.property.entity.Property;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PropertyRequestDto {

    @NotBlank(message = "물건명은 필수입니다")
    private String propNm;

    private String zipCd;
    private String address;
    private String addressDetail;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String region;
    private String propStatus;
    private String propType;
    private Integer floor;
    private BigDecimal contArea;
    private BigDecimal realArea;
    private Long rentDeposit;
    private Long monthlyRent;
    private Long premiumFee;
    private Long maintFee;
    private String propNotes;
    private LocalDate surveyDt;
    private String surveyor;

    public Property toEntity() {
        return Property.builder()
                .propNm(propNm)
                .zipCd(zipCd)
                .address(address)
                .addressDetail(addressDetail)
                .latitude(latitude)
                .longitude(longitude)
                .region(region)
                .propStatus(propStatus)
                .propType(propType)
                .floor(floor)
                .contArea(contArea)
                .realArea(realArea)
                .rentDeposit(rentDeposit)
                .monthlyRent(monthlyRent)
                .premiumFee(premiumFee)
                .maintFee(maintFee)
                .propNotes(propNotes)
                .surveyDt(surveyDt)
                .surveyor(surveyor)
                .build();
    }
}
