package com.yeokjeon.erp.master.dto;

/**
 * 가맹점주 조회·저장 응답.
 */
public record OwnerUserMstDto(
        Integer userIdx,
        String userName,
        String userId,
        String userPhone,
        String userEmail,
        Integer storeIdx,
        String storeNm) {

    public static OwnerUserMstDto fromJdbcRow(OwnerUserListJdbcRow r) {
        return new OwnerUserMstDto(
                r.userIdx(),
                r.userName(),
                r.userId(),
                r.userPhone(),
                r.userEmail(),
                r.storeIdx(),
                r.storeNm());
    }
}
