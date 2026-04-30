package com.yeokjeon.erp.activity.dto;

import lombok.*;

import java.util.List;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChecklistResultDto {
    private Integer chkIdx;
    private String answerVal;
    private Integer answerScore;
}
