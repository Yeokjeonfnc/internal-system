package com.yeokjeon.erp.activity.dto;

import com.yeokjeon.erp.activity.entity.Active;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.List;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ActiveRequestDto {

    @NotNull(message = "가맹점은 필수입니다")
    private Integer storeIdx;

    @NotBlank(message = "활동구분은 필수입니다")
    private String actType;

    private LocalDate actDt;
    private String actNotes;
    private String svId;
    private String apprStatus;
    private LocalDateTime apprDt;
    private String suggestions;
    private String svNotes;
    private Integer rChkId;
    private Character chkYn;
    private String memoTxt;
    /** 상신 시 결재자 user_id (본인 제외). 여러 명일 경우 목록으로 전달 후 서버에서 CSV 저장 */
    private List<String> apprUserIds;
    private List<ChecklistResultDto> checklistResults;

    public Active toEntity() {
        return Active.builder()
                .storeIdx(storeIdx)
                .actType(actType)
                .actDt(actDt)
                .actNotes(actNotes)
                .svId(svId)
                .apprId(joinApprUserIds(apprUserIds))
                .apprStatus(apprStatus)
                .memoTxt(memoTxt)
                .apprDt(apprDt)
                .suggestions(suggestions)
                .svNotes(svNotes)
                .rChkId(rChkId)
                .chkYn(chkYn)
                .build();
    }

    public static String joinApprUserIds(List<String> ids) {
        if (ids == null || ids.isEmpty()) {
            return null;
        }
        LinkedHashSet<String> set = new LinkedHashSet<>();
        for (String raw : ids) {
            if (raw == null) {
                continue;
            }
            String t = raw.trim();
            if (!t.isEmpty()) {
                set.add(t);
            }
        }
        if (set.isEmpty()) {
            return null;
        }
        return String.join(",", set);
    }
}
