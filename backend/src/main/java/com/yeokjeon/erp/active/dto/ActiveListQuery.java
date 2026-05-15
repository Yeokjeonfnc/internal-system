package com.yeokjeon.erp.active.dto;

/**
 * {@link com.yeokjeon.erp.active.mapper.ActMstMapper#actList} 동적 목록 조건.
 * {@link #mode} 값에 따라 나머지 필드 중 필요한 것만 채운다.
 */
public final class ActiveListQuery {

    public static final String MODE_ALL_NO_DRAFT = "ALL_NO_DRAFT";
    public static final String MODE_BY_APPR_STATUS = "BY_APPR_STATUS";
    public static final String MODE_BY_STORE = "BY_STORE";
    public static final String MODE_BY_CHK_YN = "BY_CHK_YN";
    public static final String MODE_BY_DRAFTER_MEMO = "BY_DRAFTER_MEMO";

    private final String mode;
    private final String apprStatus;
    private final Integer storeIdx;
    private final Character chkYn;
    private final String svId;

    private ActiveListQuery(String mode, String apprStatus, Integer storeIdx, Character chkYn, String svId) {
        this.mode = mode;
        this.apprStatus = apprStatus;
        this.storeIdx = storeIdx;
        this.chkYn = chkYn;
        this.svId = svId;
    }

    public static ActiveListQuery allNoDraft() {
        return new ActiveListQuery(MODE_ALL_NO_DRAFT, null, null, null, null);
    }

    public static ActiveListQuery byApprStatus(String apprStatus) {
        return new ActiveListQuery(MODE_BY_APPR_STATUS, apprStatus, null, null, null);
    }

    public static ActiveListQuery byStore(int storeIdx) {
        return new ActiveListQuery(MODE_BY_STORE, null, storeIdx, null, null);
    }

    public static ActiveListQuery byChkYn(Character chkYn) {
        return new ActiveListQuery(MODE_BY_CHK_YN, null, null, chkYn, null);
    }

    public static ActiveListQuery byDrafterMemo(String svId) {
        return new ActiveListQuery(MODE_BY_DRAFTER_MEMO, null, null, null, svId);
    }

    public String getMode() {
        return mode;
    }

    public String getApprStatus() {
        return apprStatus;
    }

    public Integer getStoreIdx() {
        return storeIdx;
    }

    public Character getChkYn() {
        return chkYn;
    }

    public String getSvId() {
        return svId;
    }
}
