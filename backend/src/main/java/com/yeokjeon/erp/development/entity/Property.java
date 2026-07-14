package com.yeokjeon.erp.development.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "property_mst")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Property {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "prop_idx")
    private Integer propIdx;

    @Column(name = "prop_nm", nullable = false, length = 100)
    private String propNm;

    @Column(name = "zip_cd", length = 10)
    private String zipCd;

    @Column(name = "address", length = 255)
    private String address;

    @Column(name = "address_detail", length = 255)
    private String addressDetail;

    @Column(name = "latitude", precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(name = "longitude", precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(name = "region", length = 50)
    private String region;

    @Column(name = "prop_status", length = 20)
    private String propStatus;

    @Column(name = "prop_type", length = 20)
    private String propType;

    @Column(name = "floor")
    private Integer floor;

    @Column(name = "cont_area", precision = 12, scale = 2)
    private BigDecimal contArea;

    @Column(name = "real_area", precision = 12, scale = 2)
    private BigDecimal realArea;

    @Column(name = "rent_deposit")
    private Long rentDeposit;

    @Column(name = "monthly_rent")
    private Long monthlyRent;

    @Column(name = "premium_fee")
    private Long premiumFee;

    @Column(name = "maint_fee")
    private Long maintFee;

    @Column(name = "prop_notes", columnDefinition = "TEXT") // 특이사항
    private String propNotes;

    @Column(name = "survey_dt") // 조사일자
    private LocalDate surveyDt;

    @Column(name = "surveyor", length = 50)
    private String surveyor; // 조사자ID

    /** 영업지역 — {@code sale_zone_mst.zone_idx}. */
    @Column(name = "zone_idx")
    private Integer zoneIdx;

    @CreatedDate
    @Column(name = "create_dt", nullable = false, updatable = false, columnDefinition = "TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime createDt;

    @LastModifiedDate
    @Column(name = "update_dt", columnDefinition = "TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime updateDt;

}
