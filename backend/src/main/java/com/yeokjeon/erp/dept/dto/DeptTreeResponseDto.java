package com.yeokjeon.erp.dept.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeptTreeResponseDto {

    private Integer deptIdx;
    private Integer upperDeptIdx;
    private String deptNm;
    private Integer deptLevel;
    private Integer sortOrder;
    private String managerNm;

    @JsonProperty("user_count")
    private Integer userCount;

    @Builder.Default
    private List<DeptTreeResponseDto> children = new ArrayList<>();

    public void addChild(DeptTreeResponseDto child) {
        children.add(child);
    }
}
