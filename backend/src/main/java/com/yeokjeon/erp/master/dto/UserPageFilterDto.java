package com.yeokjeon.erp.master.dto;

/** 사용자별 화면 필터 저장값. filterJson은 화면이 해석하는 JSON 문자열이다. */
public record UserPageFilterDto(String pageCode, String filterJson) {
}
