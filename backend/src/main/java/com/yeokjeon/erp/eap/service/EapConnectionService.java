package com.yeokjeon.erp.eap.service;

import com.yeokjeon.erp.eap.config.DaouOfficeProperties;
import com.yeokjeon.erp.eap.dto.EapConnectionTestResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class EapConnectionService {

    private static final Duration TIMEOUT = Duration.ofSeconds(15);

    private final DaouOfficeProperties daouOfficeProperties;

    public EapConnectionTestResult testConnection() {
        String daouMessage = "대기";
        boolean daouReachable = false;
        boolean daouAuthOk = false;

        if (!daouOfficeProperties.isCredentialConfigured()) {
            daouMessage = "Client ID / Secret 이 application.yml 또는 환경변수(DAOU_CLIENT_ID, DAOU_CLIENT_SECRET)에 없습니다.";
        } else {
            try {
                var probe = probeDaouOffice();
                daouReachable = probe.reachable();
                daouAuthOk = probe.authOk();
                daouMessage = probe.message();
            } catch (Exception e) {
                log.warn("다우오피스 연결 테스트 실패", e);
                daouMessage = "다우오피스 호출 실패: " + e.getMessage();
            }
        }

        return EapConnectionTestResult.builder()
                .erpApiOk(true)
                .daouConfigured(daouOfficeProperties.isCredentialConfigured())
                .daouReachable(daouReachable)
                .daouAuthOk(daouAuthOk)
                .daouMessage(daouMessage)
                .erpApiBaseUrl("http://localhost:3001/api")
                .daouApiBaseUrl(daouOfficeProperties.getApiBaseUrl())
                .callbackUrl(nullToDash(daouOfficeProperties.getCallbackUrl()))
                .formCode(nullToDash(daouOfficeProperties.getFormCode()))
                .build();
    }

    private DaouProbeResult probeDaouOffice() throws Exception {
        Map<String, String> form = new LinkedHashMap<>();
        form.put("clientId", daouOfficeProperties.getClientId());
        form.put("clientSecret", daouOfficeProperties.getClientSecret());
        form.put("formCode", blankTo(daouOfficeProperties.getFormCode(), "connection_test"));
        form.put("title", "ERP 연결 테스트");
        form.put("content", "<p>연결 테스트용 문서입니다.</p>");
        // 기본값은 운영 도메인 — 테스트 서버에서는 DAOU_CALLBACK_URL 환경변수로 덮어쓴다.
        form.put("callbackUrl", blankTo(
                daouOfficeProperties.getCallbackUrl(),
                "https://on.yeokjeon.com/api/eap/status"));

        String body = form.entrySet().stream()
                .map(e -> encode(e.getKey()) + "=" + encode(e.getValue()))
                .collect(Collectors.joining("&"));

        String url = trimSlash(daouOfficeProperties.getApiBaseUrl())
                + "/public/v4/approval/document";

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(TIMEOUT)
                .followRedirects(HttpClient.Redirect.NEVER)
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(TIMEOUT)
                .header("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        int status = response.statusCode();
        String responseBody = response.body() == null ? "" : response.body();

        log.info("다우오피스 연결 테스트 응답 status={} bodyLen={}", status, responseBody.length());

        if (status == 302) {
            return new DaouProbeResult(
                    true,
                    true,
                    "인증 성공 — 기안 API 응답 302 Redirect (연동 가능)");
        }

        if (responseBody.contains("901") || responseBody.contains("유효하지 않은 client ID")) {
            return new DaouProbeResult(true, false, "다우오피스 응답: Client ID 오류(901)");
        }
        if (responseBody.contains("902") || responseBody.contains("client Secret")) {
            return new DaouProbeResult(true, false, "다우오피스 응답: Client Secret 오류(902)");
        }
        if (responseBody.contains("955") || responseBody.contains("도메인 코드")) {
            return new DaouProbeResult(true, false, "다우오피스 응답: formCode/도메인 코드 오류(955)");
        }
        if (status >= 200 && status < 500) {
            return new DaouProbeResult(
                    true,
                    false,
                    "다우오피스 서버 응답 HTTP " + status + " — 설정(formCode·callbackUrl 등)을 확인하세요.");
        }

        return new DaouProbeResult(
                false,
                false,
                "다우오피스 서버 HTTP " + status);
    }

    private static String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private static String trimSlash(String base) {
        if (base == null) {
            return "";
        }
        return base.endsWith("/") ? base.substring(0, base.length() - 1) : base;
    }

    private static String blankTo(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    private static String nullToDash(String value) {
        return value == null || value.isBlank() ? "-" : value;
    }

    private record DaouProbeResult(boolean reachable, boolean authOk, String message) {
    }
}
