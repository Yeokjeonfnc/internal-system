package com.yeokjeon.erp.master.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotNull;

/** {@code PUT /dept/sort-order} 요청의 {@code items[]} 한 행. */
@JsonIgnoreProperties(ignoreUnknown = true)
public record DeptSortItemDto(
        @NotNull Integer deptIdx,
        Integer upperDeptIdx,
        Integer sortOrder) {}
