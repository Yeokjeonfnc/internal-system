package com.yeokjeon.erp.master.dto;

/**
 * 가맹점주 목록·상세 JOIN 조회 행.
 */
public record OwnerUserListJdbcRow(
        Integer userIdx,
        String userName,
        String userId,
        String userPhone,
        String userEmail,
        Integer storeIdx,
        String storeNm) {}
