package com.yeokjeon.erp.eap.service;

import com.yeokjeon.erp.eap.config.DaouOfficeProperties;
import com.yeokjeon.erp.eap.dto.EapConnectionTestResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

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

    /**
     * 다우오피스에 "닿는가"만 확인한다 — 조회(HEAD)만 하고 아무것도 만들지 않는다.
     *
     * <p>예전 구현은 기안 등록 엔드포인트({@code POST /public/v4/approval/document})를 실제로
     * 호출하고 302 가 오면 인증 성공으로 판정했다. 즉 성공 경로가 곧 결재문서 생성이라,
     * 환경설정 화면을 열 때마다(=이 메서드가 불릴 때마다) 다우오피스 결재함에 'ERP 연결 테스트'
     * 문서가 한 건씩 기안되고 결재자에게 알림이 갔다. 연결 확인이 운영 데이터를 만들어서는
     * 안 되므로, 인증키 유효성 판정을 포기하고 도달 가능 여부만 본다.
     */
    private DaouProbeResult probeDaouOffice() throws Exception {
        String url = trimSlash(daouOfficeProperties.getApiBaseUrl())
                + "/public/v4/approval/document";

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(TIMEOUT)
                .followRedirects(HttpClient.Redirect.NEVER)
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(TIMEOUT)
                .header("Accept", "*/*")
                .method("HEAD", HttpRequest.BodyPublishers.noBody())
                .build();

        HttpResponse<Void> response = client.send(request, HttpResponse.BodyHandlers.discarding());
        int status = response.statusCode();

        log.info("다우오피스 연결 확인(HEAD) 응답 status={}", status);

        if (status >= 500) {
            return new DaouProbeResult(
                    true,
                    false,
                    "다우오피스 서버 오류 HTTP " + status + " — 잠시 후 다시 확인하세요.");
        }

        // 상태코드가 무엇이든 응답이 왔다는 것은 주소·네트워크·TLS 가 살아 있다는 뜻이다.
        // 인증키가 맞는지는 여기서 알 수 없다 — 확인하려면 실제 기안을 남겨야 하기 때문.
        return new DaouProbeResult(
                true,
                false,
                "주소 연결 정상(HTTP " + status + ") — 인증키 유효성은 실제 기안 시 확인됩니다."
                        + " 연결 테스트가 결재문서를 만들지 않도록 조회만 수행합니다.");
    }

    private static String trimSlash(String base) {
        if (base == null) {
            return "";
        }
        return base.endsWith("/") ? base.substring(0, base.length() - 1) : base;
    }

    private static String nullToDash(String value) {
        return value == null || value.isBlank() ? "-" : value;
    }

    private record DaouProbeResult(boolean reachable, boolean authOk, String message) {
    }
}
