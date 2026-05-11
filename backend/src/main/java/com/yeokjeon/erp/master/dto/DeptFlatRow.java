package com.yeokjeon.erp.master.dto;

/** 부서 트리 구축용 평면 행 — {@code getDeptTree} 1차 조회 결과. */
public record DeptFlatRow(
        Integer deptIdx,
        Integer upperDeptIdx,
        String deptNm,
        Integer deptLevel,
        Integer sortOrder) {}
