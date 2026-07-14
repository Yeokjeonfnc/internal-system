package com.yeokjeon.erp.eap.dto;

import lombok.Builder;

@Builder
public record EapConnectionTestResult(
        boolean erpApiOk,
        boolean daouConfigured,
        boolean daouReachable,
        boolean daouAuthOk,
        String daouMessage,
        String erpApiBaseUrl,
        String daouApiBaseUrl,
        String callbackUrl,
        String formCode) {
}
