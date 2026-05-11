package com.yeokjeon.erp.active.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.yeokjeon.erp.active.entity.ActActive;
import com.yeokjeon.erp.franchise.entity.Store;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * {@code active_mst} + 가맹점 조인 API 응답 — 기존 {@code toActivityMap} 키와 동일.
 * 상세({@code GET /activities/{id}})만 {@code apprAck*} 가 채워지며, 목록에서는 {@code null}로 두어 JSON에서 생략한다.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ActiveMstResponseDto(
        Integer actIdx,
        Integer storeIdx,
        String storeNm,
        String storeCd,
        String brandCd,
        String brandNm,
        String actType,
        LocalDate actDt,
        LocalDateTime createDt,
        String memoTxt,
        String actNotes,
        String svId,
        String svNm,
        String svDeptNm,
        String apprId,
        List<String> apprUserIds,
        String ssvNm,
        String apprStatus,
        LocalDateTime apprDt,
        String apprNotes,
        String suggestions,
        String svNotes,
        Integer rChkId,
        String chkYn,
        Map<String, String> apprAckDateByUserId,
        List<String> apprAckUserIds) {

    public static ActiveMstResponseDto fromActive(
            ActActive active,
            Store store,
            String svNm,
            String svDeptNm,
            String ssvNm,
            List<String> apprUserIds,
            Map<String, String> apprAckDateByUserId,
            List<String> apprAckUserIds) {
        return new ActiveMstResponseDto(
                active.getActIdx(),
                active.getStoreIdx(),
                store == null ? null : store.getStoreNm(),
                store == null ? null : store.getStoreCd(),
                store == null ? null : store.getBrandCd(),
                store == null ? null : codeName(store.getBrandCd(), store.getBrandNm()),
                active.getActType(),
                active.getActDt(),
                active.getCreateDt(),
                active.getMemoTxt(),
                active.getActNotes(),
                active.getSvId(),
                svNm,
                svDeptNm,
                active.getApprId(),
                apprUserIds == null ? List.of() : apprUserIds,
                ssvNm,
                active.getApprStatus(),
                active.getApprDt(),
                active.getApprNotes(),
                active.getSuggestions(),
                active.getSvNotes(),
                active.getRChkId(),
                active.getChkYn() != null ? String.valueOf(active.getChkYn()) : null,
                apprAckDateByUserId,
                apprAckUserIds);
    }

    public ActiveMstResponseDto withApprAck(
            Map<String, String> apprAckDateByUserId, List<String> apprAckUserIds) {
        return new ActiveMstResponseDto(
                actIdx,
                storeIdx,
                storeNm,
                storeCd,
                brandCd,
                brandNm,
                actType,
                actDt,
                createDt,
                memoTxt,
                actNotes,
                svId,
                svNm,
                svDeptNm,
                apprId,
                apprUserIds,
                ssvNm,
                apprStatus,
                apprDt,
                apprNotes,
                suggestions,
                svNotes,
                rChkId,
                chkYn,
                apprAckDateByUserId,
                apprAckUserIds);
    }

    private static String codeName(String code, String name) {
        return name != null ? name : code;
    }
}
