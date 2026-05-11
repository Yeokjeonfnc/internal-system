package com.yeokjeon.erp.active.dto;

import lombok.Data;

/** {@code chk_mst} INSERT 파라미터 — 삽입 후 {@link #chkIdx} 가 MyBatis에 의해 채워진다. */
@Data
public class ChkMstInsertHolder {
    private String brandCd;
    private String chkType;
    private String chkContent;
    private Integer baseScore;
    private Character useYn;
    private Integer chkIdx;
}
