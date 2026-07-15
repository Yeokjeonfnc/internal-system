package com.yeokjeon.erp.eap.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * 다우 「전자결재 처리상태 전송」 콜백 본문.
 * <p>공식 필드: docId / docNum / docStatusCode / docStatusName / partnerStatusCode / allianceInfo
 * <p>레거시 ERP 테스트용: documentId / status 도 허용.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record EapStatusCallbackRequestDto(
        @JsonAlias({"documentId", "DocumentId"}) String docId,
        String docNum,
        String partnerStatusCode,
        @JsonAlias({"status", "Status", "documentStatus"}) String docStatusCode,
        String docStatusName,
        Object allianceInfo,
        /** 레거시·수동 테스트 */
        String documentId,
        String status,
        String partnerDocId) {

    public String resolveDocId() {
        if (docId != null && !docId.isBlank()) {
            return docId.trim();
        }
        if (documentId != null && !documentId.isBlank()) {
            return documentId.trim();
        }
        return null;
    }

    public String resolveStatusCode() {
        if (docStatusCode != null && !docStatusCode.isBlank()) {
            return docStatusCode.trim();
        }
        if (status != null && !status.isBlank()) {
            return status.trim();
        }
        return null;
    }

    public String resolvePartnerDocId() {
        if (partnerDocId != null && !partnerDocId.isBlank()) {
            return partnerDocId.trim();
        }
        if (allianceInfo instanceof java.util.Map<?, ?> map) {
            Object v = map.get("partnerDocId");
            if (v == null) {
                v = map.get("partnerdocid");
            }
            if (v != null && !v.toString().isBlank()) {
                return v.toString().trim();
            }
        }
        if (allianceInfo instanceof String s && s.contains("ERP-")) {
            java.util.regex.Matcher m = java.util.regex.Pattern
                    .compile("ERP-\\d+")
                    .matcher(s);
            if (m.find()) {
                return m.group();
            }
        }
        return null;
    }
}
