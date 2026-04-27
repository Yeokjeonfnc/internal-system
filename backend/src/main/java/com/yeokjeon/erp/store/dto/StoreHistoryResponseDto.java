package com.yeokjeon.erp.store.dto;

import com.fasterxml.jackson.databind.JsonNode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StoreHistoryResponseDto {

    private Long historyIdx;
    private Integer storeIdx;
    private String chgType;
    private String storeNm;
    private JsonNode chgContent;
    private String content;
    private String createdBy;
    private LocalDateTime createdAt;
}
