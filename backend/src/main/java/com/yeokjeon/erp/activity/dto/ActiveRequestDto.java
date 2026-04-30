package com.yeokjeon.erp.activity.dto;

import com.yeokjeon.erp.activity.entity.Active;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
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
    private List<ChecklistResultDto> checklistResults;

    public Active toEntity() {
        return Active.builder()
                .storeIdx(storeIdx)
                .actType(actType)
                .actDt(actDt)
                .actNotes(actNotes)
                .svId(svId)
                .apprStatus(apprStatus)
                .apprDt(apprDt)
                .suggestions(suggestions)
                .svNotes(svNotes)
                .rChkId(rChkId)
                .chkYn(chkYn)
                .build();
    }
}
