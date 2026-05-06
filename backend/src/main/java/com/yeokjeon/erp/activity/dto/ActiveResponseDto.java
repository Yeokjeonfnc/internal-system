package com.yeokjeon.erp.activity.dto;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ActiveResponseDto {
    private Integer actIdx;
    private Integer storeIdx;
    private String storeNm;
    private String storeCd;
    private String brandCd;
    private String brandNm;
    private String memoTxt;
    private String actType;
    private LocalDate actDt;
    private LocalDateTime creatDt;
    private String actNotes;
    private String svId;
    private String svNm;  // 작성자 user_mst.user_name (sv_id)
    /** 작성자 소속 부서명 (user_mst → dept_mst.dept_nm) */
    private String svDeptNm;
    /** 결재자 user_id CSV (active_mst.appr_id) */
    private String apprId;
    private List<String> apprUserIds;
    private String apprStatus;
    private LocalDateTime apprDt;
    private String suggestions;
    private String svNotes;
    private Integer rChkId;
    private Character chkYn;
    private String sSvNm; // 가맹점 수퍼바이저 이름

    /** [상세 조회] notif_mst 에서 appr_yn=Y 인 결재자 user_id 목록 */
    private List<String> apprAckUserIds;

    /** [상세 조회] 결재 확인 일자(yyyy-MM-dd), 키=user_id */
    private Map<String, String> apprAckDateByUserId;
}
