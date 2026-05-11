package com.yeokjeon.erp.active.dto;

/** 작성자 이름·부서명 — {@code user_mst} + {@code dept_mst} 조인 1행. */
public record UserWriterDeptRow(String userName, String deptNm) {}
