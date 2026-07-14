package com.yeokjeon.erp.active.entity;

import org.hibernate.annotations.Formula;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * DB 테이블 {@code active_mst}. 물리 컬럼은 snake_case({@code act_idx} 등),
 * Java·API·프론트 필드는 camelCase({@code actIdx})로 매핑한다.
 */
@Entity
@Table(name = "active_mst")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class ActActive {

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
    @Column(name = "create_dt", updatable = false, columnDefinition = "TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime createDt;

    @Column(name = "act_notes", columnDefinition = "TEXT")
    private String actNotes;

    @Column(name = "memo_txt", columnDefinition = "TEXT")
    private String memoTxt;

    @Column(name = "sv_id", length = 50)
    private String svId;

    /** 결재 대상자 user_id 목록(쉼표 구분). 본인(작성자) 제외한 결재자만 저장한다. */
    @Column(name = "appr_id", length = 500)
    private String apprId;

    @Column(name = "appr_status", length = 20)
    private String apprStatus;

    @Column(name = "appr_dt")
    private LocalDateTime apprDt;

    @Formula("(select sm.store_nm from store_mst sm where sm.store_idx = store_idx)")
    private String storeNm;

    @Formula("(select cm.code_nm from store_mst sm inner join code_mst cm on sm.brand_cd = cm.code_cd and cm.grp_cd = 40 where sm.store_idx = store_idx)")
    private String brandNm;

    @Column(name = "suggestions", columnDefinition = "TEXT")
    private String suggestions;

    @Column(name = "sv_notes", columnDefinition = "TEXT")
    private String svNotes;

    @Column(name = "appr_notes", columnDefinition = "TEXT")
    private String apprNotes;

    @Column(name = "chk_yn")
    private Character chkYn;

    /** 전자서명 PNG — 디스크 저장 파일명(UUID 기반). */
    @Column(name = "signature_stored_name", length = 255)
    private String signatureStoredName;

    /** 활동 상신 시 연결한 출입 태그 usage_log.log_idx */
    @Column(name = "usage_log_idx")
    private Long usageLogIdx;
}
