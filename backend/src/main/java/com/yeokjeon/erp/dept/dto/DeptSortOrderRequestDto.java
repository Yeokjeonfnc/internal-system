package com.yeokjeon.erp.dept.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class DeptSortOrderRequestDto {

    @NotEmpty(message = "정렬 대상 부서가 없습니다")
    private List<Item> items;

    @Getter
    @Setter
    public static class Item {

        private Integer deptIdx;

        @NotNull(message = "부서명은 필수입니다")
        private String deptNm;

        private Integer upperDeptIdx;
      
        private Integer sortOrder;
    }
}
