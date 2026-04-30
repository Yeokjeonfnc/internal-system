package com.yeokjeon.erp.activity.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "active_mst")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Active {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "act_idx")
    private Integer actIdx;

    @Column(name = "store_idx", nullable = false)
    private Integer storeIdx;

    @Column(name = "act_type", nullable = false, length = 20)
    private String actType;

    @Column(name = "act_dt")
    private LocalDate actDt;

    @CreatedDate
    @Column(name = "creat_dt", updatable = false, columnDefinition = "TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime creatDt;

    @Column(name = "act_notes", columnDefinition = "TEXT")
    private String actNotes;

    @Column(name = "sv_id", length = 50)
    private String svId;

    @Column(name = "appr_status", length = 20)
    private String apprStatus;

    @Column(name = "appr_dt")
    private LocalDateTime apprDt;

    @Column(name = "suggestions", columnDefinition = "TEXT")
    private String suggestions;

    @Column(name = "sv_notes", columnDefinition = "TEXT")
    private String svNotes;

    @Column(name = "r_chk_id")
    private Integer rChkId;

    @Column(name = "chk_yn")
    private Character chkYn;
}
