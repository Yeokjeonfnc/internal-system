package com.yeokjeon.erp.franchise.dto;

import java.util.List;

/**
 * 가맹점 목록·건수 조회 조건. 메일 {@code MailListQuery} 와 같이 목록/카운트가
 * 같은 필터를 쓰도록 한 덩어리로 묶는다.
 *
 * <p>{@code limit == null} 이면 LIMIT 절을 생략한다(대시보드·피커용 전체 조회).
 *
 * @param brandNm         브랜드명. 화면 드롭다운은 코드가 아니라 표시명이다.
 * @param regionNms       지역 표시명(다중).
 * @param storeStatusNms  계약상태 표시명(신규계약·재계약 등, 다중).
 */
public record StoreListQuery(
        Integer limit,
        int offset,
        String brandNm,
        List<String> regionNms,
        List<String> storeStatusNms,
        String storeNm,
        String storeCd,
        String ownerNm,
        String storeTel,
        String address,
        String contStartDt,
        String contEndDt,
        String sv,
        String businessNumber,
        String notes) {

    public StoreListQuery withPaging(Integer limit, int offset) {
        return new StoreListQuery(
                limit,
                Math.max(offset, 0),
                brandNm,
                regionNms,
                storeStatusNms,
                storeNm,
                storeCd,
                ownerNm,
                storeTel,
                address,
                contStartDt,
                contEndDt,
                sv,
                businessNumber,
                notes);
    }

    public boolean hasFilters() {
        return notBlank(brandNm)
                || notEmpty(regionNms)
                || notEmpty(storeStatusNms)
                || notBlank(storeNm)
                || notBlank(storeCd)
                || notBlank(ownerNm)
                || notBlank(storeTel)
                || notBlank(address)
                || notBlank(contStartDt)
                || notBlank(contEndDt)
                || notBlank(sv)
                || notBlank(businessNumber)
                || notBlank(notes);
    }

    private static boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    private static boolean notEmpty(List<String> list) {
        return list != null && !list.isEmpty();
    }
}
