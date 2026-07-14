package com.yeokjeon.erp.franchise.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

@Getter
@Setter
public class StoreNfcTagJdbcRow {
    private Integer storeIdx;
    private String tagUid;
    private String useYn;
    private OffsetDateTime registeredAt;
    private String registeredBy;
}
