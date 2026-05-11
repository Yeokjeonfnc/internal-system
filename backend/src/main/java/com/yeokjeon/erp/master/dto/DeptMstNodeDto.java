package com.yeokjeon.erp.master.dto;

import java.util.ArrayList;
import java.util.List;

/**
 * {@code dept_mst} 트리 노드(자식 포함) — 기존 {@code Map} 응답과 동일한 JSON 키.
 */
public record DeptMstNodeDto(
        Integer deptIdx,
        Integer upperDeptIdx,
        String deptNm,
        Integer deptLevel,
        Integer sortOrder,
        String managerNm,
        Integer userCount,
        List<DeptMstNodeDto> children) {

    public static DeptMstNodeDto leaf(
            Integer deptIdx,
            Integer upperDeptIdx,
            String deptNm,
            Integer deptLevel,
            Integer sortOrder,
            String managerNm,
            Integer userCount) {
        return new DeptMstNodeDto(
                deptIdx,
                upperDeptIdx,
                deptNm,
                deptLevel,
                sortOrder,
                managerNm,
                userCount,
                new ArrayList<>());
    }
}
