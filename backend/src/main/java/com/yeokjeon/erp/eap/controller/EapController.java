package com.yeokjeon.erp.eap.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.eap.dto.EapConnectionTestResult;
import com.yeokjeon.erp.eap.service.EapConnectionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/eap")
@RequiredArgsConstructor
public class EapController {

    private final EapConnectionService eapConnectionService;

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> health() {
        return ResponseEntity.ok(ApiResponse.success(
                "전자결재 API 정상",
                Map.of(
                        "service", "eap",
                        "status", "UP")));
    }

    @GetMapping("/connection-test")
    public ResponseEntity<ApiResponse<EapConnectionTestResult>> connectionTest() {
        log.info("전자결재 연동 테스트 요청");
        EapConnectionTestResult result = eapConnectionService.testConnection();
        String message = result.daouAuthOk()
                ? "ERP·다우오피스 연동 테스트 성공"
                : result.daouReachable()
                        ? "ERP 연결 OK — 다우오피스 설정 확인 필요"
                        : result.daouConfigured()
                                ? "ERP 연결 OK — 다우오피스 호출 실패"
                                : "ERP 연결 OK — 다우오피스 인증키 미설정";
        return ResponseEntity.ok(ApiResponse.success(message, result));
    }
}
