package com.yeokjeon.erp.franchise.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Formula;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "store_mst")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Store {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "store_idx")
    private Integer storeIdx;

    @Column(name = "store_cd", length = 20)
    private String storeCd;

    @Column(name = "store_nm", nullable = false, length = 100)
    private String storeNm;

    @Column(name = "owner_nm", length = 50)
    private String ownerNm;

    @Column(name = "region_cd", length = 10)
    private String regionCd;

    @Formula("(select cm.code_nm from code_mst cm where cm.code_cd = region_cd and cm.grp_cd = 20)")
    private String regionNm;

    @Column(name = "store_tel", length = 20)
    private String storeTel;

    @Column(name = "address", columnDefinition = "TEXT")
    private String address;

    @Column(name = "latitude", precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(name = "longitude", precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(name = "store_status", length = 20)
    private String storeStatus;

    @Formula("(select cm.code_nm from code_mst cm where cm.code_cd = store_status and cm.grp_cd = 10)")
    private String storeStatusNm;

    @Column(name = "cont_end_dt")
    private LocalDate contEndDt;

    @Column(name = "auto_renewal_yn")
    private Boolean autoRenewalYn;

    @Column(name = "store_type", length = 20)
    private String storeType;

    @Formula("(select cm.code_nm from code_mst cm where cm.code_cd = store_type and cm.grp_cd = 30)")
    private String storeTypeNm;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false, columnDefinition = "TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false, columnDefinition = "TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime updatedAt;

    @Column(name = "adress_detail", columnDefinition = "TEXT")
    private String adressDetail;

    @Column(name = "zip_cd", length = 10)
    private String zipCd;

    @Column(name = "brand_cd", columnDefinition = "TEXT")
    private String brandCd;

    @Formula("(select cm.code_nm from code_mst cm where cm.code_cd = brand_cd and cm.grp_cd = 40 order by cm.code_nm)")
    private String brandNm;

    @Column(name = "cont_start_dt")
    private LocalDate contStartDt;

    @Column(name = "business_number", length = 20)
    private String businessNumber;

    @Column(name = "notes", length = 500)
    private String notes;

    public enum StoreType {
        FR, // 가맹점
        DI // 직영점
    }

    @Column(name = "first_cont_dt")
    private LocalDate firstContDt;

    @Column(name = "fr_fee")
    private BigDecimal frFee;

    @Column(name = "edu_fee")
    private BigDecimal eduFee;

    @Column(name = "insu_deposit")
    private BigDecimal insuDeposit;

    @Column(name = "cont_deposit")
    private BigDecimal contDeposit;

    @Column(name = "cont_manager")
    private String contManager;

    @Formula("(select um.user_name from user_mst um where um.user_id = cont_manager)")
    private String contManagerNm;

    @Column(name = "edu_manager")
    private String eduManager;

    @Formula("(select um.user_name from user_mst um where um.user_id = edu_manager)")
    private String eduManagerNm;
    
    @Column(name = "sv_id")
    private String svId;

    @Formula("(select um.user_name from user_mst um where um.user_id = sv_id)")
    private String svNm;

    @Column(name = "cont_area")
    private BigDecimal contArea;

    @Column(name = "real_area")
    private BigDecimal realArea;

    @Column(name = "floor")
    private Integer floor;

    @Column(name = "parking_count")
    private Integer parkingCount;

    @Column(name = "premium_fee")
    private Integer premiumFee;

    @Column(name = "monthly_rent") // 임차료
    private Integer monthlyRent;

    @Column(name = "rent_deposit") // 권리금
    private Integer rentDeposit;

    /** 물건 마스터 FK — `property_mst.prop_idx` */
    @Column(name = "prop_idx")
    private Integer propIdx;

    /** 창업자 마스터 FK — `partner_mst.partner_idx` */
    @Column(name = "partner_idx")
    private Integer partnerIdx;
}
