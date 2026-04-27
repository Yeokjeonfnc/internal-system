package com.yeokjeon.erp.common;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CodeOptionDto {

    private String codeCd;
    private String codeNm;
}
