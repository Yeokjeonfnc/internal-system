package com.yeokjeon.erp.prt001.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.time.LocalDate;

@Entity
@Table(name = "partner_mst")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Partner {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "partner_idx")
    private Integer partnerIdx;

    @Column(name = "partner_nm", nullable = false, length = 50)
    private String partnerNm;

    @Column(name = "partner_status", length = 20)
    private String partnerStatus;

    @Column(name = "partner_tel", nullable = false, length = 20)
    private String partnerTel;

    @Column(name = "partner_email", length = 100)
    private String partnerEmail;

    @Column(name = "gender", length = 1)
    private String gender;

    @CreatedDate
    @Column(name = "create_dt", nullable = false, updatable = false, columnDefinition = "TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime createDt;

    @LastModifiedDate
    @Column(name = "update_dt", columnDefinition = "TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime updateDt;

    @Column(name = "partner_birth")
    private LocalDate partnerBirth;

    @Column(name = "p_zip_cd", length = 10)
    private String pZipCd;

    @Column(name = "p_address", length = 255)
    private String pAddress;

    @Column(name = "p_address_detail", length = 255)
    private String pAddressDetail;

    @Column(name = "p_region", length = 50)
    private String pRegion;
}
