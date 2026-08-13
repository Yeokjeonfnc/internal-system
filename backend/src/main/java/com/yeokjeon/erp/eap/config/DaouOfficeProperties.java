package com.yeokjeon.erp.eap.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "daou.office")
public class DaouOfficeProperties {

    private String apiBaseUrl = "https://api.daouoffice.com";
    /** 그룹웨어 웹 호스트 (모바일 기안 data.url 이 상대경로일 때 사용) */
    private String gatewayBaseUrl = "https://gw.yeokjeonfnc.com";
    private String clientId = "";
    private String clientSecret = "";
    private String formCode = "";
    private String callbackUrl = "";

    public boolean isCredentialConfigured() {
        return clientId != null && !clientId.isBlank()
                && clientSecret != null && !clientSecret.isBlank();
    }
}
