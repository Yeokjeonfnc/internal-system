package com.yeokjeon.erp.master.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

/** {@code PUT /dept/sort-order} 요청 본문. */
@JsonIgnoreProperties(ignoreUnknown = true)
public record DeptSortOrderUpdateRequestDto(
        @NotEmpty @Valid List<DeptSortItemDto> items) {}
